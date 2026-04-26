import QtQuick
import QtQuick.Layouts
import Quickshell.Io

Item {
    id: root

    implicitHeight: controlsCol.implicitHeight + 16

    // ── State ──────────────────────────────────────────────────────────────
    property real  volumeLevel: 0.0
    property bool  isMuted:     false
    property string volString:   "vol  --"

    // ── wpctl get-volume ───────────────────────────────────────────────────
    Process {
        id: getVolProc
        command: ["sh", "-c", "wpctl get-volume @DEFAULT_AUDIO_SINK@"]
        stdout: StdioCollector { id: getVolOut }
        onRunningChanged: {
            if (!running) {
                var line = getVolOut.text.trim(); // e.g. "Volume: 0.75" or "Volume: 0.75 [MUTED]"
                var m = line.match(/Volume:\s*([\d.]+)(\s*\[MUTED\])?/);
                if (m) {
                    root.volumeLevel = parseFloat(m[1]);
                    root.isMuted     = m[2] !== undefined;
                    var pct = Math.round(root.volumeLevel * 100);
                    root.volString = root.isMuted
                        ? "vol  -- MUTED"
                        : "vol  " + pct + "%";
                }
            }
        }
    }

    // ── wpctl set-volume ───────────────────────────────────────────────────
    Process {
        id: setVolProc
        property string pendingCmd: ""
        command: ["sh", "-c", pendingCmd]
        onRunningChanged: {
            if (!running && !getVolProc.running) getVolProc.running = true;
        }
    }

    function volumeUp()   { setVolProc.pendingCmd = "wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+";    setVolProc.running = true; }
    function volumeDown() { setVolProc.pendingCmd = "wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-";    setVolProc.running = true; }
    function toggleMute() { setVolProc.pendingCmd = "wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle";   setVolProc.running = true; }

    // ── grimblast screenshot ───────────────────────────────────────────────
    Process {
        id: shotProc
        property string pendingCmd: ""
        command: ["sh", "-c", pendingCmd]
        onRunningChanged: {
            if (!running) notifyProc.running = true;
        }
    }

    Process {
        id: notifyProc
        command: ["notify-send", "-i", "camera-photo", "Screenshot", "Saved to /tmp/"]
    }

    function takeScreenshot(region) {
        var ts   = Qt.formatDateTime(new Date(), "yyyyMMdd_HHmmss");
        var path = "/tmp/screenshot-" + ts + ".png";
        shotProc.pendingCmd = "grimblast copysave " + region + " '" + path + "'";
        shotProc.running    = true;
    }

    // ── Refresh timer ──────────────────────────────────────────────────────
    Timer {
        interval: 3000
        repeat:   true
        running:  true
        onTriggered: { if (!getVolProc.running) getVolProc.running = true; }
    }

    Component.onCompleted: getVolProc.running = true

    // ── UI ─────────────────────────────────────────────────────────────────
    ColumnLayout {
        id: controlsCol
        anchors {
            left:   parent.left
            right:  parent.right
            top:    parent.top
            margins: 8
        }
        spacing: 6

        // Header row ─────────────────────────────────────────────────────
        RowLayout {
            Layout.fillWidth: true
            spacing: 6

            Text {
                text:            "CONTRÔLES"
                font.family:     "JetBrains Mono"
                font.pixelSize:  12
                font.bold:       true
                color:           Theme.accentColor
            }

            Item { Layout.fillWidth: true }

            // Volume buttons
            Repeater {
                model: [
                    { label: "[−]",    action: function() { root.volumeDown(); } },
                    { label: "[+]",    action: function() { root.volumeUp();   } },
                    { label: root.isMuted ? "[unmute]" : "[mute]", action: function() { root.toggleMute(); } }
                ]

                delegate: Text {
                    required property var modelData
                    text:            modelData.label
                    font.family:     "JetBrains Mono"
                    font.pixelSize:  11
                    color:           btnHover.containsMouse ? Theme.accentColor : Theme.textInactive
                    Behavior on color { ColorAnimation { duration: 100 } }
                    MouseArea {
                        id:           btnHover
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape:  Qt.PointingHandCursor
                        onClicked:    modelData.action()
                    }
                }
            }
        }

        // Volume readout ─────────────────────────────────────────────────
        Text {
            text:           root.volString
            font.family:    "JetBrains Mono"
            font.pixelSize: 11
            color:          root.isMuted ? Theme.textDim : Theme.textInactive
        }

        // Screenshot row ─────────────────────────────────────────────────
        RowLayout {
            Layout.fillWidth: true
            spacing: 6

            Text {
                text:           "CAPTURE"
                font.family:    "JetBrains Mono"
                font.pixelSize: 11
                font.bold:      true
                color:          Theme.textInactive
            }

            Item { Layout.fillWidth: true }

            Repeater {
                model: [
                    { label: "[screenshot]", region: "screen" },
                    { label: "[zone]",       region: "area"   }
                ]

                delegate: Text {
                    required property var modelData
                    text:           modelData.label
                    font.family:    "JetBrains Mono"
                    font.pixelSize: 11
                    color:          shotBtnHover.containsMouse ? Theme.accentColor : Theme.textInactive
                    Behavior on color { ColorAnimation { duration: 100 } }
                    MouseArea {
                        id:           shotBtnHover
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape:  Qt.PointingHandCursor
                        onClicked:    root.takeScreenshot(modelData.region)
                    }
                }
            }
        }

        // Bottom separator ───────────────────────────────────────────────
        Rectangle {
            Layout.fillWidth: true
            height:           1
            color:            Theme.dividerColor
            Layout.topMargin: 2
        }
    }
}
