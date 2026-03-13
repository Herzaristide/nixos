import Quickshell
import Quickshell.Wayland
import QtQuick

ShellRoot {
	Variants {
		model: Quickshell.screens

		QuickShellBar {
			modelData: modelData
		}
	}
}
