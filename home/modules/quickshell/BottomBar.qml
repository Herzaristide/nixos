import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland

PanelWindow {
    id: window

    property bool panelOpen: false
    property int activeWidget: 0
    signal selectWidget(int index)

    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.namespace: "quickshell-leftbar"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

    anchors {
        top: true
        bottom: true
        left: true
    }

    width: 48
    color: "transparent"

    visible: screen && screen.name === "HDMI-A-1"

    function toRoman(num) {
        const romanNumerals = ["I", "II", "III", "IV", "V"];
        return romanNumerals[num - 1] || "";
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.topMargin: 12
        anchors.bottomMargin: 12
        spacing: 0

        // ── NixOS button (HardwareStats) ─────────────────────────
        Item {
            Layout.alignment: Qt.AlignHCenter
            Layout.preferredWidth: 36
            Layout.preferredHeight: 36

            Rectangle {
                anchors.fill: parent
                radius: 8
                color: window.panelOpen && window.activeWidget === 0
                       ? "#4a4a8e" : (nixMa.containsMouse ? "#2a2a4e" : "transparent")

                Image {
                    anchors.centerIn: parent
                    width: 20
                    height: 20
                    source: "nixos.svg"
                    sourceSize.width: 64
                    sourceSize.height: 64
                    fillMode: Image.PreserveAspectFit
                    smooth: true
                    opacity: window.panelOpen && window.activeWidget === 0 ? 1.0 : 0.7
                }

                MouseArea {
                    id: nixMa
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: window.selectWidget(0)
                }
            }
        }

        Item { Layout.preferredHeight: 8 }

        // ── AI button (OllamaChat) ───────────────────────────────
        Item {
            Layout.alignment: Qt.AlignHCenter
            Layout.preferredWidth: 36
            Layout.preferredHeight: 36

            Rectangle {
                anchors.fill: parent
                radius: 8
                color: window.panelOpen && window.activeWidget === 1
                       ? "#4a4a8e" : (aiMa.containsMouse ? "#2a2a4e" : "transparent")

                Text {
                    anchors.centerIn: parent
                    text: "AI"
                    font.family: "JetBrains Mono"
                    font.pixelSize: 11
                    font.bold: window.panelOpen && window.activeWidget === 1
                    color: "#FFFFFF"
                    opacity: window.panelOpen && window.activeWidget === 1 ? 1.0 : 0.55
                }

                MouseArea {
                    id: aiMa
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: window.selectWidget(1)
                }
            }
        }

        Item { Layout.preferredHeight: 8 }

        // ── Notes button ─────────────────────────────────────────
        Item {
            Layout.alignment: Qt.AlignHCenter
            Layout.preferredWidth: 36
            Layout.preferredHeight: 36

            Rectangle {
                anchors.fill: parent
                radius: 8
                color: window.panelOpen && window.activeWidget === 2
                       ? "#4a4a8e" : (notesMa.containsMouse ? "#2a2a4e" : "transparent")

                Text {
                    anchors.centerIn: parent
                    text: "\u270F"
                    font.pixelSize: 14
                    color: "#FFFFFF"
                    opacity: window.panelOpen && window.activeWidget === 2 ? 1.0 : 0.55
                }

                MouseArea {
                    id: notesMa
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: window.selectWidget(2)
                }
            }
        }

        // ── Top spacer ───────────────────────────────────────────
        Item { Layout.fillHeight: true }

        // ── Workspace selector (vertical, centered) ──────────────
        Repeater {
            model: 5

            Item {
                required property int index
                Layout.alignment: Qt.AlignHCenter
                Layout.preferredWidth: 36
                Layout.preferredHeight: 28

                Text {
                    anchors.centerIn: parent
                    text: window.toRoman(parent.index + 1)
                    font.family: "JetBrains Mono"
                    font.pixelSize: 14
                    font.weight: Font.Normal
                    color: "#FFFFFF"

                    opacity: {
                        const workspaceId = parent.index + 1;
                        const isActive = Hyprland.focusedWorkspace?.id === workspaceId;

                        if (isActive) return 1.0;

                        if (Hyprland.workspaces && Hyprland.workspaces.values) {
                            const workspace = Hyprland.workspaces.values.find(ws => ws.id === workspaceId);
                            const hasWindows = workspace && workspace.windows && workspace.windows.values && workspace.windows.values.length > 0;
                            return hasWindows ? 0.6 : 0.3;
                        }

                        return 0.3;
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: Hyprland.dispatch("workspace " + (parent.index + 1).toString())
                }
            }
        }

        // ── Bottom spacer ────────────────────────────────────────
        Item { Layout.fillHeight: true }
    }
}
