import Quickshell
import Quickshell.Services.Pipewire
import QtQuick
import QtQuick.Layouts

Item {
	implicitWidth: micLayout.implicitWidth
	implicitHeight: micLayout.implicitHeight

	property var defaultSource: Pipewire.defaultAudioSource
	property real volume: defaultSource?.audio.volume ?? 0.0
	property bool muted: defaultSource?.audio.muted ?? true

	RowLayout {
		id: micLayout
		spacing: 6

		Rectangle {
			Layout.preferredWidth: 32
			Layout.preferredHeight: 32
			radius: 6
			color: micMouseArea.containsMouse ? "#f5f5f5" : "#ffffff"
			border.color: micMouseArea.containsMouse ? "#000000" : "#e0e0e0"
			border.width: 2

			Behavior on color {
				ColorAnimation { duration: 150 }
			}

			Behavior on border.color {
				ColorAnimation { duration: 150 }
			}

			Text {
				anchors.centerIn: parent
				text: muted ? "mic_off" : "mic"
				color: muted ? "#ff4444" : "#000000"
				font.pixelSize: 18
				font.family: "Material Symbols Rounded"
				font.weight: Font.Bold
			}

			MouseArea {
				id: micMouseArea
				anchors.fill: parent
				hoverEnabled: true
				cursorShape: Qt.PointingHandCursor

				onClicked: {
					micPopup.visible = !micPopup.visible
				}
			}
		}
	}

	// Microphone control popup
	Rectangle {
		id: micPopup
		visible: false
		width: 220
		height: 280
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
			spacing: 10

			// Header
			Text {
				text: "Microphone"
				color: "#000000"
				font.pixelSize: 14
				font.weight: Font.Bold
				Layout.alignment: Qt.AlignHCenter
			}

			Rectangle {
				Layout.fillWidth: true
				Layout.preferredHeight: 1
				color: "#e0e0e0"
			}

			// Mute toggle
			Rectangle {
				Layout.fillWidth: true
				Layout.preferredHeight: 40
				radius: 6
				color: muteToggleArea.containsMouse ? "#f5f5f5" : "#ffffff"
				border.color: muted ? "#ff4444" : "#4CAF50"
				border.width: 2

				RowLayout {
					anchors.fill: parent
					anchors.margins: 8
					spacing: 8

					Text {
						text: muted ? "mic_off" : "mic"
						color: muted ? "#ff4444" : "#4CAF50"
						font.pixelSize: 20
						font.family: "Material Symbols Rounded"
						font.weight: Font.Bold
					}

					Text {
						text: muted ? "Muted" : "Active"
						color: "#000000"
						font.pixelSize: 13
						font.weight: Font.DemiBold
						Layout.fillWidth: true
					}
				}

				MouseArea {
					id: muteToggleArea
					anchors.fill: parent
					hoverEnabled: true
					cursorShape: Qt.PointingHandCursor
					onClicked: {
						if (defaultSource) {
							defaultSource.audio.muted = !defaultSource.audio.muted
						}
					}
				}
			}

			// Volume control
			Text {
				text: "Input Volume"
				color: "#666666"
				font.pixelSize: 11
				font.weight: Font.Medium
			}

			RowLayout {
				Layout.fillWidth: true
				spacing: 8

				Rectangle {
					Layout.fillWidth: true
					Layout.preferredHeight: 36
					radius: 6
					color: "#f5f5f5"
					border.color: "#e0e0e0"
					border.width: 1

					// Volume fill indicator
					Rectangle {
						anchors.left: parent.left
						anchors.verticalCenter: parent.verticalCenter
						anchors.margins: 4
						width: (parent.width - 8) * volume
						height: parent.height - 8
						radius: 4
						color: muted ? "#cccccc" : "#000000"

						Behavior on width {
							NumberAnimation { duration: 100 }
						}
					}

					MouseArea {
						anchors.fill: parent
						hoverEnabled: true

						onPositionChanged: (mouse) => {
							if (pressed && defaultSource) {
								const newVolume = mouse.x / width
								defaultSource.audio.volume = Math.max(0, Math.min(1, newVolume))
							}
						}

						onWheel: (wheel) => {
							if (defaultSource) {
								const delta = wheel.angleDelta.y > 0 ? 0.05 : -0.05
								defaultSource.audio.volume = Math.max(0, Math.min(1, defaultSource.audio.volume + delta))
							}
						}
					}
				}

				Text {
					text: Math.round(volume * 100) + "%"
					color: "#000000"
					font.pixelSize: 12
					font.weight: Font.Bold
					Layout.preferredWidth: 40
				}
			}

			// Input devices list
			Text {
				text: "Input Devices"
				color: "#666666"
				font.pixelSize: 11
				font.weight: Font.Medium
				Layout.topMargin: 4
			}

			ListView {
				Layout.fillWidth: true
				Layout.fillHeight: true
				clip: true
				spacing: 4

				model: Pipewire.audioSources

				delegate: Rectangle {
					width: ListView.view.width
					height: 36
					radius: 6
					color: deviceMouseArea.containsMouse ? "#f5f5f5" : "#ffffff"
					border.color: modelData === defaultSource ? "#000000" : "#e0e0e0"
					border.width: modelData === defaultSource ? 2 : 1

					RowLayout {
						anchors.fill: parent
						anchors.margins: 8
						spacing: 8

						Text {
							text: modelData === defaultSource ? "radio_button_checked" : "radio_button_unchecked"
							color: "#000000"
							font.pixelSize: 16
							font.family: "Material Symbols Rounded"
						}

						Text {
							text: {
								const desc = modelData.description ?? "Unknown Device"
								return desc.length > 25 ? desc.substring(0, 25) + "..." : desc
							}
							color: "#000000"
							font.pixelSize: 11
							font.weight: modelData === defaultSource ? Font.Bold : Font.Normal
							Layout.fillWidth: true
							elide: Text.ElideRight
						}
					}

					MouseArea {
						id: deviceMouseArea
						anchors.fill: parent
						hoverEnabled: true
						cursorShape: Qt.PointingHandCursor
						onClicked: {
							Pipewire.defaultAudioSource = modelData
						}
					}
				}
			}
		}
	}

	// Auto-close popup after 5 seconds
	Timer {
		interval: 5000
		running: micPopup.visible
		onTriggered: micPopup.visible = false
	}
}
