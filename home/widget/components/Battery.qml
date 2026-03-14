import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Layouts

RowLayout {
	spacing: 6

	property int batteryPercent: 0
	property bool batteryCharging: false
	property string batteryIcon: "battery_0_bar"
	property string batteryColor: "#000000"

	// Separator (only shown when battery is visible)
	Rectangle {
		Layout.preferredWidth: 1
		Layout.preferredHeight: 24
		color: "#e0e0e0"
		opacity: 0.8
		visible: parent.visible
	}

	Rectangle {
		Layout.preferredWidth: 32
		Layout.preferredHeight: 32
		radius: 6
		color: "#ffffff"
		border.color: batteryCharging ? "#4CAF50" : "#e0e0e0"
		border.width: 2

		Behavior on border.color {
			ColorAnimation { duration: 300 }
		}

		Text {
			anchors.centerIn: parent
			text: batteryIcon
			color: batteryColor
			font.pixelSize: 18
			font.family: "Material Symbols Rounded"
			font.weight: Font.Bold
		}

		// Charging animation
		SequentialAnimation on opacity {
			running: batteryCharging
			loops: Animation.Infinite
			NumberAnimation { to: 0.6; duration: 800; easing.type: Easing.InOutSine }
			NumberAnimation { to: 1.0; duration: 800; easing.type: Easing.InOutSine }
		}
	}

	Text {
		text: batteryPercent + "%"
		color: batteryColor
		font.pixelSize: 13
		font.weight: Font.DemiBold
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
			batteryColor = "#4CAF50"
		} else if (batteryPercent <= 10) {
			batteryIcon = "battery_0_bar"
			batteryColor = "#ff4444"
		} else if (batteryPercent <= 20) {
			batteryIcon = "battery_1_bar"
			batteryColor = "#ff9944"
		} else if (batteryPercent <= 30) {
			batteryIcon = "battery_2_bar"
			batteryColor = "#ff9944"
		} else if (batteryPercent <= 50) {
			batteryIcon = "battery_3_bar"
			batteryColor = "#000000"
		} else if (batteryPercent <= 70) {
			batteryIcon = "battery_4_bar"
			batteryColor = "#000000"
		} else if (batteryPercent <= 90) {
			batteryIcon = "battery_5_bar"
			batteryColor = "#000000"
		} else {
			batteryIcon = "battery_full"
			batteryColor = "#000000"
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
