import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Layouts

RowLayout {
	spacing: 6

	property int batteryPercent: 0
	property bool batteryCharging: false
	property string batteryIcon: "󰂎"
	property string batteryColor: "#a9b1d6"

	// Separator (only shown when battery is visible)
	Rectangle {
		Layout.preferredWidth: 1
		Layout.preferredHeight: 24
		color: "#414868"
		opacity: 0.5
		visible: parent.visible
	}

	Rectangle {
		Layout.preferredWidth: 28
		Layout.preferredHeight: 28
		radius: 14
		color: "#414868"

		Text {
			anchors.centerIn: parent
			text: batteryIcon
			color: batteryColor
			font.pixelSize: 16
			font.family: "Material Design Icons"
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
			batteryIcon = "󰂄"
			batteryColor = "#9ece6a"
		} else if (batteryPercent <= 10) {
			batteryIcon = "󰂎"
			batteryColor = "#f7768e"
		} else if (batteryPercent <= 20) {
			batteryIcon = "󰁺"
			batteryColor = "#e0af68"
		} else if (batteryPercent <= 30) {
			batteryIcon = "󰁻"
			batteryColor = "#e0af68"
		} else if (batteryPercent <= 50) {
			batteryIcon = "󰁽"
			batteryColor = "#a9b1d6"
		} else if (batteryPercent <= 70) {
			batteryIcon = "󰁿"
			batteryColor = "#a9b1d6"
		} else if (batteryPercent <= 90) {
			batteryIcon = "󰂁"
			batteryColor = "#9ece6a"
		} else {
			batteryIcon = "󰁹"
			batteryColor = "#9ece6a"
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
