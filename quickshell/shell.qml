import QtQuick
import Quickshell
import Quickshell.Io

ShellRoot {
    id: root

    QtObject {
        Component.onCompleted: {
            Qt.application.name = "quickshell";
            Qt.application.organization = "quickshell";
            Qt.application.domain = "quickshell.local";
        }
    }

    property bool panelOpen: false
    property int activeWidget: 0

    // ── IPC externe via FIFO /tmp/qs-panel.fifo ──────────────────────────
    //   echo "widget:N" > /tmp/qs-panel.fifo   → bascule le widget N
    //   echo "close"    > /tmp/qs-panel.fifo   → ferme le panel
    //   N : 0=Stats  1=IA  2=Notes  3=Pitch  4=Music
    Process {
        id: ipcListener
        command: [
            "bash", "-c",
            "rm -f /tmp/qs-panel.fifo; mkfifo /tmp/qs-panel.fifo; " +
            "exec 3<>/tmp/qs-panel.fifo; " +
            "while IFS= read -r line <&3; do echo \"$line\"; done"
        ]
        running: true
        stdout: SplitParser {
            onRead: (data) => {
                var msg = data.trim();
                if (msg.startsWith("widget:")) {
                    var idx = parseInt(msg.substring(7));
                    if (!isNaN(idx)) {
                        if (root.panelOpen && root.activeWidget === idx)
                            root.panelOpen = false;
                        else {
                            root.activeWidget = idx;
                            root.panelOpen = true;
                        }
                    }
                } else if (msg === "close") {
                    root.panelOpen = false;
                }
            }
        }
        onExited: Qt.callLater(function() { ipcListener.running = true; })
    }

    Variants {
        model: Quickshell.screens

        BottomBar {
            property var modelData
            screen: modelData
            visible: modelData && modelData.name === "HDMI-A-1"
            panelOpen: root.panelOpen
            activeWidget: root.activeWidget
            onSelectWidget: (idx) => {
                if (root.panelOpen && root.activeWidget === idx) {
                    root.panelOpen = false;
                } else {
                    root.activeWidget = idx;
                    root.panelOpen = true;
                }
            }
        }
    }

    Variants {
        model: Quickshell.screens

        SidePanel {
            property var modelData
            screen: modelData
            visible: modelData && modelData.name === "HDMI-A-1"
            panelOpen: root.panelOpen
            activeWidget: root.activeWidget
        }
    }
}
