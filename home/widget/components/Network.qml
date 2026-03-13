import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Layouts

RowLayout {
	spacing: 6

	property string networkStatus: "disconnected"
	property string networkIcon: "wifi_off"
	property string networkColor: "#666666"

	Rectangle {
		Layout.preferredWidth: 28
		Layout.preferredHeight: 28
		radius: 3
		color: "#0d0d0d"
		border.color: "#3a3a3a"
		border.width: 2

		Text {
			anchors.centerIn: parent
			text: networkIcon
			color: networkColor
			font.pixelSize: 16
			font.family: "Material Symbols Rounded"
		}
	}

	Text {
		id: networkText
		text: networkStatus
		color: "#e0e0e0"
		font.pixelSize: 12
		font.weight: Font.Medium
		visible: networkStatus !== "disconnected"
	}

	Process {
		id: networkProcess
		command: ["sh", "-c", "nmcli -t -f TYPE,STATE device | grep -E 'wifi|ethernet' | head -1"]
		running: true

		stdout: SplitParser {
			onRead: data => {
				const parts = data.trim().split(':')
				if (parts.length >= 2) {
					const type = parts[0]
					const state = parts[1]

					if (state === 'connected') {
						if (type === 'wifi') {
							networkIcon = "wifi"
							networkColor = "#e0e0e0"
							networkStatus = "WiFi"
						} else if (type === 'ethernet') {
							networkIcon = "lan"
							networkColor = "#e0e0e0"
							networkStatus = "Ethernet"
						}
					} else {
						networkIcon = "wifi_off"
						networkColor = "#ff5555"
						networkStatus = "disconnected"
					}
				}
			}
		}
	}

	Timer {
		interval: 5000
		running: true
		repeat: true
		onTriggered: networkProcess.running = true
	}

	Component.onCompleted: networkProcess.running = true
}
