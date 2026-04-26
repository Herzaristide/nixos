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

    WlrLayershell.layer: WlrLayer.Bottom
    WlrLayershell.namespace: "quickshell-leftbar"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

    anchors {
        top: true
        bottom: true
        left: true
    }

    implicitWidth: 48
    color: "transparent"

    function toRoman(num) {
        const romanNumerals = ["I", "II", "III", "IV", "V"];
        return romanNumerals[num - 1] || "";
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.topMargin: 12
        anchors.bottomMargin: 12
        spacing: 0

        // ── AI button (OllamaChat) ───────────────────────────────
        Item {
            Layout.alignment: Qt.AlignHCenter
            Layout.preferredWidth: 36
            Layout.preferredHeight: 36

            Rectangle {
                anchors.fill: parent
                radius: 8
                color: window.panelOpen && window.activeWidget === 1
                       ? Theme.accentColor : (aiMa.containsMouse ? Theme.accentDark : "transparent")

                Text {
                    anchors.centerIn: parent
                    text: "AI"
                    font.family: "JetBrains Mono"
                    font.pixelSize: 12
                    color: Theme.iconColor
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
                       ? Theme.accentColor : (notesMa.containsMouse ? Theme.accentDark : "transparent")

                Text {
                    anchors.centerIn: parent
                    text: "N"
                    font.family: "JetBrains Mono"
                    font.pixelSize: 14
                    color: Theme.iconColor
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

        Item { Layout.preferredHeight: 8 }

        // ── Pitch Analyzer button ────────────────────────────────────
        Item {
            Layout.alignment: Qt.AlignHCenter
            Layout.preferredWidth: 36
            Layout.preferredHeight: 36

            Rectangle {
                anchors.fill: parent
                radius: 8
                color: window.panelOpen && window.activeWidget === 3
                       ? Theme.accentColor : (pitchMa.containsMouse ? Theme.accentDark : "transparent")

                Text {
                    anchors.centerIn: parent
                    text: "~"
                    font.family: "JetBrains Mono"
                    font.pixelSize: 16
                    color: Theme.iconColor
                    opacity: window.panelOpen && window.activeWidget === 3 ? 1.0 : 0.55
                }

                MouseArea {
                    id: pitchMa
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: window.selectWidget(3)
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
                    color: Theme.iconColor

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

        // ── Settings button ──────────────────────────────────────
        Item {
            Layout.alignment: Qt.AlignHCenter
            Layout.preferredWidth: 36
            Layout.preferredHeight: 36

            Rectangle {
                anchors.fill: parent
                radius: 8
                color: window.panelOpen && window.activeWidget === 4
                       ? Theme.accentColor : (settingsMa.containsMouse ? Theme.accentDark : "transparent")

                Text {
                    anchors.centerIn: parent
                    text: "⚙"
                    font.family: "JetBrains Mono"
                    font.pixelSize: 14
                    color: Theme.iconColor
                    opacity: window.panelOpen && window.activeWidget === 4 ? 1.0 : 0.55
                }

                MouseArea {
                    id: settingsMa
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: window.selectWidget(4)
                }
            }
        }

        Item { Layout.preferredHeight: 8 }

        // ── NixOS button (HardwareStats) ─────────────────────────
        Item {
            Layout.alignment: Qt.AlignHCenter
            Layout.preferredWidth: 36
            Layout.preferredHeight: 36

            Rectangle {
                anchors.fill: parent
                radius: 8
                color: window.panelOpen && window.activeWidget === 0
                       ? Theme.accentColor : (nixMa.containsMouse ? Theme.accentDark : "transparent")

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
    }
}
