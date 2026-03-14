import Quickshell
import Quickshell.Hyprland
import QtQuick
import QtQuick.Layouts

RowLayout {
	id: root
	spacing: 6

	property int activeWorkspaceId: -1

	Repeater {
		model: 5

		Rectangle {
			required property int index
			property int workspaceId: index + 1
			property bool isActive: root.activeWorkspaceId === workspaceId
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

			Layout.preferredWidth: isActive ? 56 : 32
			Layout.preferredHeight: 32
			radius: 6

			// Smooth width animation
			Behavior on Layout.preferredWidth {
				NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
			}

			// Minimalist white design with black accents
			color: isActive ? "#000000" : (hasWindows ? "#f5f5f5" : "#ffffff")
			border.color: isActive ? "#000000" : (hasWindows ? "#cccccc" : "#e0e0e0")
			border.width: 2

			Behavior on color {
				ColorAnimation { duration: 200 }
			}

			Behavior on border.color {
				ColorAnimation { duration: 200 }
			}

			// Subtle shadow for active workspace
			layer.enabled: isActive
			layer.effect: ShaderEffect {
				property real shadowOpacity: 0.1
			}

			// Workspace number or indicator
			Item {
				anchors.centerIn: parent
				width: parent.width
				height: parent.height

				// Number for active workspace - white on black
				Text {
					anchors.centerIn: parent
					text: parent.parent.workspaceId
					color: "#ffffff"
					font.pixelSize: 14
					font.weight: Font.Bold
					visible: parent.parent.isActive
				}

				// Filled circle for inactive workspaces with windows
				Rectangle {
					anchors.centerIn: parent
					width: 8
					height: 8
					radius: 4
					color: "#000000"
					visible: !parent.parent.isActive && parent.parent.hasWindows
				}

				// Empty circle for empty workspaces
				Rectangle {
					anchors.centerIn: parent
					width: 6
					height: 6
					radius: 3
					color: "transparent"
					border.color: "#cccccc"
					border.width: 2
					visible: !parent.parent.isActive && !parent.parent.hasWindows
				}
			}

			MouseArea {
				anchors.fill: parent
				cursorShape: Qt.PointingHandCursor
				hoverEnabled: true

				onEntered: parent.scale = 1.05
				onExited: parent.scale = 1.0
				onClicked: function() {
					Hyprland.dispatch("workspace " + parent.workspaceId)
				}
			}

			// Hover scale animation
			Behavior on scale {
				NumberAnimation { duration: 150; easing.type: Easing.OutCubic }
			}
		}
	}
}
