import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts

PanelWindow {
	property var modelData
	screen: modelData

	anchors.bottom: true
	anchors.left: true
	anchors.right: true
	implicitHeight: 30
	color: "#1a1b26"

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

	RowLayout {
		anchors.fill: parent
		anchors.margins: 8
		spacing: 8

		// Workspace buttons (1-5 as configured in hyprland.nix)
		RowLayout {
			spacing: 4

			Repeater {
				model: 5

				Rectangle {
					required property int index
					property int workspaceId: index + 1
					property bool isActive: activeWorkspaceId === workspaceId
					property bool hasWindows: {
						const workspaces = Hyprland.workspaces
						if (!workspaces) return false
						for (let i = 0; i < workspaces.length; i++) {
							if (workspaces[i].id === workspaceId && workspaces[i].windows.length > 0) {
								return true
							}
						}
						return false
					}

					Layout.preferredWidth: 40
					Layout.preferredHeight: 22
					radius: 4
					color: isActive ? "#7aa2f7" : "#414868"

					Text {
						anchors.centerIn: parent
						text: parent.workspaceId
						color: parent.isActive ? "#1a1b26" : "#a9b1d6"
						font.pixelSize: 12
						font.bold: parent.isActive
					}

					MouseArea {
						anchors.fill: parent
						cursorShape: Qt.PointingHandCursor
						onClicked: {
							Hyprland.dispatch("workspace", parent.workspaceId.toString())
						}
					}

					// Indicator for workspaces with windows
					Rectangle {
						width: 4
						height: 4
						radius: 2
						anchors.horizontalCenter: parent.horizontalCenter
						anchors.bottom: parent.bottom
						anchors.bottomMargin: 3
						visible: parent.hasWindows
						color: "#9ece6a"
					}
				}
			}
		}

		Item { Layout.fillWidth: true }

		// Monitor name
		Text {
			text: modelData.name
			color: "#565f89"
			font.pixelSize: 12
		}

		// Clock
		Text {
			id: clock
			color: "#a9b1d6"
			font.pixelSize: 14
			text: Qt.formatDateTime(new Date(), "HH:mm")
			Timer {
				interval: 1000
				running: true
				repeat: true
				onTriggered: clock.text = Qt.formatDateTime(new Date(), "HH:mm")
			}
		}
	}
}
