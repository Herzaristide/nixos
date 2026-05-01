#!/usr/bin/env bash
# metronome.sh — Sample-accurate metronome backend for the Quickshell
# Metronome widget.
#
# Design
# ------
#   • One persistent audio player (pw-cat / aplay / paplay) reads raw PCM
#     from a pipe attached to FD 9. Started once, never restarted.
#   • A "writer" subshell, started on START, repeatedly emits one beat's
#     worth of PCM (click + silence padding sized to the current BPM) on
#     FD 9. The audio backpressure (small playback buffer) paces the loop
#     to the sample clock, so timing is rock-solid with zero drift.
#   • Tempo / mute changes are picked up by the writer on the next beat.
#
# Protocol on stdin  : START [bpm] | STOP | BPM <n> | MUTE 0|1 | QUIT
# Output on stdout   : READY | BEAT <n>
# Audio diagnostics  : stderr (typically redirected to a log)

set -u

RUN_DIR="${XDG_RUNTIME_DIR:-/tmp}/quickshell-metronome"
mkdir -p "$RUN_DIR"
ACCENT="$RUN_DIR/accent.raw"
BEAT="$RUN_DIR/beat.raw"
STATE_BPM="$RUN_DIR/bpm"
STATE_MUTE="$RUN_DIR/mute"

# ── Pre-render click samples as raw 48 kHz mono s16le ─────────────────────
gen_clicks() {
    sox -q -n -r 48000 -c 1 -b 16 -e signed -t raw "$ACCENT" \
        synth 0.045 sine 1760 fade t 0.001 0.045 0.030 gain -3 || return 1
    sox -q -n -r 48000 -c 1 -b 16 -e signed -t raw "$BEAT" \
        synth 0.035 sine 880  fade t 0.001 0.035 0.025 gain -6 || return 1
}
if ! [ -s "$ACCENT" ] || ! [ -s "$BEAT" ]; then
    if ! gen_clicks; then
        echo "READY"
        echo "ERROR: sox failed" >&2
        exec cat >/dev/null
    fi
fi
ACCENT_BYTES=$(stat -c%s "$ACCENT")
BEAT_BYTES=$(stat -c%s "$BEAT")
export ACCENT BEAT ACCENT_BYTES BEAT_BYTES STATE_BPM STATE_MUTE

# ── Pick a player that reads raw 48 kHz mono s16le from stdin ─────────────
# Note: pw-cat uses libsndfile and refuses headerless stdin, so it's last.
PLAYER_CMD=""
if command -v aplay >/dev/null 2>&1; then
    # --buffer-size in frames (mono s16 ⇒ 1 frame = 2 bytes).
    # 4096 frames @48 kHz ≈ 85 ms — small enough that the writer blocks
    # within one beat at typical tempos, providing tight backpressure pacing.
    PLAYER_CMD="aplay -q -t raw -f S16_LE -r 48000 -c 1 --buffer-size=4096 -"
elif command -v paplay >/dev/null 2>&1; then
    PLAYER_CMD="paplay --raw --rate=48000 --channels=1 --format=s16le --latency-msec=50"
fi

if [ -z "$PLAYER_CMD" ]; then
    echo "READY"
    echo "ERROR: no audio player (pw-cat / aplay / paplay) found" >&2
    exec cat >/dev/null
fi

# ── Start the long-lived player. FD 9 is its stdin. ───────────────────────
# Process substitution gives us a writeable FD that the player reads from.
exec 9> >(exec $PLAYER_CMD >/dev/null 2>&1)

echo "READY"

# ── State ────────────────────────────────────────────────────────────────
running=0
muted=0
bpm=120
WRITER_PID=""

write_state() {
    echo "$bpm"   > "$STATE_BPM"
    echo "$muted" > "$STATE_MUTE"
}
write_state

# ── Writer subshell ───────────────────────────────────────────────────────
# Drift-free wall-clock scheduler. We only stream the click samples; the
# player happily underruns into silence between clicks (which is exactly
# what we want — silence between ticks).
start_writer() {
    (
        trap 'exit 0' HUP TERM INT
        beat_index=0
        # Use bash 5+ EPOCHREALTIME for sub-ms clock; fall back to date.
        now() { printf '%s' "${EPOCHREALTIME:-$(date +%s.%N)}"; }
        next=$(now)
        while :; do
            local_bpm=120
            local_muted=0
            [ -r "$STATE_BPM" ]  && read -r local_bpm  < "$STATE_BPM"  || true
            [ -r "$STATE_MUTE" ] && read -r local_muted < "$STATE_MUTE" || true
            : "${local_bpm:=120}"
            : "${local_muted:=0}"

            # Sleep until the scheduled deadline.
            cur=$(now)
            wait_s=$(awk -v a="$next" -v b="$cur" 'BEGIN{ d=a-b; if (d<0) d=0; printf "%.4f", d }')
            # shellcheck disable=SC2086
            [ "$wait_s" != "0.0000" ] && sleep $wait_s

            echo "BEAT $beat_index"
            if [ "$local_muted" -eq 0 ]; then
                if [ "$beat_index" -eq 0 ]; then
                    cat "$ACCENT" >&9 || exit 0
                else
                    cat "$BEAT" >&9 || exit 0
                fi
                # Pad ~120 ms of silence after each click so aplay's buffer
                # stays primed (avoids underrun-induced glitches on some
                # hardware) without overlapping the next click at < 500 BPM.
                head -c 11520 /dev/zero >&9 2>/dev/null || true
            fi

            interval=$(awk -v b="$local_bpm" 'BEGIN{ printf "%.6f", 60.0 / b }')
            next=$(awk -v a="$next" -v i="$interval" 'BEGIN{ printf "%.6f", a + i }')
            # Resync if we fell badly behind (suspend, BPM jump).
            cur=$(now)
            behind=$(awk -v a="$cur" -v b="$next" 'BEGIN{ print (a - b > 1) ? 1 : 0 }')
            if [ "$behind" = "1" ]; then
                next=$(awk -v c="$cur" -v i="$interval" 'BEGIN{ printf "%.6f", c + i }')
            fi

            beat_index=$(( (beat_index + 1) % 4 ))
        done
    ) &
    WRITER_PID=$!
}

stop_writer() {
    if [ -n "$WRITER_PID" ]; then
        kill "$WRITER_PID" 2>/dev/null || true
        wait "$WRITER_PID" 2>/dev/null || true
        WRITER_PID=""
    fi
}

cleanup() {
    stop_writer
    exec 9>&-
}
trap cleanup EXIT INT TERM

# ── Command loop ─────────────────────────────────────────────────────────
while IFS= read -r line; do
    # Word-split intentionally
    # shellcheck disable=SC2086
    set -- $line
    cmd="${1:-}"
    case "$cmd" in
        START)
            [ -n "${2:-}" ] && bpm=${2}
            write_state
            if [ "$running" -eq 0 ]; then
                running=1
                start_writer
            fi
            ;;
        STOP)
            running=0
            stop_writer
            ;;
        BPM)
            [ -n "${2:-}" ] && bpm=${2}
            write_state
            ;;
        MUTE)
            muted=${2:-0}
            write_state
            ;;
        QUIT)
            exit 0
            ;;
        *) ;;
    esac
done
