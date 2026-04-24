#!/usr/bin/env bash
# Voice assistant daemon for QuickShell OllamaChat
# Uses whisper-stream for continuous wake word detection ("Nix"),
# then sox + whisper-cli for command capture and transcription.
#
# Protocol (stdout lines):
#   STATUS:LISTENING     - idle, waiting for wake word
#   STATUS:TRIGGERED     - wake word detected, recording command
#   STATUS:PROCESSING    - transcribing command
#   TRANSCRIPT:<text>    - transcribed user command
#   STATUS:SPEAKING      - TTS playing response
#   ERROR:<message>      - something went wrong

set -uo pipefail

WHISPER_MODEL="${WHISPER_MODEL:-$HOME/.local/share/whisper/ggml-base.bin}"
PIPER_MODEL="${PIPER_MODEL:-$HOME/.local/share/piper/fr_FR-siwis-medium.onnx}"
WORK_DIR="/tmp/voice-assistant-$$"
SAMPLE_RATE=16000
# Whisper language for wake-word stream. Use 'en' for an English wake word
# pronounced in French (much more reliable than '-l fr').
WHISPER_LANG="${WHISPER_LANG:-en}"
# Wake word: defaults to the machine's hostname (e.g. "gary", "zola").
# Whisper handles common English names very reliably in -l en mode.
# Override via env var if needed: WAKE_WORD=ordi
WAKE_WORD="${WAKE_WORD:-$(hostname)}"
# Build a simple case-insensitive ERE: match the wake word as a whole word.
# Word-boundary at start only so "gary.", "gary!", "gary's" all match too.
# Override WAKE_WORD_REGEX entirely if you need finer control.
_ww_esc=$(printf '%s' "$WAKE_WORD" | tr '[:upper:]' '[:lower:]' | sed 's/[.[\*^$]/\\&/g')
WAKE_WORD_REGEX="${WAKE_WORD_REGEX:-\\b${_ww_esc}}"
unset _ww_esc

mkdir -p "$WORK_DIR"

WHISPER_PID=""
STDIN_PID=""

cleanup() {
    [ -n "$WHISPER_PID" ] && kill "$WHISPER_PID" 2>/dev/null
    [ -n "$STDIN_PID" ] && kill "$STDIN_PID" 2>/dev/null
    rm -rf "$WORK_DIR"
}
trap cleanup EXIT

# ── Model downloads ──────────────────────────────────────────
ensure_whisper_model() {
    if [ ! -f "$WHISPER_MODEL" ]; then
        echo "STATUS:DOWNLOADING_MODEL"
        mkdir -p "$(dirname "$WHISPER_MODEL")"
        whisper-cpp-download-ggml-model base "$(dirname "$WHISPER_MODEL")" 2>/dev/null
    fi
}

ensure_piper_model() {
    if [ ! -f "$PIPER_MODEL" ]; then
        echo "STATUS:DOWNLOADING_VOICE"
        mkdir -p "$(dirname "$PIPER_MODEL")"
        local base_url="https://huggingface.co/rhasspy/piper-voices/resolve/main/fr/fr_FR/siwis/medium"
        curl -sL "$base_url/fr_FR-siwis-medium.onnx" -o "$PIPER_MODEL"
        curl -sL "$base_url/fr_FR-siwis-medium.onnx.json" -o "${PIPER_MODEL}.json"
    fi
}

# ── TTS ──────────────────────────────────────────────────────
speak() {
    local text="$1"
    if [ -f "$PIPER_MODEL" ] && command -v piper >/dev/null 2>&1; then
        echo "STATUS:SPEAKING"
        echo "$text" | piper -m "$PIPER_MODEL" --output-raw 2>/dev/null | \
            aplay -r 22050 -f S16_LE -t raw -q 2>/dev/null || true
    fi
}

# ── Stdin handler (TTS from QuickShell) ──────────────────────
handle_stdin() {
    while IFS= read -r line; do
        case "$line" in
            SPEAK:*) speak "${line#SPEAK:}" & ;;
        esac
    done
}

# ── Wake word detection via whisper-stream ───────────────────
#
# whisper-stream in non-VAD (--step) mode writes to stdout using \r (carriage
# returns) to overwrite the same terminal line — never issuing \n between
# transcription updates. A raw FIFO + "while read" loop therefore blocks
# forever waiting for a newline that never comes.
#
# Fix: pass -f FILE so whisper-stream writes clean newline-terminated
# transcriptions to a file (std::endl → flush + \n after each 2-second
# chunk). A tail -f on that file then streams the lines reliably.
wait_for_wake_word() {
    local wake_file="$WORK_DIR/wake_text"
    local tail_fifo="$WORK_DIR/tail_fifo"
    local tail_pid=""
    > "$wake_file"
    mkfifo "$tail_fifo"

    # -f writes transcriptions with std::endl (flush+newline) every ~2 s.
    # Redirect stdout to /dev/null to suppress the ANSI terminal display.
    whisper-stream \
        -m "$WHISPER_MODEL" \
        -l "$WHISPER_LANG" \
        --step 2000 \
        --length 5000 \
        --keep 200 \
        --vad-thold 0.6 \
        -t 4 \
        -f "$wake_file" \
        >/dev/null 2>"$WORK_DIR/whisper-stream.err" &
    WHISPER_PID=$!

    # Stream new lines through a FIFO so we hold tail's PID for cleanup.
    # Opening the write side blocks until we open the read side below.
    stdbuf -oL tail -f "$wake_file" > "$tail_fifo" &
    tail_pid=$!

    local detected=false
    exec 3< "$tail_fifo"   # unblocks tail's FIFO write open
    while IFS= read -r line <&3; do
        # Strip CR and surrounding whitespace; skip empty
        line=$(printf '%s' "$line" | tr -d '\r' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
        [ -z "$line" ] && continue
        # Skip whisper's silence markers but keep them out of debug spam
        case "$line" in
            '[BLANK_AUDIO]'|'[Musique]'|'(musique)'|'...'|'.'|'[silence]') ;;
            *)
                # Surface to QuickShell so user can see what whisper hears
                echo "DEBUG:$line"
                local lower
                lower=$(printf '%s' "$line" | tr '[:upper:]' '[:lower:]')
                if printf '%s' "$lower" | grep -qiE "$WAKE_WORD_REGEX"; then
                    detected=true
                    break
                fi
                ;;
        esac
        # Exit loop if whisper-stream died unexpectedly
        kill -0 "$WHISPER_PID" 2>/dev/null || break
    done
    exec 3<&-

    kill "$tail_pid" 2>/dev/null
    wait "$tail_pid" 2>/dev/null || true
    kill "$WHISPER_PID" 2>/dev/null
    wait "$WHISPER_PID" 2>/dev/null || true
    WHISPER_PID=""
    # Give SDL/PulseAudio time to release the capture device before sox grabs it.
    # whisper-stream uses SDL2; after SIGKILL it can take ~500ms for PipeWire
    # to re-route the source to the next client (sox via PulseAudio compat layer).
    sleep 0.8
    rm -f "$wake_file" "$tail_fifo"

    [ "$detected" = true ]
}

# ── Command capture and transcription ────────────────────────
capture_command() {
    local outfile="$WORK_DIR/command.wav"
    rm -f "$outfile"

    # Record until silence (1.5s) or max 15s
    # timeout prevents infinite hang if sox blocks
    timeout 18 sox -d -r "$SAMPLE_RATE" -c 1 -b 16 "$outfile" \
        silence 1 0.3 2% 1 1.5 2% \
        trim 0 15 2>/dev/null || true

    local filesize
    filesize=$(stat -c%s "$outfile" 2>/dev/null || echo 0)

    if [ "$filesize" -lt 5000 ]; then
        echo "ERROR:Pas de parole détectée"
        return 1
    fi

    echo "STATUS:PROCESSING"

    local transcript
    transcript=$(whisper-cli -m "$WHISPER_MODEL" -f "$outfile" -l fr -np -nt 2>/dev/null | \
        sed 's/^[[:space:]]*//;s/[[:space:]]*$//' | \
        grep -v '^\[' | grep -v '^$' || echo "")

    if [ -n "$transcript" ]; then
        echo "TRANSCRIPT:$transcript"
    else
        echo "ERROR:Transcription échouée"
    fi
}

# ── Main loop ────────────────────────────────────────────────
main() {
    ensure_whisper_model
    ensure_piper_model

    echo "STATUS:READY"

    while true; do
        echo "STATUS:LISTENING"

        if wait_for_wake_word; then
            echo "STATUS:TRIGGERED"
            # Audible cue so the user knows when to start speaking
            (paplay /run/current-system/sw/share/sounds/freedesktop/stereo/message.oga 2>/dev/null \
                || printf '\a') &
            sleep 0.3
            capture_command || true
        fi
    done
}

# Start stdin handler in background
handle_stdin &
STDIN_PID=$!

main

