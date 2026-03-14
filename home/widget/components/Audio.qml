import Quickshell
import Quickshell.Services.Pipewire
import QtQuick
import QtQuick.Layouts

Item {
	implicitWidth: audioLayout.implicitWidth
	implicitHeight: audioLayout.implicitHeight

	property var defaultSink: Pipewire.defaultAudioSink
	property real volume: defaultSink?.audio.volume ?? 0.0
	property bool muted: defaultSink?.audio.muted ?? false

	RowLayout {
		id: audioLayout
		spacing: 6

		Rectangle {
			Layout.preferredWidth: 32
			Layout.preferredHeight: 32
			radius: 6
			color: audioMouseArea.containsMouse ? "#f5f5f5" : "#ffffff"
			border.color: audioMouseArea.containsMouse ? "#000000" : "#e0e0e0"
			border.width: 2

			Behavior on color {
				ColorAnimation { duration: 150 }
			}

			Behavior on border.color {
				ColorAnimation { duration: 150 }
			}

			Text {
				anchors.centerIn: parent
				text: {
					if (muted || volume === 0) return "volume_off"
					if (volume < 0.33) return "volume_mute"
					if (volume < 0.66) return "volume_down"
					return "volume_up"
				}
				color: muted ? "#999999" : "#000000"
				font.pixelSize: 18
				font.family: "Material Symbols Rounded"
				font.weight: Font.Bold
			}

			MouseArea {
				id: audioMouseArea
				anchors.fill: parent
				hoverEnabled: true
				cursorShape: Qt.PointingHandCursor

				onClicked: {
					volumePopup.visible = !volumePopup.visible
				}
			}
		}

		Text {
			text: Math.round(volume * 100) + "%"
			color: muted ? "#999999" : "#000000"
			font.pixelSize: 13
			font.weight: Font.DemiBold
		}
	}

	// Volume control popup
	Rectangle {
		id: volumePopup
		visible: false
		width: 60
		height: 200
		radius: 8
		color: "#ffffff"
		border.color: "#e0e0e0"
		border.width: 1
		opacity: 0.98

		anchors.bottom: parent.top
		anchors.bottomMargin: 8
		anchors.horizontalCenter: parent.horizontalCenter

		layer.enabled: true
		layer.effect: ShaderEffect {
			property real shadowOpacity: 0.15
		}

		ColumnLayout {
			anchors.fill: parent
			anchors.margins: 12
			spacing: 8

			// Mute toggle button
			Rectangle {
				Layout.preferredWidth: 36
				Layout.preferredHeight: 36
				Layout.alignment: Qt.AlignHCenter
				radius: 6
				color: muteMouseArea.containsMouse ? "#f5f5f5" : "#ffffff"
				border.color: muted ? "#ff4444" : "#e0e0e0"
				border.width: 2

				Text {
					anchors.centerIn: parent
					text: muted ? "volume_off" : "volume_up"
					color: muted ? "#ff4444" : "#000000"
					font.pixelSize: 20
					font.family: "Material Symbols Rounded"
					font.weight: Font.Bold
				}

				MouseArea {
					id: muteMouseArea
					anchors.fill: parent
					hoverEnabled: true
					cursorShape: Qt.PointingHandCursor
					onClicked: {
						if (defaultSink) {
							defaultSink.audio.muted = !defaultSink.audio.muted
						}
					}
				}
			}

			// Volume slider
			Rectangle {
				Layout.fillHeight: true
				Layout.preferredWidth: 36
				Layout.alignment: Qt.AlignHCenter
				radius: 6
				color: "#f5f5f5"
				border.color: "#e0e0e0"
				border.width: 1

				// Volume fill indicator
				Rectangle {
					anchors.bottom: parent.bottom
					anchors.horizontalCenter: parent.horizontalCenter
					width: parent.width - 8
					height: parent.height * volume
					radius: 4
					color: muted ? "#cccccc" : "#000000"

					Behavior on height {
						NumberAnimation { duration: 100 }
					}
				}

				MouseArea {
					anchors.fill: parent
					hoverEnabled: true

					onPositionChanged: (mouse) => {
						if (pressed && defaultSink) {
							const newVolume = 1 - (mouse.y / height)
							defaultSink.audio.volume = Math.max(0, Math.min(1, newVolume))
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

			// Volume percentage text
			Text {
				Layout.alignment: Qt.AlignHCenter
				text: Math.round(volume * 100) + "%"
				color: "#000000"
				font.pixelSize: 12
				font.weight: Font.Bold
			}
		}

		// Close popup when clicking outside
		MouseArea {
			anchors.fill: parent
			propagateComposedEvents: true
			onPressed: (mouse) => {
				mouse.accepted = false
			}
		}
	}

	// Auto-close timer for volume popup
	Timer {
		id: autoCloseTimer
		interval: 5000
		onTriggered: volumePopup.visible = false
	}

	Connections {
		target: volumePopup
		function onVisibleChanged() {
			if (volumePopup.visible) {
				autoCloseTimer.restart()
			} else {
				autoCloseTimer.stop()
			}
		}
	}
}
