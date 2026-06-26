import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland

PanelWindow {
    id: panel

    property bool panelOpen: false
    property int activeWidget: 0
    property real panelWidth: 380
    readonly property real minWidth: 250
    readonly property real maxWidth: 600

    WlrLayershell.layer: WlrLayer.Bottom
    WlrLayershell.namespace: "quickshell-sidepanel"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand

    anchors {
        top: true
        left: true
        bottom: true
    }

    implicitWidth: panelOpen ? panelWidth : 0
    Behavior on implicitWidth { enabled: false }
    exclusiveZone: implicitWidth

    color: "transparent"

    margins {
        left: 8
    }

    // ── Resize handle on right edge ──────────────────────────────
    MouseArea {
        id: resizeHandle
        width: 8
        anchors.right: parent.right
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
            const delta = currentGlobalX - startGlobalX;
            panel.panelWidth = Math.max(panel.minWidth,
                Math.min(panel.maxWidth, startWidth + delta));
        }

        Rectangle {
            anchors.fill: parent
            color: resizeHandle.containsMouse || resizeHandle.pressed
                   ? Theme.iconColor : "transparent"
            opacity: 0.2
        }
    }

    // ── Main content ─────────────────────────────────────────────
    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 8
        anchors.leftMargin: 0
        anchors.rightMargin: 12
        visible: panelOpen
        spacing: 0

        // Always-visible controls: volume + screenshot
        QuickControls {
            Layout.fillWidth: true
        }

        StackLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            currentIndex: panel.activeWidget

            HardwareStats {}
            AIPanel {}
            NotesWidget {}
            Metronome {}
            MusicPlayerWidget {}
        }
    }
}
