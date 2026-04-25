import QtQuick
import Quickshell

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
