import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import Quickshell.Services.Pipewire
import Quickshell.Services.SystemTray
import QtQuick
import QtQuick.Layouts

import "components" as Components

PanelWindow {
	property var modelData
	screen: modelData

	anchors.bottom: true
	anchors.left: true
	anchors.right: true
	implicitHeight: 48

	// Transparent window background
	color: "transparent"

	// Minimalist geometric background panel
	Rectangle {
		anchors.fill: parent
		anchors.margins: 4
		anchors.bottomMargin: 0
		radius: 4
		color: "#0a0a0a"
		border.color: "#2a2a2a"
		border.width: 1
		opacity: 0.9
	}

	// Get current monitor's active workspace
	property var currentMonitor: {
		const monitors = Hyprland.monitors
		if (!monitors) return null
		for (let i = 0; i < monitors.length; i++) {
			if (monitors[i].name === modelData.name) {
				return monitors[i]
			}
		}
		return null
	}

	property int activeWorkspaceId: currentMonitor?.activeWorkspace?.id ?? -1
	property var activeWindow: currentMonitor?.activeWindow ?? null

	RowLayout {
		anchors.fill: parent
		anchors.leftMargin: 16
		anchors.rightMargin: 16
		anchors.topMargin: 6
		anchors.bottomMargin: 6
		spacing: 12

		// Left section: Workspaces + Active Window
		RowLayout {
			spacing: 12
			Layout.fillWidth: false

			// Workspaces
			Components.Workspaces {
				activeWorkspaceId: parent.parent.parent.activeWorkspaceId
			}

			// Active window title
			Components.WindowTitle {
				activeWindow: parent.parent.parent.activeWindow
			}
		}

		Item { Layout.fillWidth: true }

		// Center section: System Tray
		Components.SystemTrayComponent {
			Layout.alignment: Qt.AlignCenter
		}

		Item { Layout.fillWidth: true }

		// Right section: System info + Clock
		RowLayout {
			spacing: 8
			Layout.fillWidth: false

			// System stats
			Components.SystemStats {}

			// Network
			Components.Network {}

			// Audio
			Components.Audio {}

			// Battery (only on laptop)
			Components.Battery {
				visible: modelData.name.includes("eDP")
			}

			// Clock
			Components.Clock {}
		}
	}
}
