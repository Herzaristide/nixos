import QtQuick
import QtQuick.Layouts

RowLayout {
	spacing: 8

	// Date
	Text {
		text: Qt.formatDateTime(new Date(), "ddd dd MMM")
		color: "#565f89"
		font.pixelSize: 12
		font.weight: Font.Medium

		Timer {
			interval: 60000
			running: true
			repeat: true
			onTriggered: parent.text = Qt.formatDateTime(new Date(), "ddd dd MMM")
		}
	}

	// Time
	Rectangle {
		Layout.preferredHeight: 32
		Layout.preferredWidth: timeText.width + 20
		radius: 16

		gradient: Gradient {
			orientation: Gradient.Horizontal
			GradientStop { position: 0.0; color: "#7aa2f7" }
			GradientStop { position: 1.0; color: "#bb9af7" }
		}

		Text {
			id: timeText
			anchors.centerIn: parent
			text: Qt.formatDateTime(new Date(), "HH:mm")
			color: "#1a1b26"
			font.pixelSize: 14
			font.weight: Font.Bold

			Timer {
				interval: 1000
				running: true
				repeat: true
				onTriggered: timeText.text = Qt.formatDateTime(new Date(), "HH:mm")
			}
		}

		// Subtle pulse animation every minute
		SequentialAnimation on scale {
			running: true
			loops: Animation.Infinite

			NumberAnimation { to: 1.05; duration: 200; easing.type: Easing.OutCubic }
			NumberAnimation { to: 1.0; duration: 200; easing.type: Easing.InCubic }
			PauseAnimation { duration: 58600 }
		}
	}
}
