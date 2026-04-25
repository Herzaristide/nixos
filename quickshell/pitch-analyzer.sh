#!/usr/bin/env bash
# pitch-analyzer.sh — Real-time pitch detection for Quickshell PitchAnalyzer widget
# Dependencies: aubio (provides aubiopitch), sox or arecord (alsa-utils)
# Output protocol (stdout):
#   STATUS:READY                           — on startup
#   NOTE:<name><oct> FREQ:<hz> CENTS:<+/-n> MIDI:<n>  — detected pitch
#   STATUS:SILENT                          — after N silent frames

echo "STATUS:READY"

# ── awk processor: reads aubiopitch output, converts to protocol lines ──────
# aubio yin confidence: 0.0 = perfectly periodic (good pitch), 1.0 = aperiodic.
# Accept frames where confidence < 0.35, frequency in [50, 4200] Hz.
AWK_PROC='
BEGIN {
    split("C C# D D# E F F# G G# A A# B", notes, " ")
    silent = 0
}
/^#/ || /^[[:space:]]*$/ { next }
{
    if (NF >= 3) { freq = $2+0; conf = $3+0 }
    else if (NF == 2) { freq = $1+0; conf = $2+0 }
    else { next }

    if (freq < 50 || freq > 4200 || conf > 0.35) {
        if (++silent >= 4) { print "STATUS:SILENT"; fflush(); silent = 0 }
        next
    }
    silent = 0

    midi_f   = 69 + 12 * log(freq / 440) / log(2)
    midi_i   = int(midi_f + 0.5)
    if (midi_i < 0)   midi_i = 0
    if (midi_i > 127) midi_i = 127
    semitone = (midi_i % 12) + 1
    octave   = int(midi_i / 12) - 1
    cents    = (midi_f - midi_i) * 100
    printf "NOTE:%s%d FREQ:%.1f CENTS:%s%.0f MIDI:%d\n",
        notes[semitone], octave, freq, (cents >= 0 ? "+" : ""), cents, midi_i
    fflush()
}
'

# ── Capture + process pipeline ───────────────────────────────────────────────
if command -v sox > /dev/null 2>&1; then
    sox -d -q -r 44100 -c 1 -t wav - 2>/dev/null
else
    arecord -q -f cd -r 44100 -c 1 -t wav 2>/dev/null
fi | aubiopitch -i - -r 44100 -B 2048 -H 512 -p yin -u freq 2>/dev/null \
  | awk "$AWK_PROC"
