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
			radius: 14
			color: "#414868"

			Text {
				anchors.centerIn: parent
				text: "󰻠"
				color: "#7aa2f7"
				font.pixelSize: 14
				font.family: "Material Design Icons"
			}
		}

		Text {
			id: cpuText
			text: "0%"
			color: "#a9b1d6"
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
						cpuText.color = cpu > 80 ? "#f7768e" : (cpu > 50 ? "#e0af68" : "#a9b1d6")
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
