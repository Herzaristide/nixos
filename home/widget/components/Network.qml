import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Layouts

Item {
	implicitWidth: networkLayout.implicitWidth
	implicitHeight: networkLayout.implicitHeight

	property string networkStatus: "disconnected"
	property string networkIcon: "wifi_off"
	property string networkColor: "#999999"
	property string currentSSID: ""
	property var wifiNetworks: []

	RowLayout {
		id: networkLayout
		spacing: 6

		Rectangle {
			Layout.preferredWidth: 32
			Layout.preferredHeight: 32
			radius: 6
			color: networkMouseArea.containsMouse ? "#f5f5f5" : "#ffffff"
			border.color: networkMouseArea.containsMouse ? "#000000" : "#e0e0e0"
			border.width: 2

			Behavior on color {
				ColorAnimation { duration: 150 }
			}

			Behavior on border.color {
				ColorAnimation { duration: 150 }
			}

			Text {
				anchors.centerIn: parent
				text: networkIcon
				color: networkColor
				font.pixelSize: 18
				font.family: "Material Symbols Rounded"
				font.weight: Font.Bold
			}

			MouseArea {
				id: networkMouseArea
				anchors.fill: parent
				hoverEnabled: true
				cursorShape: Qt.PointingHandCursor

				onClicked: {
					if (networkStatus === "WiFi") {
						wifiPopup.visible = !wifiPopup.visible
						if (wifiPopup.visible) {
							scanWifi()
						}
					}
				}
			}
		}

		Text {
			text: networkStatus === "WiFi" ? currentSSID : networkStatus
			color: "#000000"
			font.pixelSize: 13
			font.weight: Font.DemiBold
			visible: networkStatus !== "disconnected"
		}
	}

	// WiFi selector popup
	Rectangle {
		id: wifiPopup
		visible: false
		width: 300
		height: 400
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

			// Header with refresh button
			RowLayout {
				Layout.fillWidth: true
				spacing: 8

				Text {
					text: "WiFi Networks"
					color: "#000000"
					font.pixelSize: 14
					font.weight: Font.Bold
					Layout.fillWidth: true
				}

				Rectangle {
					Layout.preferredWidth: 32
					Layout.preferredHeight: 32
					radius: 6
					color: refreshMouseArea.containsMouse ? "#f5f5f5" : "#ffffff"
					border.color: "#e0e0e0"
					border.width: 1

					Text {
						anchors.centerIn: parent
						text: "refresh"
						color: "#000000"
						font.pixelSize: 18
						font.family: "Material Symbols Rounded"
						font.weight: Font.Bold

						RotationAnimation on rotation {
							id: refreshAnimation
							running: false
							from: 0
							to: 360
							duration: 500
							loops: 1
						}
					}

					MouseArea {
						id: refreshMouseArea
						anchors.fill: parent
						hoverEnabled: true
						cursorShape: Qt.PointingHandCursor
						onClicked: {
							refreshAnimation.restart()
							scanWifi()
						}
					}
				}
			}

			Rectangle {
				Layout.fillWidth: true
				Layout.preferredHeight: 1
				color: "#e0e0e0"
			}

			// Current connection
			Rectangle {
				Layout.fillWidth: true
				Layout.preferredHeight: 50
				radius: 6
				color: "#f5f5f5"
				border.color: "#4CAF50"
				border.width: 2
				visible: currentSSID !== ""

				RowLayout {
					anchors.fill: parent
					anchors.margins: 10
					spacing: 10

					Text {
						text: "wifi"
						color: "#4CAF50"
						font.pixelSize: 20
						font.family: "Material Symbols Rounded"
						font.weight: Font.Bold
					}

					ColumnLayout {
						Layout.fillWidth: true
						spacing: 2

						Text {
							text: currentSSID
							color: "#000000"
							font.pixelSize: 13
							font.weight: Font.Bold
						}

						Text {
							text: "Connected"
							color: "#4CAF50"
							font.pixelSize: 10
							font.weight: Font.Medium
						}
					}

					Text {
						text: "check_circle"
						color: "#4CAF50"
						font.pixelSize: 20
						font.family: "Material Symbols Rounded"
					}
				}
			}

			// Available networks list
			Text {
				text: "Available Networks"
				color: "#666666"
				font.pixelSize: 11
				font.weight: Font.Medium
				visible: wifiNetworks.length > 0
			}

			ListView {
				Layout.fillWidth: true
				Layout.fillHeight: true
				clip: true
				spacing: 4

				model: wifiNetworks

				delegate: Rectangle {
					width: ListView.view.width
					height: 44
					radius: 6
					color: wifiMouseArea.containsMouse ? "#f5f5f5" : "#ffffff"
					border.color: modelData.active ? "#4CAF50" : "#e0e0e0"
					border.width: modelData.active ? 2 : 1

					RowLayout {
						anchors.fill: parent
						anchors.margins: 10
						spacing: 10

						Text {
							text: {
								const signal = parseInt(modelData.signal)
								if (signal > 75) return "signal_wifi_4_bar"
								if (signal > 50) return "network_wifi_3_bar"
								if (signal > 25) return "network_wifi_2_bar"
								return "network_wifi_1_bar"
							}
							color: "#000000"
							font.pixelSize: 18
							font.family: "Material Symbols Rounded"
						}

						ColumnLayout {
							Layout.fillWidth: true
							spacing: 2

							Text {
								text: modelData.ssid
								color: "#000000"
								font.pixelSize: 12
								font.weight: modelData.active ? Font.Bold : Font.Normal
								elide: Text.ElideRight
							}

							Text {
								text: modelData.security
								color: "#666666"
								font.pixelSize: 9
								font.weight: Font.Medium
							}
						}

						Text {
							text: modelData.signal + "%"
							color: "#666666"
							font.pixelSize: 10
							font.weight: Font.Medium
						}

						Text {
							text: modelData.secured ? "lock" : ""
							color: "#666666"
							font.pixelSize: 16
							font.family: "Material Symbols Rounded"
							visible: modelData.secured
						}
					}

					MouseArea {
						id: wifiMouseArea
						anchors.fill: parent
						hoverEnabled: true
						cursorShape: Qt.PointingHandCursor
						onClicked: {
							// Connect to network (would need nmcli or similar)
							console.log("Connecting to:", modelData.ssid)
						}
					}
				}
			}

			// Status text when no networks
			Text {
				text: "Scanning for networks..."
				color: "#666666"
				font.pixelSize: 12
				font.weight: Font.Medium
				Layout.alignment: Qt.AlignCenter
				Layout.fillHeight: true
				visible: wifiNetworks.length === 0
			}
		}
	}

	// Network status check
	Process {
		id: networkProcess
		command: ["sh", "-c", "nmcli -t -f TYPE,STATE,DEVICE device | grep -E 'wifi|ethernet' | head -1"]
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
							networkColor = "#000000"
							networkStatus = "WiFi"
							getCurrentSSID()
						} else if (type === 'ethernet') {
							networkIcon = "lan"
							networkColor = "#000000"
							networkStatus = "Ethernet"
						}
					} else {
						networkIcon = "wifi_off"
						networkColor = "#ff4444"
						networkStatus = "disconnected"
					}
				}
			}
		}
	}

	// Get current SSID
	Process {
		id: ssidProcess
		command: ["sh", "-c", "nmcli -t -f active,ssid dev wifi | grep '^yes' | cut -d: -f2"]
		running: false

		stdout: SplitParser {
			onRead: data => {
				currentSSID = data.trim()
			}
		}
	}

	function getCurrentSSID() {
		ssidProcess.running = true
	}

	// Scan WiFi networks
	Process {
		id: wifiScanProcess
		command: ["sh", "-c", "nmcli -t -f ACTIVE,SSID,SIGNAL,SECURITY dev wifi list | head -20"]
		running: false

		stdout: SplitParser {
			onRead: data => {
				const lines = data.trim().split('\n')
				const networks = []

				for (const line of lines) {
					const parts = line.split(':')
					if (parts.length >= 3) {
						networks.push({
							active: parts[0] === 'yes',
							ssid: parts[1] || 'Hidden Network',
							signal: parts[2] || '0',
							security: parts[3] || 'Open',
							secured: parts[3] && parts[3] !== '--' && parts[3] !== ''
						})
					}
				}

				wifiNetworks = networks
			}
		}
	}

	function scanWifi() {
		wifiScanProcess.running = true
	}

	// Update network status periodically
	Timer {
		interval: 5000
		running: true
		repeat: true
		onTriggered: networkProcess.running = true
	}

	// Auto-close popup after 10 seconds
	Timer {
		interval: 10000
		running: wifiPopup.visible
		onTriggered: wifiPopup.visible = false
	}

	Component.onCompleted: {
		networkProcess.running = true
	}
}
