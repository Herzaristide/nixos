import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Layouts

RowLayout {
	spacing: 12

	// CPU usage
	RowLayout {
		spacing: 6

		Rectangle {
			Layout.preferredWidth: 28
			Layout.preferredHeight: 28
			radius: 3
			color: "#0d0d0d"
			border.color: "#3a3a3a"
			border.width: 2

			Text {
				anchors.centerIn: parent
				text: "memory"
				color: "#cccccc"
				font.pixelSize: 13
				font.family: "Material Symbols Rounded"
			}
		}

		Text {
			id: cpuText
			text: "0%"
			color: "#e0e0e0"
			font.pixelSize: 12
			font.weight: Font.Medium
		}

		Process {
			id: cpuProcess
			command: ["sh", "-c", "top -bn2 -d0.5 | grep 'Cpu(s)' | tail -1 | awk '{print $2}' | cut -d'%' -f1"]
			running: true

			stdout: SplitParser {
				onRead: data => {
					const cpu = parseFloat(data.trim())
					if (!isNaN(cpu)) {
						cpuText.text = cpu.toFixed(0) + "%"
						cpuText.color = cpu > 80 ? "#ff5555" : (cpu > 50 ? "#ffaa55" : "#e0e0e0")
					}
				}
			}
		}

		Timer {
			interval: 2000
			running: true
			repeat: true
			onTriggered: cpuProcess.running = true
		}
	}

	// RAM usage
	RowLayout {
		spacing: 6

		Rectangle {
			Layout.preferredWidth: 28
			Layout.preferredHeight: 28
			radius: 14
			color: "#414868"

			Text {
				anchors.centerIn: parent
				text: "󰍛"
				color: "#bb9af7"
				font.pixelSize: 14
				font.family: "Material Design Icons"
			}
		}

		Text {
			id: ramText
			text: "0 GB"
			color: "#a9b1d6"
			font.pixelSize: 12
			font.weight: Font.Medium
		}

		Process {
			id: ramProcess
			command: ["sh", "-c", "free -g | awk '/^Mem:/ {print $3}'"]
			running: true

			stdout: SplitParser {
				onRead: data => {
					const ram = parseInt(data.trim())
					if (!isNaN(ram)) {
						ramText.text = ram + " GB"
					}
				}
			}
		}

		Timer {
			interval: 3000
			running: true
			repeat: true
			onTriggered: ramProcess.running = true
		}
	}
}
