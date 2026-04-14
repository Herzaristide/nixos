import Quickshell

ShellRoot {
    Variants {
        model: Quickshell.screens

        BottomBar {
            property var modelData
            screen: modelData
        }
    }
}
