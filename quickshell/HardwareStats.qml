import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io

Item {
    id: hwPanel

    // ── Hardware data ────────────────────────────────────────────────────
    property string cpuName: "Chargement..."
    property int cpuUsage: 0
    property real ramTotalBytes: 0
    property real ramUsedBytes: 0
    property string gpuName: "Chargement..."
    property string gpuUsage: ""
    property var diskData: []
    property string openTarget: ""

    // ── History buffers for sparkline graphs (40 samples) ──
    readonly property int historySize: 40
    property var cpuHistory: []
    property var ramHistory: []
    property var gpuHistory: []
    property int gpuUsagePercent: 0
    property string cpuTemp: ""
    property string gpuTemp: ""

    // CPU delta state
    property real prevCpuTotal: 0
    property real prevCpuActive: 0
    property bool cpuNameLoaded: false

    // ── Helpers ──────────────────────────────────────────────────────────
    function formatGiB(bytes) {
        if (bytes <= 0) return "0 Mo";
        const gib = bytes / (1024 * 1024 * 1024);
        if (gib >= 0.95) return gib.toFixed(1) + " Go";
        return (bytes / (1024 * 1024)).toFixed(0) + " Mo";
    }

    function pushHistory(arr, value) {
        const copy = arr.slice();
        copy.push(Math.max(0, Math.min(100, Math.round(value))));
        if (copy.length > hwPanel.historySize) copy.splice(0, 1);
        return copy;
    }

    // ── Refresh timer ────────────────────────────────────────────────────
    Timer {
        id: refreshTimer
        interval: 1000
        running: hwPanel.visible
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            if (!hwPanel.cpuNameLoaded && !cpuNameProc.running)
                cpuNameProc.running = true;
            if (!cpuStatProc.running) cpuStatProc.running = true;
            if (!ramProc.running) ramProc.running = true;
            if (!gpuProc.running) gpuProc.running = true;
            if (!diskProc.running) diskProc.running = true;
            if (!tempProc.running) tempProc.running = true;
        }
    }

    onVisibleChanged: {
        if (!visible) {
            prevCpuTotal = 0;
            prevCpuActive = 0;
        }
    }

    // ── CPU model name (run once) ────────────────────────────────────────
    Process {
        id: cpuNameProc
        command: ["sh", "-c", "grep -m1 'model name' /proc/cpuinfo | cut -d: -f2 | sed 's/^ *//'"]
        stdout: StdioCollector { id: cpuNameOut }
        onRunningChanged: {
            if (!running) {
                const n = cpuNameOut.text.trim();
                if (n.length > 0) {
                    hwPanel.cpuName = n;
                    hwPanel.cpuNameLoaded = true;
                }
            }
        }
    }

    // ── CPU usage ───────────────────────────────────────────────────────
    Process {
        id: cpuStatProc
        command: ["sh", "-c", "head -1 /proc/stat"]
        stdout: StdioCollector { id: cpuStatOut }
        onRunningChanged: {
            if (!running) {
                const parts = cpuStatOut.text.trim().split(/\s+/);
                const user    = parseFloat(parts[1]) || 0;
                const nice    = parseFloat(parts[2]) || 0;
                const system  = parseFloat(parts[3]) || 0;
                const idle    = parseFloat(parts[4]) || 0;
                const iowait  = parseFloat(parts[5]) || 0;
                const irq     = parseFloat(parts[6]) || 0;
                const softirq = parseFloat(parts[7]) || 0;
                const total   = user + nice + system + idle + iowait + irq + softirq;
                const active  = total - idle - iowait;
                if (hwPanel.prevCpuTotal > 0) {
                    const dTotal  = total - hwPanel.prevCpuTotal;
                    const dActive = active - hwPanel.prevCpuActive;
                    hwPanel.cpuUsage = dTotal > 0 ? Math.round((dActive / dTotal) * 100) : 0;
                    hwPanel.cpuHistory = hwPanel.pushHistory(hwPanel.cpuHistory, hwPanel.cpuUsage);
                }
                hwPanel.prevCpuTotal  = total;
                hwPanel.prevCpuActive = active;
            }
        }
    }

    // ── RAM ──────────────────────────────────────────────────────────────
    Process {
        id: ramProc
        command: ["sh", "-c", "grep -E '^(MemTotal|MemAvailable):' /proc/meminfo"]
        stdout: StdioCollector { id: ramOut }
        onRunningChanged: {
            if (!running) {
                const lines = ramOut.text.trim().split('\n');
                let total = 0, available = 0;
                for (const line of lines) {
                    const m = line.match(/^(MemTotal|MemAvailable):\s+(\d+)/);
                    if (m) {
                        if (m[1] === "MemTotal")     total     = parseInt(m[2]) * 1024;
                        else                         available = parseInt(m[2]) * 1024;
                    }
                }
                hwPanel.ramTotalBytes = total;
                hwPanel.ramUsedBytes  = total - available;
                if (total > 0)
                    hwPanel.ramHistory = hwPanel.pushHistory(hwPanel.ramHistory,
                        (hwPanel.ramUsedBytes / total) * 100);
            }
        }
    }

    // ── GPU ──────────────────────────────────────────────────────────────
    Process {
        id: gpuProc
        command: [
            "sh", "-c",
            "out=$(nvidia-smi --query-gpu=name,utilization.gpu,memory.used,memory.total --format=csv,noheader,nounits 2>/dev/null); " +
            "if [ -n \"$out\" ]; then echo \"$out\"; " +
            "else " +
            "name=$(lspci 2>/dev/null | grep -iE 'VGA|3D|Display' | head -1 | sed 's/.*: //' | sed 's/ (.*//'); " +
            "dev=''; for h in /sys/class/hwmon/hwmon*; do [ \"$(cat $h/name 2>/dev/null)\" = 'amdgpu' ] && dev=\"$h/device\" && break; done; " +
            "if [ -n \"$dev\" ]; then " +
            "util=$(cat \"$dev/gpu_busy_percent\"); " +
            "vram_used_b=$(cat \"$dev/mem_info_vram_used\" 2>/dev/null || echo 0); " +
            "vram_total_b=$(cat \"$dev/mem_info_vram_total\" 2>/dev/null || echo 0); " +
            "vram_used=$(( vram_used_b / 1048576 )); " +
            "vram_total=$(( vram_total_b / 1048576 )); " +
            "echo \"$name,$util,$vram_used,$vram_total\"; " +
            "else echo \"$name\"; fi; fi"
        ]
        stdout: StdioCollector { id: gpuOut }
        onRunningChanged: {
            if (!running) {
                const text = gpuOut.text.trim();
                if (text.length === 0) {
                    hwPanel.gpuName  = "Non détecté";
                    hwPanel.gpuUsage = "";
                    return;
                }
                const parts = text.split(',');
                if (parts.length >= 4) {
                    hwPanel.gpuName  = parts.slice(0, parts.length - 3).join(',').trim();
                    const util       = parseInt(parts[parts.length - 3]) || 0;
                    const memUsed    = parseInt(parts[parts.length - 2]) || 0;
                    const memTotal   = parseInt(parts[parts.length - 1]) || 0;
                    hwPanel.gpuUsage        = util + "% — " + memUsed + " Mio / " + memTotal + " Mio";
                    hwPanel.gpuUsagePercent = util;
                    hwPanel.gpuHistory      = hwPanel.pushHistory(hwPanel.gpuHistory, util);
                } else {
                    hwPanel.gpuName  = text;
                    hwPanel.gpuUsage = "";
                }
            }
        }
    }

    // ── Open folder ──────────────────────────────────────────────────────
    Process {
        id: openFolderProc
        command: ["nautilus", hwPanel.openTarget]
    }

    // ── Temperatures ─────────────────────────────────────────────────────
    Process {
        id: tempProc
        command: [
            "sh", "-c",
            "cpu_t=''; " +
            "for d in /sys/class/hwmon/hwmon*; do " +
            "  n=$(cat \"$d/name\" 2>/dev/null); " +
            "  if [ \"$n\" = 'k10temp' ] || [ \"$n\" = 'coretemp' ]; then " +
            "    raw=$(cat \"$d/temp2_input\" 2>/dev/null || cat \"$d/temp1_input\" 2>/dev/null); " +
            "    [ -n \"$raw\" ] && cpu_t=$(( raw / 1000 )); break; " +
            "  fi; " +
            "done; " +
            "gpu_t=''; " +
            "for d in /sys/class/hwmon/hwmon*; do " +
            "  n=$(cat \"$d/name\" 2>/dev/null); " +
            "  if [ \"$n\" = 'amdgpu' ]; then " +
            "    raw=$(cat \"$d/temp2_input\" 2>/dev/null || cat \"$d/temp1_input\" 2>/dev/null); " +
            "    [ -n \"$raw\" ] && gpu_t=$(( raw / 1000 )); break; " +
            "  fi; " +
            "done; " +
            "[ -z \"$gpu_t\" ] && gpu_t=$(nvidia-smi --query-gpu=temperature.gpu --format=csv,noheader,nounits 2>/dev/null | head -1); " +
            "echo \"${cpu_t},${gpu_t}\""
        ]
        stdout: StdioCollector { id: tempOut }
        onRunningChanged: {
            if (!running) {
                const parts = tempOut.text.trim().split(',');
                const c = parts[0] ? parts[0].trim() : "";
                const g = parts[1] ? parts[1].trim() : "";
                hwPanel.cpuTemp = (c.length > 0 && c !== "0") ? c + "°C" : "";
                hwPanel.gpuTemp = (g.length > 0 && g !== "0") ? g + "°C" : "";
            }
        }
    }

    // ── Disques ──────────────────────────────────────────────────────────
    Process {
        id: diskProc
        command: [
            "sh", "-c",
            "df -BG --output=source,size,used,avail,target -x tmpfs -x devtmpfs -x efivarfs -x overlay 2>/dev/null | tail -n +2"
        ]
        stdout: StdioCollector { id: diskOut }
        onRunningChanged: {
            if (!running) {
                const lines = diskOut.text.trim().split('\n');
                const result = [];
                for (const line of lines) {
                    const trimmed = line.trim();
                    if (!trimmed) continue;
                    const p = trimmed.split(/\s+/);
                    if (p.length >= 5) {
                        const size = parseInt(p[1]) || 0;
                        const used = parseInt(p[2]) || 0;
                        if (size > 0) {
                            result.push({
                                source: p[0],
                                size:   size,
                                used:   used,
                                avail:  parseInt(p[3]) || 0,
                                mount:  p[4]
                            });
                        }
                    }
                }
                hwPanel.diskData = result;
            }
        }
    }

    // ── Scrollable content ──────────────────────────────────────────────
    Flickable {
        anchors.fill: parent
        contentHeight: cardColumn.implicitHeight
        clip: true
        boundsBehavior: Flickable.StopAtBounds

        ScrollBar.vertical: ScrollBar {
            policy: ScrollBar.AsNeeded
        }

        ColumnLayout {
            id: cardColumn
            width: parent.width
            spacing: 14

            // ── Header ───────────────────────────────────────────────
            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                Image {
                    source: "nixos.svg"
                    Layout.preferredWidth: 20
                    Layout.preferredHeight: 20
                    sourceSize.width: 48
                    sourceSize.height: 48
                    fillMode: Image.PreserveAspectFit
                    smooth: true
                }

                Text {
                    text: "Informations système"
                    font.family: "JetBrains Mono"
                    font.pixelSize: 14
                    font.weight: Font.Bold
                    color: "#e0e0ff"
                    Layout.fillWidth: true
                }
            }

            Rectangle { Layout.fillWidth: true; height: 1; color: Theme.accentDark }

            // ── CPU ──────────────────────────────────────────────────
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 6

                RowLayout {
                    Layout.fillWidth: true
                    Text {
                        text: "CPU"
                        font.family: "JetBrains Mono"
                        font.pixelSize: 10
                        font.weight: Font.Bold
                        font.letterSpacing: 1.5
                        color: Theme.accentMuted
                        Layout.fillWidth: true
                    }
                    Text {
                        visible: hwPanel.cpuTemp.length > 0
                        text: hwPanel.cpuTemp
                        font.family: "JetBrains Mono"
                        font.pixelSize: 11
                        color: {
                            const v = parseInt(hwPanel.cpuTemp) || 0;
                            return v > 90 ? "#cc4444" : v > 70 ? "#cc8844" : "#88ccaa";
                        }
                    }
                }

                Text {
                    text: hwPanel.cpuName
                    font.family: "JetBrains Mono"
                    font.pixelSize: 12
                    color: "#e0e0ff"
                    Layout.fillWidth: true
                    elide: Text.ElideRight
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    Rectangle {
                        Layout.fillWidth: true
                        height: 6
                        radius: 3
                        color: "#1a1a2e"
                        Rectangle {
                            width: parent.width * Math.min(hwPanel.cpuUsage / 100.0, 1.0)
                            height: parent.height
                            radius: parent.radius
                            color: hwPanel.cpuUsage > 80 ? "#cc4444"
                                 : hwPanel.cpuUsage > 60 ? "#cc8844"
                                 : Theme.accentColor
                            Behavior on width { NumberAnimation { duration: 400 } }
                        }
                    }

                    Text {
                        text: hwPanel.cpuUsage + "%"
                        font.family: "JetBrains Mono"
                        font.pixelSize: 12
                        color: "#e0e0ff"
                        Layout.preferredWidth: 40
                        horizontalAlignment: Text.AlignRight
                    }
                }

                MiniGraph {
                    Layout.fillWidth: true
                    values: hwPanel.cpuHistory
                    lineColor: Theme.accentColor
                }
            }

            Rectangle { Layout.fillWidth: true; height: 1; color: "#1e1e30" }

            // ── RAM ──────────────────────────────────────────────────
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 6

                Text {
                    text: "RAM"
                    font.family: "JetBrains Mono"
                    font.pixelSize: 10
                    font.weight: Font.Bold
                    font.letterSpacing: 1.5
                    color: Theme.accentMuted
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    Rectangle {
                        Layout.fillWidth: true
                        height: 6
                        radius: 3
                        color: "#1a1a2e"
                        property real ratio: hwPanel.ramTotalBytes > 0
                            ? hwPanel.ramUsedBytes / hwPanel.ramTotalBytes : 0
                        Rectangle {
                            width: parent.width * Math.min(parent.ratio, 1.0)
                            height: parent.height
                            radius: parent.radius
                            color: parent.ratio > 0.85 ? "#cc4444"
                                 : parent.ratio > 0.65 ? "#cc8844"
                                 : "#4a8e4a"
                            Behavior on width { NumberAnimation { duration: 400 } }
                        }
                    }

                    Text {
                        text: hwPanel.ramTotalBytes > 0
                            ? hwPanel.formatGiB(hwPanel.ramUsedBytes) + " / " + hwPanel.formatGiB(hwPanel.ramTotalBytes)
                            : "..."
                        font.family: "JetBrains Mono"
                        font.pixelSize: 12
                        color: "#e0e0ff"
                        Layout.preferredWidth: 140
                        horizontalAlignment: Text.AlignRight
                    }
                }

                MiniGraph {
                    Layout.fillWidth: true
                    values: hwPanel.ramHistory
                    lineColor: "#4a8e4a"
                }
            }

            Rectangle { Layout.fillWidth: true; height: 1; color: "#1e1e30" }

            // ── GPU ──────────────────────────────────────────────────
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 6

                RowLayout {
                    Layout.fillWidth: true
                    Text {
                        text: "GPU"
                        font.family: "JetBrains Mono"
                        font.pixelSize: 10
                        font.weight: Font.Bold
                        font.letterSpacing: 1.5
                        color: Theme.accentMuted
                        Layout.fillWidth: true
                    }
                    Text {
                        visible: hwPanel.gpuTemp.length > 0
                        text: hwPanel.gpuTemp
                        font.family: "JetBrains Mono"
                        font.pixelSize: 11
                        color: {
                            const v = parseInt(hwPanel.gpuTemp) || 0;
                            return v > 95 ? "#cc4444" : v > 75 ? "#cc8844" : "#88ccaa";
                        }
                    }
                }

                Text {
                    text: hwPanel.gpuName
                    font.family: "JetBrains Mono"
                    font.pixelSize: 12
                    color: "#e0e0ff"
                    Layout.fillWidth: true
                    elide: Text.ElideRight
                }

                Text {
                    visible: hwPanel.gpuUsage.length > 0
                    text: hwPanel.gpuUsage
                    font.family: "JetBrains Mono"
                    font.pixelSize: 11
                    color: "#aaaacc"
                }

                RowLayout {
                    visible: hwPanel.gpuUsage.length > 0
                    Layout.fillWidth: true
                    spacing: 8

                    Rectangle {
                        Layout.fillWidth: true
                        height: 6
                        radius: 3
                        color: "#1a1a2e"
                        Rectangle {
                            width: parent.width * Math.min(hwPanel.gpuUsagePercent / 100.0, 1.0)
                            height: parent.height
                            radius: parent.radius
                            color: hwPanel.gpuUsagePercent > 80 ? "#cc4444"
                                 : hwPanel.gpuUsagePercent > 60 ? "#cc8844"
                                 : "#8e4a8e"
                            Behavior on width { NumberAnimation { duration: 400 } }
                        }
                    }

                    Text {
                        text: hwPanel.gpuUsagePercent + "%"
                        font.family: "JetBrains Mono"
                        font.pixelSize: 12
                        color: "#e0e0ff"
                        Layout.preferredWidth: 40
                        horizontalAlignment: Text.AlignRight
                    }
                }

                MiniGraph {
                    Layout.fillWidth: true
                    values: hwPanel.gpuHistory
                    lineColor: "#8e4a9e"
                }
            }

            Rectangle { Layout.fillWidth: true; height: 1; color: "#1e1e30" }

            // ── Disques ──────────────────────────────────────────────
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 10

                Text {
                    text: "Disques"
                    font.family: "JetBrains Mono"
                    font.pixelSize: 10
                    font.weight: Font.Bold
                    font.letterSpacing: 1.5
                    color: Theme.accentMuted
                }

                Text {
                    visible: hwPanel.diskData.length === 0
                    text: "Chargement..."
                    font.family: "JetBrains Mono"
                    font.pixelSize: 12
                    color: "#555577"
                }

                Repeater {
                    model: hwPanel.diskData
                    delegate: ColumnLayout {
                        required property var modelData
                        Layout.fillWidth: true
                        spacing: 4

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 6

                            Text {
                                text: modelData.mount
                                font.family: "JetBrains Mono"
                                font.pixelSize: 12
                                color: "#e0e0ff"
                                Layout.fillWidth: true
                                elide: Text.ElideRight
                            }

                            Text {
                                text: modelData.used + " Go / " + modelData.size + " Go"
                                font.family: "JetBrains Mono"
                                font.pixelSize: 11
                                color: "#aaaacc"
                            }

                            Text {
                                property real ratio: modelData.size > 0 ? modelData.used / modelData.size : 0
                                text: Math.round(ratio * 100) + "%"
                                font.family: "JetBrains Mono"
                                font.pixelSize: 11
                                color: ratio > 0.85 ? "#cc4444" : ratio > 0.65 ? "#cc8844" : "#e0e0ff"
                                Layout.preferredWidth: 36
                                horizontalAlignment: Text.AlignRight
                            }

                            Rectangle {
                                width: 22
                                height: 22
                                radius: 4
                                color: openBtn.containsMouse ? Theme.accentDark : "transparent"
                                border.color: openBtn.containsMouse ? Theme.accentColor : "#2a2a3e"
                                border.width: 1

                                Text {
                                    anchors.centerIn: parent
                                    text: "\u23CD"
                                    font.pixelSize: 12
                                    color: openBtn.containsMouse ? "#aaaaff" : "#555577"
                                }

                                MouseArea {
                                    id: openBtn
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        hwPanel.openTarget = modelData.mount;
                                        openFolderProc.running = true;
                                    }
                                }
                            }
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            height: 5
                            radius: 3
                            color: "#1a1a2e"
                            property real ratio: modelData.size > 0
                                ? modelData.used / modelData.size : 0
                            Rectangle {
                                width: parent.width * Math.min(parent.ratio, 1.0)
                                height: parent.height
                                radius: parent.radius
                                color: parent.ratio > 0.85 ? "#cc4444"
                                     : parent.ratio > 0.65 ? "#cc8844"
                                     : "#4a6a8e"
                            }
                        }

                        Text {
                            text: modelData.source
                            font.family: "JetBrains Mono"
                            font.pixelSize: 10
                            color: "#444466"
                        }
                    }
                }
            }

            Item { height: 8 }
        }
    }
}
