import Quickshell
import Quickshell.Hyprland
import QtQuick
import QtQuick.Layouts

RowLayout {
	id: root
	spacing: 8

	property var activeWindow: null
	property string windowTitle: activeWindow?.title ?? ""
	property string windowClass: activeWindow?.class ?? ""

	Layout.maximumWidth: 400

	// App icon (using first letter of class)
	Rectangle {
		Layout.preferredWidth: 28
		Layout.preferredHeight: 28
		radius: 3
		visible: root.windowTitle !== ""
		color: "#0d0d0d"
		border.color: "#ffffff"
		border.width: 2

		Text {
			anchors.centerIn: parent
			text: root.windowClass.length > 0 ? root.windowClass[0].toUpperCase() : ""
			color: "#ffffff"
			font.pixelSize: 14
			font.weight: Font.Bold
		}
	}

	// Window title with fade effect for overflow
	Item {
		Layout.fillWidth: true
		Layout.preferredHeight: 28
		visible: root.windowTitle !== ""

		clip: true

		Text {
			id: titleText
			anchors.verticalCenter: parent.verticalCenter
			text: root.windowTitle
			color: "#e0e0e0"
			font.pixelSize: 13
			font.weight: Font.Medium
			elide: Text.ElideRight
			width: parent.width

			// Smooth text update
			Behavior on text {
				SequentialAnimation {
					NumberAnimation { target: titleText; property: "opacity"; to: 0.5; duration: 100 }
					PropertyAction { target: titleText; property: "text" }
					NumberAnimation { target: titleText; property: "opacity"; to: 1.0; duration: 100 }
				}
			}
		}

		// Fade effect on right edge
		Rectangle {
			anchors.right: parent.right
			anchors.top: parent.top
			anchors.bottom: parent.bottom
			width: 40
			gradient: Gradient {
				orientation: Gradient.Horizontal
				GradientStop { position: 0.0; color: "transparent" }
				GradientStop { position: 1.0; color: "#000000" }
			}
		}
	}

	// Empty state indicator
	Text {
		visible: root.windowTitle === ""
		text: "Desktop"
		color: "#666666"
		font.pixelSize: 12
		font.italic: true
	}
}
