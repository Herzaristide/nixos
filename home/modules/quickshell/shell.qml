import Quickshell

ShellRoot {
    id: root
    property bool panelOpen: false

    Variants {
        model: Quickshell.screens

        BottomBar {
            property var modelData
            screen: modelData
            panelOpen: root.panelOpen
            onTogglePanel: root.panelOpen = !root.panelOpen
        }
    }

    Variants {
        model: Quickshell.screens

        SidePanel {
            property var modelData
            screen: modelData
            panelOpen: root.panelOpen
        }
    }
}
