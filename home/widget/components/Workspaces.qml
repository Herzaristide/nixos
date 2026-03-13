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
			radius: 16

			// Smooth width animation
			Behavior on Layout.preferredWidth {
				NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
			}

			// Background with autumn gradient when active
			gradient: isActive ? activeGradient : null
			color: isActive ? "transparent" : (hasWindows ? "#3a3a3a" : "#2a2a2a")

			Gradient {
				id: activeGradient
				orientation: Gradient.Horizontal
				GradientStop { position: 0.0; color: "#DC143C" }
				GradientStop { position: 0.5; color: "#FF6347" }
				GradientStop { position: 1.0; color: "#FF7F50" }
			}

			// Glowing border for active workspace
			Rectangle {
				anchors.fill: parent
				anchors.margins: -2
				radius: parent.radius + 2
				color: "transparent"
				border.color: "#FF6347"
				border.width: isActive ? 2 : 0
				opacity: isActive ? 0.6 : 0
				z: -1

				// Pulsing glow effect
				SequentialAnimation on opacity {
					running: isActive
					loops: Animation.Infinite
					NumberAnimation { from: 0.6; to: 0.9; duration: 1200; easing.type: Easing.InOutSine }
					NumberAnimation { from: 0.9; to: 0.6; duration: 1200; easing.type: Easing.InOutSine }
				}
			}

			// Workspace number or indicator
			Item {
				anchors.centerIn: parent
				width: parent.width
				height: parent.height

				// Number for active workspace
				Text {
					anchors.centerIn: parent
					text: parent.parent.workspaceId
					color: parent.parent.isActive ? "#1a1a1a" : "#c0c0c0"
					font.pixelSize: 14
					font.weight: parent.parent.isActive ? Font.Bold : Font.Medium
					visible: parent.parent.isActive

					// Subtle text shadow for depth
					style: parent.parent.isActive ? Text.Raised : Text.Normal
					styleColor: parent.parent.isActive ? "#FF7F50" : "transparent"
				}

				// Dot for inactive workspaces with windows - autumn orange
				Rectangle {
					anchors.centerIn: parent
					width: 6
					height: 6
					radius: 3
					color: "#FF7F50"
					visible: !parent.parent.isActive && parent.parent.hasWindows
				}

				// Small dot for empty workspaces
				Rectangle {
					anchors.centerIn: parent
					width: 4
					height: 4
					radius: 2
					color: "#5a5a5a"
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
