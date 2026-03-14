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
		Layout.preferredWidth: 32
		Layout.preferredHeight: 32
		radius: 6
		visible: root.windowTitle !== ""
		color: "#000000"
		border.color: "#000000"
		border.width: 2

		Text {
			anchors.centerIn: parent
			text: root.windowClass.length > 0 ? root.windowClass[0].toUpperCase() : ""
			color: "#ffffff"
			font.pixelSize: 15
			font.weight: Font.Bold
		}
	}

	// Window title with fade effect for overflow
	Item {
		Layout.fillWidth: true
		Layout.preferredHeight: 32
		visible: root.windowTitle !== ""

		clip: true

		Text {
			id: titleText
			anchors.verticalCenter: parent.verticalCenter
			text: root.windowTitle
			color: "#000000"
			font.pixelSize: 13
			font.weight: Font.DemiBold
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
				GradientStop { position: 1.0; color: "#ffffff" }
			}
		}
	}

	// Empty state indicator
	Text {
		visible: root.windowTitle === ""
		text: "Desktop"
		color: "#999999"
		font.pixelSize: 12
		font.italic: true
	}
}
