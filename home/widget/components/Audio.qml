import Quickshell
import Quickshell.Services.Pipewire
import QtQuick
import QtQuick.Layouts

RowLayout {
	spacing: 6

	property var defaultSink: Pipewire.defaultAudioSink
	property real volume: defaultSink?.audio.volume ?? 0.0
	property bool muted: defaultSink?.audio.muted ?? false

	Rectangle {
		Layout.preferredWidth: 28
		Layout.preferredHeight: 28
		radius: 14
		color: audioMouseArea.containsMouse ? "#414868" : "transparent"

		Behavior on color {
			ColorAnimation { duration: 150 }
		}

		Text {
			anchors.centerIn: parent
			text: {
				if (muted || volume === 0) return "󰖁"
				if (volume < 0.33) return "󰕿"
				if (volume < 0.66) return "󰖀"
				return "󰕾"
			}
			color: muted ? "#565f89" : "#9ece6a"
			font.pixelSize: 16
			font.family: "Material Design Icons"
		}

		MouseArea {
			id: audioMouseArea
			anchors.fill: parent
			hoverEnabled: true
			cursorShape: Qt.PointingHandCursor

			onClicked: {
				if (defaultSink) {
					defaultSink.audio.muted = !defaultSink.audio.muted
				}
			}

			onWheel: (wheel) => {
				if (defaultSink) {
					const delta = wheel.angleDelta.y > 0 ? 0.05 : -0.05
					defaultSink.audio.volume = Math.max(0, Math.min(1, defaultSink.audio.volume + delta))
				}
			}
		}
	}

	Text {
		text: Math.round(volume * 100) + "%"
		color: muted ? "#565f89" : "#a9b1d6"
		font.pixelSize: 12
		font.weight: Font.Medium
	}
}
