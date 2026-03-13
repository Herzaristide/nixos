import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Layouts

RowLayout {
	spacing: 6

	property string networkStatus: "disconnected"
	property string networkIcon: "󰖪"
	property string networkColor: "#565f89"

	Rectangle {
		Layout.preferredWidth: 28
		Layout.preferredHeight: 28
		radius: 14
		color: "#414868"

		Text {
			anchors.centerIn: parent
			text: networkIcon
			color: networkColor
			font.pixelSize: 16
			font.family: "Material Design Icons"
		}
	}

	Text {
		id: networkText
		text: networkStatus
		color: "#a9b1d6"
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
							networkIcon = "󰖩"
							networkColor = "#9ece6a"
							networkStatus = "WiFi"
						} else if (type === 'ethernet') {
							networkIcon = "󰈀"
							networkColor = "#7aa2f7"
							networkStatus = "Ethernet"
						}
					} else {
						networkIcon = "󰖪"
						networkColor = "#f7768e"
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
