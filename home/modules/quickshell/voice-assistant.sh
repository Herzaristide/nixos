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
WAKE_PIPE="$WORK_DIR/wake_pipe"
SAMPLE_RATE=16000

mkdir -p "$WORK_DIR"
mkfifo "$WAKE_PIPE"

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
wait_for_wake_word() {
    # Start whisper-stream, output goes to FIFO
    whisper-stream \
        -m "$WHISPER_MODEL" \
        -l fr \
        --step 2000 \
        --length 5000 \
        --keep 200 \
        --vad-thold 0.5 \
        -t 4 \
        2>/dev/null > "$WAKE_PIPE" &
    WHISPER_PID=$!

    # Read from FIFO line by line
    local detected=false
    exec 3< "$WAKE_PIPE"
    while IFS= read -r line <&3; do
        local lower
        lower=$(echo "$line" | tr '[:upper:]' '[:lower:]')
        # Match "nix" and common whisper misheard variants
        if echo "$lower" | grep -qiE 'nix|nicks|niques'; then
            detected=true
            break
        fi
    done
    exec 3<&-

    # Stop whisper-stream to free the microphone
    kill "$WHISPER_PID" 2>/dev/null
    wait "$WHISPER_PID" 2>/dev/null || true
    WHISPER_PID=""

    # Recreate FIFO for next cycle
    rm -f "$WAKE_PIPE"
    mkfifo "$WAKE_PIPE"

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
            sleep 0.4
            capture_command || true
        fi
    done
}

# Start stdin handler in background
handle_stdin &
STDIN_PID=$!

main
