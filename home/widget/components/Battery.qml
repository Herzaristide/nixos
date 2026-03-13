import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Layouts

RowLayout {
	spacing: 6

	property int batteryPercent: 0
	property bool batteryCharging: false
	property string batteryIcon: "battery_0_bar"
	property string batteryColor: "#e0e0e0"

	// Separator (only shown when battery is visible)
	Rectangle {
		Layout.preferredWidth: 1
		Layout.preferredHeight: 24
		color: "#3a3a3a"
		opacity: 0.8
		visible: parent.visible
	}

	Rectangle {
		Layout.preferredWidth: 28
		Layout.preferredHeight: 28
		radius: 3
		color: "#0d0d0d"
		border.color: "#3a3a3a"
		border.width: 2

		Text {
			anchors.centerIn: parent
			text: batteryIcon
			color: batteryColor
			font.pixelSize: 16
			font.family: "Material Symbols Rounded"
		}
	}

	Text {
		text: batteryPercent + "%"
		color: batteryColor
		font.pixelSize: 12
		font.weight: Font.Medium
	}

	Process {
		id: batteryProcess
		command: ["sh", "-c", "cat /sys/class/power_supply/BAT*/capacity 2>/dev/null || echo '100'"]
		running: true

		stdout: SplitParser {
			onRead: data => {
				batteryPercent = parseInt(data.trim())
				updateBatteryIcon()
			}
		}
	}

	Process {
		id: batteryStatusProcess
		command: ["sh", "-c", "cat /sys/class/power_supply/BAT*/status 2>/dev/null || echo 'Unknown'"]
		running: true

		stdout: SplitParser {
			onRead: data => {
				batteryCharging = data.trim() === "Charging"
				updateBatteryIcon()
			}
		}
	}

	function updateBatteryIcon() {
		if (batteryCharging) {
			batteryIcon = "battery_charging_full"
			batteryColor = "#aaffaa"
		} else if (batteryPercent <= 10) {
			batteryIcon = "battery_0_bar"
			batteryColor = "#ff5555"
		} else if (batteryPercent <= 20) {
			batteryIcon = "battery_1_bar"
			batteryColor = "#ffaa55"
		} else if (batteryPercent <= 30) {
			batteryIcon = "battery_2_bar"
			batteryColor = "#ffaa55"
		} else if (batteryPercent <= 50) {
			batteryIcon = "battery_3_bar"
			batteryColor = "#e0e0e0"
		} else if (batteryPercent <= 70) {
			batteryIcon = "battery_4_bar"
			batteryColor = "#e0e0e0"
		} else if (batteryPercent <= 90) {
			batteryIcon = "battery_5_bar"
			batteryColor = "#e0e0e0"
		} else {
			batteryIcon = "battery_full"
			batteryColor = "#e0e0e0"
		}
	}

	Timer {
		interval: 10000
		running: true
		repeat: true
		onTriggered: {
			batteryProcess.running = true
			batteryStatusProcess.running = true
		}
	}

	Component.onCompleted: {
		batteryProcess.running = true
		batteryStatusProcess.running = true
	}
}
