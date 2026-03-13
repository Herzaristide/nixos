import QtQuick
import QtQuick.Layouts

RowLayout {
	spacing: 8

	// Date
	Text {
		text: Qt.formatDateTime(new Date(), "ddd dd MMM")
		color: "#999999"
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
		radius: 3
		color: "#1a1a1a"
		border.color: "#ffffff"
		border.width: 2

		Text {
			id: timeText
			anchors.centerIn: parent
			text: Qt.formatDateTime(new Date(), "HH:mm")
			color: "#ffffff"
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

			NumberAnimation { to: 1.03; duration: 200; easing.type: Easing.OutCubic }
			NumberAnimation { to: 1.0; duration: 200; easing.type: Easing.InCubic }
			PauseAnimation { duration: 58600 }
		}
	}
}
