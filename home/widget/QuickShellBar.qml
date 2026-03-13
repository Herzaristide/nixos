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
	implicitHeight: 44

	// Autumn forest inspired colors matching wallpaper
	color: "#1a1a1a"

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

	// Glassmorphic background effect
	Rectangle {
		anchors.fill: parent
		color: "transparent"

		Rectangle {
			anchors.fill: parent
			color: "#1a1a1a"
			opacity: 0.88
		}

		// Top border accent - autumn gradient
		Rectangle {
			anchors.top: parent.top
			anchors.left: parent.left
			anchors.right: parent.right
			height: 2
			gradient: Gradient {
				orientation: Gradient.Horizontal
				GradientStop { position: 0.0; color: "#DC143C" }
				GradientStop { position: 0.33; color: "#FF6347" }
				GradientStop { position: 0.66; color: "#FF7F50" }
				GradientStop { position: 1.0; color: "#D2691E" }
			}
		}
	}

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

			// Separator
			Rectangle {
				Layout.preferredWidth: 1
				Layout.preferredHeight: 24
				color: "#4a4a4a"
				opacity: 0.5
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

			// Separator
			Rectangle {
				Layout.preferredWidth: 1
				Layout.preferredHeight: 24
				color: "#4a4a4a"
				opacity: 0.5
			}

			// Network
			Components.Network {}

			// Separator
			Rectangle {
				Layout.preferredWidth: 1
				Layout.preferredHeight: 24
				color: "#4a4a4a"
				opacity: 0.5
			}

			// Audio
			Components.Audio {}

			// Battery (only on laptop)
			Components.Battery {
				visible: modelData.name.includes("eDP")
			}

			// Separator
			Rectangle {
				Layout.preferredWidth: 1
				Layout.preferredHeight: 24
				color: "#4a4a4a"
				opacity: 0.5
			}

			// Clock
			Components.Clock {}
		}
	}
}
