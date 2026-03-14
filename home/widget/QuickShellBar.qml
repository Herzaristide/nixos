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

	// Minimalist white background panel with subtle shadow
	Rectangle {
		anchors.fill: parent
		anchors.margins: 6
		anchors.bottomMargin: 0
		radius: 8
		color: "#ffffff"
		border.color: "#e0e0e0"
		border.width: 1
		opacity: 0.95

		layer.enabled: true
		layer.effect: ShaderEffect {
			property real shadowOpacity: 0.1
			fragmentShader: "
				varying highp vec2 qt_TexCoord0;
				uniform sampler2D source;
				uniform lowp float qt_Opacity;
				void main() {
					gl_FragColor = texture2D(source, qt_TexCoord0) * qt_Opacity;
				}
			"
		}
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

			// Microphone
			Components.Microphone {}

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
