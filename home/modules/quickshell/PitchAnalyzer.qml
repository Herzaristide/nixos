import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell.Io

Item {
    id: pitchPanel

    // ── State ──────────────────────────────────────────────────────────────
    property string currentNote: ""
    property real currentFreq: 0.0
    property int currentMidi: 0
    property real currentCents: 0.0
    property bool isSilent: true

    // ── Reference tuning ──────────────────────────────────────────────────
    property real refA4: 440.0
    onRefA4Changed: {
        if (!isSilent && currentFreq > 0)
            currentCents = computeCents(currentFreq, currentMidi)
    }

    // ── Metronome state ───────────────────────────────────────────────────
    property bool metroRunning:      false
    property int  bpm:               120
    property int  beatIndex:         -1
    property bool metroClickEnabled: true
    property var  tapHistory:        []

    function clampBpm(v) { return Math.max(20, Math.min(300, v)) }

    function tapTempo() {
        var now = Date.now()
        var h = pitchPanel.tapHistory
        if (h.length > 0 && now - h[h.length - 1] > 3000) h = []
        h.push(now)
        if (h.length > 6) h = h.slice(-6)
        pitchPanel.tapHistory = h
        if (h.length >= 2) {
            var sum = 0
            for (var i = 1; i < h.length; i++) sum += h[i] - h[i - 1]
            pitchPanel.bpm = pitchPanel.clampBpm(Math.round(60000 / (sum / (h.length - 1))))
        }
    }

    // ── Cents relative to user's refA4 ────────────────────────────────────
    function computeCents(freq, midiInt) {
        if (freq <= 0) return 0
        var midiFloat = 69 + 12 * (Math.log(freq / pitchPanel.refA4) / Math.LN2)
        var nearest   = Math.round(midiFloat)
        return (midiFloat - nearest) * 100
    }

    // ── Pitch line parser ──────────────────────────────────────────────────
    function parsePitchLine(data) {
        var line = data.trim();
        if (line === "STATUS:SILENT" || line === "STATUS:READY") {
            pitchPanel.isSilent = true;
            pitchPanel.currentNote = "";
            pitchPanel.currentFreq = 0.0;
            return;
        }
        if (!line.startsWith("NOTE:")) return;

        // Format: NOTE:A4 FREQ:440.0 CENTS:+2 MIDI:69
        var parts = line.split(" ");
        var note = "", freq = 0.0, midi = 0;
        for (var i = 0; i < parts.length; i++) {
            var p = parts[i];
            if (p.startsWith("NOTE:"))  note = p.substring(5);
            if (p.startsWith("FREQ:"))  freq = parseFloat(p.substring(5));
            if (p.startsWith("MIDI:"))  midi = parseInt(p.substring(5));
        }
        if (note !== "") {
            pitchPanel.currentNote  = note;
            pitchPanel.currentFreq  = freq;
            pitchPanel.currentMidi  = midi;
            pitchPanel.currentCents = pitchPanel.computeCents(freq, midi);
            pitchPanel.isSilent     = false;
        }
    }

    // ── Backend process ────────────────────────────────────────────────────
    Process {
        id: pitchProcess
        command: ["bash", "-c", "exec $HOME/.config/quickshell/pitch-analyzer.sh"]
        running: pitchPanel.visible
        stdout: SplitParser {
            onRead: (data) => pitchPanel.parsePitchLine(data)
        }
        stderr: SplitParser {
            onRead: (data) => { /* suppress aubio debug output */ }
        }
        onExited: (code, status) => {
            pitchPanel.isSilent = true;
            pitchPanel.currentNote = "";
        }
    }

    // ── Metronome timer ───────────────────────────────────────────────────
    Timer {
        id: metroTimer
        interval: 60000 / Math.max(1, pitchPanel.bpm)
        running: pitchPanel.metroRunning
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            pitchPanel.beatIndex = (pitchPanel.beatIndex + 1) % 4
            if (pitchPanel.metroClickEnabled) {
                if (pitchPanel.beatIndex === 0)
                    accentClick.running = true
                else
                    beatClick.running = true
            }
        }
    }

    // Accent click — beat 1, higher pitch
    Process {
        id: accentClick
        command: ["play", "-q", "-n", "synth", "0.05", "sin", "1760", "vol", "0.55"]
        onExited: running = false
    }

    // Regular beat click
    Process {
        id: beatClick
        command: ["play", "-q", "-n", "synth", "0.04", "sin", "880", "vol", "0.4"]
        onExited: running = false
    }

    // ── Accuracy colour helper ─────────────────────────────────────────────
    function accuracyColor(absCents) {
        if (absCents <= 10) return "#00FF88";   // green — in tune
        if (absCents <= 25) return "#FFCC44";   // amber — slightly off
        return "#cc4444";                        // red — out of tune
    }

    // ── Staff drawing helper ───────────────────────────────────────────────
    // Diatonic index within octave for each semitone:
    //   C=0, C#=0, D=1, D#=1, E=2, F=3, F#=3, G=4, G#=4, A=5, A#=5, B=6
    // E4 (MIDI 64) = staff slot 0 (bottom line of treble staff).
    // Each slot = 0.5; slot increases upward (lower y).
    function midiToStaffSlot(midi) {
        var diatonic = [0, 0, 1, 1, 2, 3, 3, 4, 4, 5, 5, 6];
        var semitone = midi % 12;
        var octave   = Math.floor(midi / 12) - 1;
        var absD     = octave * 7 + diatonic[semitone];
        // E4: midi=64, octave=4, semitone=4 → diatonic=2 → absD = 4*7+2 = 30
        var e4AbsD   = 30;
        return (absD - e4AbsD) * 0.5;  // 0 = bottom line, 4 = top line
    }

    // ── UI Layout ──────────────────────────────────────────────────────────
    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 12
        spacing: 0

        // ── Header ──────────────────────────────────────────────
        RowLayout {
            Layout.fillWidth: true
            spacing: 0

            Text {
                text: "PITCH"
                font.family: "JetBrains Mono"
                font.pixelSize: 11
                font.weight: Font.Medium
                color: "#7777aa"
                font.letterSpacing: 1.5
            }

            Item { Layout.fillWidth: true }

            Text {
                text: pitchPanel.isSilent ? "—" : pitchPanel.currentNote
                font.family: "JetBrains Mono"
                font.pixelSize: 13
                font.bold: true
                color: "#00FF88"
            }
        }

        Item { Layout.preferredHeight: 10 }

        // ── Music staff ─────────────────────────────────────────
        Canvas {
            id: staffCanvas
            Layout.fillWidth: true
            implicitHeight: 110

            Component.onCompleted:          requestPaint()
            onVisibleChanged: if (visible)  requestPaint()
            onWidthChanged:                 requestPaint()
            onHeightChanged:                requestPaint()

            // Redraw when pitch changes
            Connections {
                target: pitchPanel
                function onCurrentMidiChanged()  { staffCanvas.requestPaint() }
                function onIsSilentChanged()      { staffCanvas.requestPaint() }
                function onCurrentCentsChanged()  { staffCanvas.requestPaint() }
            }

            onPaint: {
                var ctx = getContext("2d");
                ctx.clearRect(0, 0, width, height);

                // ── Draw 5 staff lines ──────────────────────────
                // Staff occupies middle 60% vertically, ledger-line headroom top/bottom
                var staffTop    = height * 0.22;
                var staffBottom = height * 0.78;
                var lineSpacing = (staffBottom - staffTop) / 4;  // 4 gaps between 5 lines

                ctx.strokeStyle = "rgba(255,255,255,0.25)";
                ctx.lineWidth   = 1;
                for (var i = 0; i < 5; i++) {
                    var ly = staffTop + i * lineSpacing;
                    ctx.beginPath();
                    ctx.moveTo(8, ly);
                    ctx.lineTo(width - 8, ly);
                    ctx.stroke();
                }

                // ── Draw treble clef label ──────────────────────
                ctx.fillStyle = "rgba(255,255,255,0.18)";
                ctx.font = "bold 11px JetBrains Mono";
                ctx.fillText("treble", 10, staffTop - 6);

                if (pitchPanel.isSilent) return;

                // ── Map MIDI → canvas Y ─────────────────────────
                // slot 0 = bottom line (staffBottom), slot 4 = top line (staffTop)
                // each half-slot = lineSpacing/2 upward
                var slot = pitchPanel.midiToStaffSlot(pitchPanel.currentMidi);

                // Canvas Y: slot 0 → staffBottom, higher slot → smaller Y
                var noteY = staffBottom - slot * (lineSpacing / 2);

                // ── Draw ledger lines (below bottom or above top) ─
                var cts = Math.abs(pitchPanel.currentCents);
                var noteColor = pitchPanel.accuracyColor(cts);

                ctx.strokeStyle = "rgba(255,255,255,0.4)";
                ctx.lineWidth = 1;

                // Below staff: ledger lines at slot -2, -1 (i.e. slots < 0 at integers)
                var slotInt = Math.round(slot * 2) / 2; // nearest even half
                var actualSlot = slot;
                if (actualSlot < 0) {
                    var ledgerSlot = -2;
                    while (ledgerSlot <= actualSlot + 0.5) {
                        if (ledgerSlot % 1 === 0 || ledgerSlot === Math.floor(actualSlot)) {
                            var ledy = staffBottom - ledgerSlot * (lineSpacing / 2);
                            ctx.beginPath();
                            ctx.moveTo(width * 0.4 - 12, ledy);
                            ctx.lineTo(width * 0.4 + 12, ledy);
                            ctx.stroke();
                        }
                        ledgerSlot += 2;
                    }
                }
                if (actualSlot > 4) {
                    var ledgerSlot2 = 6;
                    while (ledgerSlot2 >= actualSlot - 0.5) {
                        if ((ledgerSlot2 - 4) % 2 === 0) {
                            var ledy2 = staffBottom - ledgerSlot2 * (lineSpacing / 2);
                            ctx.beginPath();
                            ctx.moveTo(width * 0.4 - 12, ledy2);
                            ctx.lineTo(width * 0.4 + 12, ledy2);
                            ctx.stroke();
                        }
                        ledgerSlot2 -= 2;
                    }
                }

                // ── Draw accidental "#" if note contains sharp ──
                var noteStr = pitchPanel.currentNote;
                if (noteStr.indexOf("#") !== -1) {
                    ctx.fillStyle = "rgba(255,255,255,0.65)";
                    ctx.font = "bold 10px JetBrains Mono";
                    ctx.fillText("#", width * 0.4 - 22, noteY + 3.5);
                }

                // ── Draw note head (filled ellipse) ─────────────
                var nx = width * 0.4;
                var noteW = 11;
                var noteH = 7;

                // Glow / shadow
                ctx.shadowColor  = noteColor;
                ctx.shadowBlur   = 10;

                // Note head: rotated ellipse via arc + transform
                // (ctx.save/restore scopes the transform; path survives restore)
                ctx.save();
                ctx.translate(nx, noteY);
                ctx.rotate(-0.2);
                ctx.scale(noteW, noteH);
                ctx.beginPath();
                ctx.arc(0, 0, 1, 0, Math.PI * 2);
                ctx.restore();
                ctx.fillStyle = noteColor;
                ctx.fill();

                ctx.shadowBlur = 0;

                // ── Draw stem (upward if below middle, down if above) ──
                var stemUp = slot < 2;
                ctx.strokeStyle = "rgba(255,255,255,0.55)";
                ctx.lineWidth   = 1.2;
                ctx.beginPath();
                if (stemUp) {
                    ctx.moveTo(nx + noteW, noteY);
                    ctx.lineTo(nx + noteW, noteY - lineSpacing * 2.8);
                } else {
                    ctx.moveTo(nx - noteW, noteY);
                    ctx.lineTo(nx - noteW, noteY + lineSpacing * 2.8);
                }
                ctx.stroke();

                // ── Note label text to the right ────────────────
                ctx.fillStyle = "rgba(255,255,255,0.40)";
                ctx.font      = "10px JetBrains Mono";
                ctx.fillText(noteStr, nx + noteW + 5, noteY + 4);
            }
        }

        Item { Layout.preferredHeight: 10 }

        // ── Note name + frequency ────────────────────────────────
        RowLayout {
            Layout.fillWidth: true
            spacing: 0

            Text {
                text: pitchPanel.isSilent ? "—" : pitchPanel.currentNote
                font.family: "JetBrains Mono"
                font.pixelSize: 32
                font.bold: true
                color: pitchPanel.isSilent
                       ? "#444466"
                       : pitchPanel.accuracyColor(Math.abs(pitchPanel.currentCents))
                Behavior on color { ColorAnimation { duration: 150 } }
            }

            Item { Layout.fillWidth: true }

            ColumnLayout {
                spacing: 2
                Layout.alignment: Qt.AlignRight | Qt.AlignVCenter

                Text {
                    text: pitchPanel.isSilent ? "—.— Hz" : pitchPanel.currentFreq.toFixed(1) + " Hz"
                    font.family: "JetBrains Mono"
                    font.pixelSize: 12
                    color: "#aaaacc"
                    Layout.alignment: Qt.AlignRight
                }

                Text {
                    text: "MIDI " + (pitchPanel.isSilent ? "—" : pitchPanel.currentMidi.toString())
                    font.family: "JetBrains Mono"
                    font.pixelSize: 10
                    color: "#444466"
                    Layout.alignment: Qt.AlignRight
                }
            }
        }

        Item { Layout.preferredHeight: 10 }

        // ── Separator ────────────────────────────────────────────
        Rectangle {
            Layout.fillWidth: true
            height: 1
            color: "#2a2a4e"
        }

        Item { Layout.preferredHeight: 10 }

        // ── Intonation / cents meter ─────────────────────────────
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 6

            RowLayout {
                Layout.fillWidth: true
                spacing: 0

                Text {
                    text: "INTONATION"
                    font.family: "JetBrains Mono"
                    font.pixelSize: 11
                    font.weight: Font.Medium
                    color: "#7777aa"
                    font.letterSpacing: 1.5
                }

                Item { Layout.fillWidth: true }

                Text {
                    text: pitchPanel.isSilent
                          ? "— ¢"
                          : (pitchPanel.currentCents >= 0 ? "+" : "") + pitchPanel.currentCents.toFixed(0) + " ¢"
                    font.family: "JetBrains Mono"
                    font.pixelSize: 11
                    color: pitchPanel.isSilent
                           ? "#444466"
                           : pitchPanel.accuracyColor(Math.abs(pitchPanel.currentCents))
                    Behavior on color { ColorAnimation { duration: 150 } }
                }
            }

            // Cents bar: from -50 to +50, needle from center
            Item {
                Layout.fillWidth: true
                height: 8

                // Track
                Rectangle {
                    anchors.fill: parent
                    radius: 4
                    color: "#1a1a2e"
                }

                // Center tick
                Rectangle {
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.verticalCenter: parent.verticalCenter
                    width: 2
                    height: 14
                    color: Qt.rgba(1, 1, 1, 0.25)
                }

                // Needle from center
                Rectangle {
                    id: centsNeedle
                    anchors.verticalCenter: parent.verticalCenter
                    height: 8
                    radius: 3

                    visible: !pitchPanel.isSilent

                    property real clampedCents: pitchPanel.isSilent
                                                ? 0
                                                : Math.max(-50, Math.min(50, pitchPanel.currentCents))

                    // Range: -50 = far left of center, +50 = far right of center
                    // Needle x: center of parent = parent.width/2
                    // Positive cents → needle extends rightward from center
                    // Negative cents → needle extends leftward from center
                    x: clampedCents >= 0
                       ? parent.width / 2
                       : parent.width / 2 + (clampedCents / 50) * (parent.width / 2)
                    width: Math.abs(clampedCents) / 50 * (parent.width / 2)

                    color: pitchPanel.accuracyColor(Math.abs(pitchPanel.currentCents))
                    Behavior on color { ColorAnimation { duration: 150 } }
                    Behavior on x     { NumberAnimation { duration: 80 } }
                    Behavior on width { NumberAnimation { duration: 80 } }
                }
            }

            // -50 / 0 / +50 labels
            RowLayout {
                Layout.fillWidth: true
                spacing: 0

                Text {
                    text: "−50"
                    font.family: "JetBrains Mono"
                    font.pixelSize: 9
                    color: "#444466"
                }
                Item { Layout.fillWidth: true }
                Text {
                    text: "0"
                    font.family: "JetBrains Mono"
                    font.pixelSize: 9
                    color: "#444466"
                }
                Item { Layout.fillWidth: true }
                Text {
                    text: "+50"
                    font.family: "JetBrains Mono"
                    font.pixelSize: 9
                    color: "#444466"
                }
            }
        }

        Item { Layout.preferredHeight: 12 }

        // ── Separator ────────────────────────────────────────────
        Rectangle { Layout.fillWidth: true; height: 1; color: "#2a2a4e" }

        Item { Layout.preferredHeight: 10 }

        // ── Reference tuning (A4) ────────────────────────────────
        RowLayout {
            Layout.fillWidth: true
            spacing: 4

            Text {
                text: "A4"
                font.family: "JetBrains Mono"; font.pixelSize: 11
                font.weight: Font.Medium; color: "#7777aa"
                font.letterSpacing: 1.5
            }

            Item { Layout.fillWidth: true }

            Rectangle {
                width: 22; height: 22; radius: 4
                color: refMinusMa.containsMouse ? "#2a2a4e" : "transparent"
                border.color: "#2a2a4e"; border.width: 1
                Text {
                    anchors.centerIn: parent; text: "\u2212"
                    font.family: "JetBrains Mono"; font.pixelSize: 14; color: "#aaaacc"
                }
                MouseArea {
                    id: refMinusMa
                    anchors.fill: parent; hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: pitchPanel.refA4 = Math.max(380, Math.round((pitchPanel.refA4 - 1) * 10) / 10)
                }
            }

            TextInput {
                id: refInput
                text: pitchPanel.refA4.toFixed(1)
                font.family: "JetBrains Mono"; font.pixelSize: 12
                color: "#e0e0ff"
                width: 50; horizontalAlignment: TextInput.AlignHCenter
                selectByMouse: true
                validator: DoubleValidator { bottom: 380; top: 480; decimals: 1 }
                onEditingFinished: {
                    var v = parseFloat(text)
                    if (!isNaN(v) && v >= 380 && v <= 480) pitchPanel.refA4 = v
                    text = pitchPanel.refA4.toFixed(1)
                }
                Connections {
                    target: pitchPanel
                    function onRefA4Changed() {
                        if (!refInput.activeFocus) refInput.text = pitchPanel.refA4.toFixed(1)
                    }
                }
            }

            Text {
                text: "Hz"
                font.family: "JetBrains Mono"; font.pixelSize: 11; color: "#444466"
            }

            Rectangle {
                width: 22; height: 22; radius: 4
                color: refPlusMa.containsMouse ? "#2a2a4e" : "transparent"
                border.color: "#2a2a4e"; border.width: 1
                Text {
                    anchors.centerIn: parent; text: "+"
                    font.family: "JetBrains Mono"; font.pixelSize: 13; color: "#aaaacc"
                }
                MouseArea {
                    id: refPlusMa
                    anchors.fill: parent; hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: pitchPanel.refA4 = Math.min(480, Math.round((pitchPanel.refA4 + 1) * 10) / 10)
                }
            }

            // Reset to standard 440
            Rectangle {
                width: 32; height: 22; radius: 4
                color: resetRefMa.containsMouse ? "#2a2a4e" : "transparent"
                border.color: "#2a2a4e"; border.width: 1
                Text {
                    anchors.centerIn: parent; text: "440"
                    font.family: "JetBrains Mono"; font.pixelSize: 9
                    color: pitchPanel.refA4 === 440 ? "#2a2a4e" : "#aaaacc"
                }
                MouseArea {
                    id: resetRefMa
                    anchors.fill: parent; hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: pitchPanel.refA4 = 440
                }
            }
        }

        Item { Layout.preferredHeight: 12 }

        // ── Separator ────────────────────────────────────────────
        Rectangle { Layout.fillWidth: true; height: 1; color: "#2a2a4e" }

        Item { Layout.preferredHeight: 10 }

        // ── Metronome ────────────────────────────────────────────
        RowLayout {
            Layout.fillWidth: true
            spacing: 0

            Text {
                text: "M\u00C9TRONOME"
                font.family: "JetBrains Mono"; font.pixelSize: 11
                font.weight: Font.Medium; color: "#7777aa"
                font.letterSpacing: 1.5
            }

            Item { Layout.fillWidth: true }

            // Sound toggle
            Rectangle {
                width: 22; height: 22; radius: 4
                color: soundToggleMa.containsMouse ? "#2a2a4e"
                       : pitchPanel.metroClickEnabled ? "#4a4a8e" : "transparent"
                border.color: "#2a2a4e"; border.width: 1
                Text {
                    anchors.centerIn: parent; text: "\u266A"
                    font.family: "JetBrains Mono"; font.pixelSize: 13
                    color: pitchPanel.metroClickEnabled ? "#e0e0ff" : "#444466"
                }
                MouseArea {
                    id: soundToggleMa
                    anchors.fill: parent; hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: pitchPanel.metroClickEnabled = !pitchPanel.metroClickEnabled
                }
            }

            Item { Layout.preferredWidth: 6 }

            // Start / stop
            Rectangle {
                width: 28; height: 22; radius: 4
                color: startStopMa.containsMouse ? "#2a2a4e"
                       : pitchPanel.metroRunning ? "#4a4a8e" : "transparent"
                border.color: "#2a2a4e"; border.width: 1
                Text {
                    anchors.centerIn: parent
                    text: pitchPanel.metroRunning ? "\u25A0" : "\u25B6"
                    color: pitchPanel.metroRunning ? "#e0e0ff" : "#aaaacc"
                    font.family: "JetBrains Mono"; font.pixelSize: 11
                }
                MouseArea {
                    id: startStopMa
                    anchors.fill: parent; hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (!pitchPanel.metroRunning)
                            pitchPanel.beatIndex = -1
                        pitchPanel.metroRunning = !pitchPanel.metroRunning
                    }
                }
            }
        }

        Item { Layout.preferredHeight: 10 }

        // Beat indicator dots
        RowLayout {
            Layout.fillWidth: true
            spacing: 6

            Repeater {
                model: 4
                Rectangle {
                    required property int index
                    Layout.fillWidth: true
                    height: 10; radius: 5
                    property bool isActive: pitchPanel.metroRunning && pitchPanel.beatIndex === index
                    color: isActive
                           ? (index === 0 ? "#00FF88" : "#4a4a8e")
                           : "#1a1a2e"
                    Behavior on color { ColorAnimation { duration: 60 } }
                    SequentialAnimation on scale {
                        running: isActive
                        NumberAnimation { to: 1.15; duration: 40; easing.type: Easing.OutQuad }
                        NumberAnimation { to: 1.0;  duration: 120; easing.type: Easing.InQuad }
                    }
                }
            }
        }

        Item { Layout.preferredHeight: 10 }

        // BPM controls
        RowLayout {
            Layout.fillWidth: true
            spacing: 4

            Rectangle {
                width: 28; height: 24; radius: 4
                color: bpmMinus5Ma.containsMouse ? "#2a2a4e" : "transparent"
                border.color: "#1e1e30"; border.width: 1
                Text { anchors.centerIn: parent; text: "\u22125"
                    font.family: "JetBrains Mono"; font.pixelSize: 10; color: "#7777aa" }
                MouseArea {
                    id: bpmMinus5Ma; anchors.fill: parent; hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: pitchPanel.bpm = pitchPanel.clampBpm(pitchPanel.bpm - 5)
                }
            }

            Rectangle {
                width: 24; height: 24; radius: 4
                color: bpmMinus1Ma.containsMouse ? "#2a2a4e" : "transparent"
                border.color: "#1e1e30"; border.width: 1
                Text { anchors.centerIn: parent; text: "\u22121"
                    font.family: "JetBrains Mono"; font.pixelSize: 10; color: "#7777aa" }
                MouseArea {
                    id: bpmMinus1Ma; anchors.fill: parent; hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: pitchPanel.bpm = pitchPanel.clampBpm(pitchPanel.bpm - 1)
                }
            }

            Item {
                Layout.fillWidth: true
                height: 24
                TextInput {
                    id: bpmInput
                    anchors.centerIn: parent
                    width: parent.width
                    text: pitchPanel.bpm.toString()
                    font.family: "JetBrains Mono"; font.pixelSize: 18; font.bold: true
                    color: "#e0e0ff"
                    horizontalAlignment: TextInput.AlignHCenter
                    selectByMouse: true
                    validator: IntValidator { bottom: 20; top: 300 }
                    onEditingFinished: {
                        var v = parseInt(text)
                        if (!isNaN(v)) pitchPanel.bpm = pitchPanel.clampBpm(v)
                        text = pitchPanel.bpm.toString()
                        if (pitchPanel.metroRunning) metroTimer.restart()
                    }
                    Connections {
                        target: pitchPanel
                        function onBpmChanged() {
                            if (!bpmInput.activeFocus)
                                bpmInput.text = pitchPanel.bpm.toString()
                            if (pitchPanel.metroRunning) metroTimer.restart()
                        }
                    }
                }
            }

            Text {
                text: "bpm"
                font.family: "JetBrains Mono"; font.pixelSize: 10; color: "#444466"
                Layout.alignment: Qt.AlignBottom
                bottomPadding: 4
            }

            Rectangle {
                width: 24; height: 24; radius: 4
                color: bpmPlus1Ma.containsMouse ? "#2a2a4e" : "transparent"
                border.color: "#1e1e30"; border.width: 1
                Text { anchors.centerIn: parent; text: "+1"
                    font.family: "JetBrains Mono"; font.pixelSize: 10; color: "#7777aa" }
                MouseArea {
                    id: bpmPlus1Ma; anchors.fill: parent; hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: pitchPanel.bpm = pitchPanel.clampBpm(pitchPanel.bpm + 1)
                }
            }

            Rectangle {
                width: 28; height: 24; radius: 4
                color: bpmPlus5Ma.containsMouse ? "#2a2a4e" : "transparent"
                border.color: "#1e1e30"; border.width: 1
                Text { anchors.centerIn: parent; text: "+5"
                    font.family: "JetBrains Mono"; font.pixelSize: 10; color: "#7777aa" }
                MouseArea {
                    id: bpmPlus5Ma; anchors.fill: parent; hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: pitchPanel.bpm = pitchPanel.clampBpm(pitchPanel.bpm + 5)
                }
            }
        }

        Item { Layout.preferredHeight: 8 }

        // Tap tempo
        Rectangle {
            Layout.fillWidth: true
            height: 28; radius: 4
            color: tapMa.containsMouse ? "#2a2a4e" : "#1a1a2e"
            border.color: "#2a2a4e"; border.width: 1
            Text {
                anchors.centerIn: parent; text: "TAP TEMPO"
                font.family: "JetBrains Mono"; font.pixelSize: 11
                font.letterSpacing: 1.5
                color: tapMa.containsMouse ? "#e0e0ff" : "#7777aa"
            }
            MouseArea {
                id: tapMa
                anchors.fill: parent; hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: pitchPanel.tapTempo()
            }
        }

        Item { Layout.preferredHeight: 10 }

        // ── Separator ────────────────────────────────────────────
        Rectangle {
            Layout.fillWidth: true
            height: 1
            color: "#1e1e30"
        }

        Item { Layout.preferredHeight: 8 }

        // ── Microphone status ────────────────────────────────────
        RowLayout {
            Layout.fillWidth: true
            spacing: 6

            Rectangle {
                width: 7
                height: 7
                radius: 3.5
                color: pitchPanel.isSilent ? "#2a2a4e" : "#00FF88"
                Behavior on color { ColorAnimation { duration: 200 } }
            }

            Text {
                text: pitchPanel.isSilent ? "en attente du signal…" : "signal détecté"
                font.family: "JetBrains Mono"
                font.pixelSize: 10
                color: "#444466"
            }

            Item { Layout.fillWidth: true }

            Text {
                text: "aubio / yin"
                font.family: "JetBrains Mono"
                font.pixelSize: 9
                color: "#2a2a4e"
            }
        }

        // ── Bottom filler ────────────────────────────────────────
        Item { Layout.fillHeight: true }
    }
}
