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
			radius: 3

			// Smooth width animation
			Behavior on Layout.preferredWidth {
				NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
			}

			// Minimalist geometric design - black bg with white accents
			color: isActive ? "#1a1a1a" : (hasWindows ? "#0d0d0d" : "transparent")
			border.color: isActive ? "#ffffff" : (hasWindows ? "#4a4a4a" : "#2a2a2a")
			border.width: 2

			// Subtle glow for active workspace
			Rectangle {
				anchors.fill: parent
				anchors.margins: -3
				radius: parent.radius
				color: "transparent"
				border.color: "#ffffff"
				border.width: isActive ? 1 : 0
				opacity: isActive ? 0.3 : 0
				z: -1

				// Gentle pulsing glow
				SequentialAnimation on opacity {
					running: isActive
					loops: Animation.Infinite
					NumberAnimation { from: 0.2; to: 0.4; duration: 1500; easing.type: Easing.InOutSine }
					NumberAnimation { from: 0.4; to: 0.2; duration: 1500; easing.type: Easing.InOutSine }
				}
			}

			// Workspace number or indicator
			Item {
				anchors.centerIn: parent
				width: parent.width
				height: parent.height

				// Number for active workspace - white on dark
				Text {
					anchors.centerIn: parent
					text: parent.parent.workspaceId
					color: "#ffffff"
					font.pixelSize: 14
					font.weight: Font.Bold
					visible: parent.parent.isActive
				}

				// Geometric diamond for inactive workspaces with windows
				Rectangle {
					anchors.centerIn: parent
					width: 7
					height: 7
					rotation: 45
					color: "transparent"
					border.color: "#cccccc"
					border.width: 2
					visible: !parent.parent.isActive && parent.parent.hasWindows
				}

				// Small circle for empty workspaces
				Rectangle {
					anchors.centerIn: parent
					width: 5
					height: 5
					radius: 2.5
					color: "transparent"
					border.color: "#444444"
					border.width: 1
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
