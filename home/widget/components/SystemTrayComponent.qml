import Quickshell
import Quickshell.Services.SystemTray
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

RowLayout {
	spacing: 4

	Repeater {
		model: SystemTray.items

		Rectangle {
			required property SystemTrayItem modelData

			Layout.preferredWidth: 32
			Layout.preferredHeight: 32
			radius: 6
			color: trayMouseArea.containsMouse ? "#f5f5f5" : "#ffffff"
			border.color: trayMouseArea.containsMouse ? "#000000" : "#e0e0e0"
			border.width: 2

			Behavior on color {
				ColorAnimation { duration: 150 }
			}

			Behavior on border.color {
				ColorAnimation { duration: 150 }
			}

			Image {
				id: trayIcon
				anchors.centerIn: parent
				width: 20
				height: 20
				source: modelData.icon?.toString() ?? ""
				smooth: true
				mipmap: true

				// Fallback to text if no icon
				visible: source.toString() !== ""
			}

			Text {
				anchors.centerIn: parent
				text: trayIcon.visible ? "" : (modelData.title?.substring(0, 1) ?? "?")
				color: "#000000"
				font.pixelSize: 13
				font.weight: Font.Bold
			}

			MouseArea {
				id: trayMouseArea
				anchors.fill: parent
				hoverEnabled: true
				acceptedButtons: Qt.LeftButton | Qt.RightButton
				cursorShape: Qt.PointingHandCursor

				onClicked: (mouse) => {
					if (mouse.button === Qt.LeftButton) {
						modelData.activate()
					} else if (mouse.button === Qt.RightButton) {
						modelData.menu?.open()
					}
				}

				// Tooltip
				ToolTip {
					visible: parent.containsMouse
					text: modelData.tooltip?.title ?? modelData.title ?? ""
					delay: 500

					background: Rectangle {
						color: "#ffffff"
						border.color: "#e0e0e0"
						border.width: 1
						radius: 4
					}

					contentItem: Text {
						text: parent.text
						color: "#000000"
						font.pixelSize: 11
					}
				}
			}
		}
	}
}
