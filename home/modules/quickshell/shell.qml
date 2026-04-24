import Quickshell

ShellRoot {
    id: root
    property bool panelOpen: false
    property bool hardwareOpen: false

    Variants {
        model: Quickshell.screens

        BottomBar {
            property var modelData
            screen: modelData
            panelOpen: root.panelOpen
            hardwareOpen: root.hardwareOpen
            onTogglePanel: root.panelOpen = !root.panelOpen
            onToggleHardware: root.hardwareOpen = !root.hardwareOpen
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

    Variants {
        model: Quickshell.screens

        HardwareStats {
            property var modelData
            screen: modelData
            hardwareOpen: root.hardwareOpen
            onCloseRequested: root.hardwareOpen = false
        }
    }
}
