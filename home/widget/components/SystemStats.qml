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
			Layout.preferredWidth: 32
			Layout.preferredHeight: 32
			radius: 6
			color: "#ffffff"
			border.color: "#e0e0e0"
			border.width: 2

			Text {
				anchors.centerIn: parent
				text: "memory"
				color: "#000000"
				font.pixelSize: 16
				font.family: "Material Symbols Rounded"
				font.weight: Font.Bold
			}
		}

		Text {
			id: cpuText
			text: "0%"
			color: "#000000"
			font.pixelSize: 13
			font.weight: Font.DemiBold
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
						cpuText.color = cpu > 80 ? "#ff4444" : (cpu > 50 ? "#ff9944" : "#000000")
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
			Layout.preferredWidth: 32
			Layout.preferredHeight: 32
			radius: 6
			color: "#ffffff"
			border.color: "#e0e0e0"
			border.width: 2

			Text {
				anchors.centerIn: parent
				text: "storage"
				color: "#000000"
				font.pixelSize: 16
				font.family: "Material Symbols Rounded"
				font.weight: Font.Bold
			}
		}

		Text {
			id: ramText
			text: "0 GB"
			color: "#000000"
			font.pixelSize: 13
			font.weight: Font.DemiBold
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
