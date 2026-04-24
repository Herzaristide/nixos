import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland

PanelWindow {
    id: panel

    property bool panelOpen: false
    property real panelWidth: 380
    readonly property real minWidth: 250
    readonly property real maxWidth: 600
    property int activeWidget: 0

    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.namespace: "quickshell-sidepanel"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand

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

    // ── Resize handle on left edge ────────────────────────────────
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
            panel.panelWidth = Math.max(panel.minWidth,
                Math.min(panel.maxWidth, startWidth + delta));
        }

        Rectangle {
            anchors.fill: parent
            color: resizeHandle.containsMouse || resizeHandle.pressed
                   ? "#FFFFFF" : "transparent"
            opacity: 0.2
        }
    }

    // ── Main content: icon bar + widget area ──────────────────────
    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 8
        anchors.topMargin: 8
        anchors.rightMargin: 8
        anchors.bottomMargin: 8
        spacing: 0
        visible: panelOpen

        // Widget area (fills remaining width)
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true

            StackLayout {
                anchors.fill: parent
                currentIndex: panel.activeWidget

                OllamaChat {}
                NotesWidget {}
            }
        }

        // Icon bar (vertical selector)
        Rectangle {
            Layout.preferredWidth: 48
            Layout.fillHeight: true
            color: "#1a1a2e"
            radius: 8

            Column {
                anchors.top: parent.top
                anchors.topMargin: 16
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 8

                Repeater {
                    model: ListModel {
                        ListElement { iconLabel: "AI"; widgetIndex: 0 }
                        ListElement { iconLabel: "✏"; widgetIndex: 1 }
                    }

                    delegate: Rectangle {
                        required property string iconLabel
                        required property int widgetIndex

                        width: 36
                        height: 36
                        radius: 6
                        color: panel.activeWidget === widgetIndex
                               ? "#4a4a8e"
                               : (iconMa.containsMouse ? "#2a2a4e" : "transparent")

                        Text {
                            anchors.centerIn: parent
                            text: iconLabel
                            color: "#FFFFFF"
                            font.family: "JetBrains Mono"
                            font.pixelSize: 12
                            font.bold: panel.activeWidget === widgetIndex
                            opacity: panel.activeWidget === widgetIndex ? 1.0 : 0.55
                        }

                        MouseArea {
                            id: iconMa
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: panel.activeWidget = widgetIndex
                        }
                    }
                }
            }
        }
    }
}
