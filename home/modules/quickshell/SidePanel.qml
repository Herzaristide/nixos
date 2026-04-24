import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland

PanelWindow {
    id: panel

    property bool panelOpen: false
    property real panelWidth: 250
    readonly property real minWidth: 150
    readonly property real maxWidth: 500

    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.namespace: "quickshell-sidepanel"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

    anchors {
        top: true
        right: true
        bottom: true
    }

    visible: screen && screen.name === "HDMI-A-1"

    width: panelOpen ? panelWidth : 0
    Behavior on width { enabled: false }
    exclusiveZone: width

    color: "transparent"

    margins {
        bottom: 28
    }

    // Resize handle on left edge
    MouseArea {
        id: resizeHandle
        width: 8
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        cursorShape: Qt.SizeHorCursor
        hoverEnabled: true
        preventStealing: true

        property real startGlobalX: 0
        property real startWidth: 0

        onPressed: (mouse) => {
            startGlobalX = mapToGlobal(mouse.x, 0).x;
            startWidth = panel.panelWidth;
        }

        onPositionChanged: (mouse) => {
            if (!pressed) return;
            const currentGlobalX = mapToGlobal(mouse.x, 0).x;
            const delta = startGlobalX - currentGlobalX;
            panel.panelWidth = Math.max(panel.minWidth, Math.min(panel.maxWidth, startWidth + delta));
        }

        Rectangle {
            anchors.fill: parent
            color: resizeHandle.containsMouse || resizeHandle.pressed ? "#FFFFFF" : "transparent"
            opacity: 0.2
        }
    }

    Column {
        anchors.fill: parent
        anchors.leftMargin: 22
        anchors.topMargin: 16
        anchors.rightMargin: 16
        anchors.bottomMargin: 16
        spacing: 12
        visible: panelOpen

        Text {
            text: "Apps"
            font.family: "JetBrains Mono"
            font.pixelSize: 13
            font.weight: Font.Bold
            color: "#FFFFFF"
            opacity: 0.5
        }

        Repeater {
            model: ListModel {
                ListElement { name: "Terminal"; cmd: "wezterm"; icon: ">" }
                ListElement { name: "Browser"; cmd: "chromium"; icon: "B" }
            }

            Rectangle {
                required property string name
                required property string cmd
                required property string icon
                required property int index

                width: parent ? parent.width : 0
                height: 36
                radius: 6
                color: appMouse.containsMouse ? "#2a2a4e" : "transparent"

                Row {
                    anchors.fill: parent
                    anchors.leftMargin: 10
                    spacing: 10

                    Text {
                        text: icon
                        font.family: "JetBrains Mono"
                        font.pixelSize: 16
                        color: "#FFFFFF"
                        opacity: 0.7
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    Text {
                        text: name
                        font.family: "JetBrains Mono"
                        font.pixelSize: 13
                        color: "#FFFFFF"
                        opacity: 0.9
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }

                MouseArea {
                    id: appMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        Hyprland.dispatch("exec " + cmd);
                    }
                }
            }
        }
    }
}
