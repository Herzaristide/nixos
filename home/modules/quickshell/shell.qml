import Quickshell

ShellRoot {
    id: root
    property bool panelOpen: false
    property int activeWidget: 0

    Variants {
        model: Quickshell.screens

        BottomBar {
            property var modelData
            screen: modelData
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
            panelOpen: root.panelOpen
            activeWidget: root.activeWidget
        }
    }
}
