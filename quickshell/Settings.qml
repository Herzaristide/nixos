import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io

Item {
    id: root

    property var sinks: []
    property var sources: []
    property string pendingId: ""

    // ── wpctl status → parse sinks + sources with active flag ───
    Process {
        id: statusProc
        command: [
            "sh", "-c",
            "wpctl status | awk '" +
            "/Sinks:/{sec=\"sink\"} /Sources:/{sec=\"source\"} /Filters:|Streams:|Video/{sec=\"\"} " +
            "sec&&/[0-9]+\\./{act=(index($0,\"*\")>0)?\"true\":\"false\"; line=$0; gsub(/^[^0-9]*/,\"\",line); id=line+0; " +
            "desc=line; sub(/^[0-9]+\\. */,\"\",desc); gsub(/ *\\[.*/,\"\",desc); gsub(/ *$/,\"\",desc); " +
            "print sec\"|\"id\"|\"act\"|\"desc}'"
        ]
        stdout: StdioCollector { id: statusOut }
        onRunningChanged: {
            if (!running) {
                const newSinks = [];
                const newSources = [];
                const lines = statusOut.text.trim().split('\n');
                for (const line of lines) {
                    if (!line) continue;
                    const parts = line.split('|');
                    if (parts.length < 4) continue;
                    const entry = {
                        id:     parts[1],
                        active: parts[2] === "true",
                        desc:   parts.slice(3).join('|')
                    };
                    if (parts[0] === "sink")   newSinks.push(entry);
                    if (parts[0] === "source") newSources.push(entry);
                }
                root.sinks   = newSinks;
                root.sources = newSources;
            }
        }
    }

    // ── wpctl set-default <id> ───────────────────────────────────
    Process {
        id: setDefaultProc
        command: ["sh", "-c", "wpctl set-default \"$1\"", "--", root.pendingId]
        onRunningChanged: {
            if (!running && !statusProc.running) statusProc.running = true;
        }
    }

    // ── Refresh timer ────────────────────────────────────────────
    Timer {
        interval: 3000
        repeat: true
        running: true
        onTriggered: {
            if (!statusProc.running) statusProc.running = true;
        }
    }

    Component.onCompleted: statusProc.running = true

    // ── UI ────────────────────────────────────────────────────────
    Flickable {
        anchors.fill: parent
        contentHeight: mainCol.implicitHeight
        clip: true
        boundsBehavior: Flickable.StopAtBounds

        ScrollBar.vertical: ScrollBar {
            policy: ScrollBar.AsNeeded
        }

        ColumnLayout {
            id: mainCol
            width: parent.width
            spacing: 0

            // ── Header ───────────────────────────────────────────
            RowLayout {
                Layout.fillWidth: true
                Layout.bottomMargin: 8
                spacing: 8

                Text {
                    text: "settings"
                    font.family: "Material Symbols Rounded"
                    font.pixelSize: 18
                    color: Theme.accentMuted
                }

                Text {
                    text: "Paramètres"
                    font.family: "JetBrains Mono"
                    font.pixelSize: 14
                    font.weight: Font.Bold
                    color: Theme.textPrimary
                    Layout.fillWidth: true
                }
            }

            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: Theme.accentDark
                Layout.bottomMargin: 16
            }

            // ── APPARENCE section ──────────────────────────────
            Text {
                Layout.bottomMargin: 10
                text: "APPARENCE"
                font.family: "JetBrains Mono"
                font.pixelSize: 10
                font.letterSpacing: 1.5
                color: Theme.accentMuted
            }

            // ── Dark / Light mode toggle ───────────────────────
            RowLayout {
                Layout.fillWidth: true
                Layout.bottomMargin: 12
                spacing: 8

                // Sun icon
                Text {
                    text: "light_mode"
                    font.family: "Material Symbols Rounded"
                    font.pixelSize: 16
                    color: Theme.darkMode ? Theme.textDim : Theme.accentColor
                    Behavior on color { ColorAnimation { duration: 150 } }
                }

                // Toggle pill
                Rectangle {
                    id: themePill
                    width: 44; height: 22; radius: 11
                    color: Theme.darkMode ? Theme.accentDark : Theme.accentColor
                    Behavior on color { ColorAnimation { duration: 200 } }

                    // Knob
                    Rectangle {
                        width: 16; height: 16; radius: 8
                        anchors.verticalCenter: parent.verticalCenter
                        x: Theme.darkMode ? 24 : 4
                        color: "#FFFFFF"
                        Behavior on x { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: Theme.toggleTheme()
                    }
                }

                // Moon icon
                Text {
                    text: "dark_mode"
                    font.family: "Material Symbols Rounded"
                    font.pixelSize: 16
                    color: Theme.darkMode ? Theme.accentColor : Theme.textDim
                    Behavior on color { ColorAnimation { duration: 150 } }
                }

                Item { Layout.fillWidth: true }

                Text {
                    text: Theme.darkMode ? "Sombre" : "Clair"
                    font.family: "JetBrains Mono"
                    font.pixelSize: 11
                    color: Theme.textSecondary
                }
            }

            // Color preview chip + hex input
            RowLayout {
                Layout.fillWidth: true
                Layout.bottomMargin: 8
                spacing: 8

                Rectangle {
                    width: 24; height: 24; radius: 5
                    color: Theme.accentColor
                    border.color: Qt.rgba(1, 1, 1, 0.25)
                    border.width: 1
                }

                TextField {
                    id: hexField
                    Layout.fillWidth: true
                    text: Theme.accentColor.toString().toUpperCase()
                    font.family: "JetBrains Mono"
                    font.pixelSize: 12
                    color: Theme.textPrimary
                    leftPadding: 8; rightPadding: 8
                    selectByMouse: true
                    background: Rectangle {
                        color: Theme.bgInput
                        radius: 4
                        border.color: Theme.accentDark
                        border.width: 1
                    }
                    Connections {
                        target: Theme
                        function onAccentColorChanged() {
                            if (!hexField.activeFocus)
                                hexField.text = Theme.accentColor.toString().toUpperCase()
                        }
                    }
                    onEditingFinished: {
                        var t = text.trim()
                        if (!t.startsWith("#")) t = "#" + t
                        if (/^#[0-9a-fA-F]{6}$/.test(t) || /^#[0-9a-fA-F]{3}$/.test(t)) {
                            colorPicker.initFromColor(Qt.color(t))
                            Theme.setAccentColor(t.toLowerCase())
                        } else {
                            text = Theme.accentColor.toString().toUpperCase()
                        }
                    }
                }
            }

            // ── Color picker ─────────────────────────────────────
            Item {
                id: colorPicker
                Layout.fillWidth: true
                Layout.preferredHeight: 144  // 120 field + 8 gap + 14 hue + 2 padding
                Layout.bottomMargin: 16

                // Internal HSV state (0.0 – 1.0 each)
                property real pickerH: 0.667
                property real pickerS: 0.5
                property real pickerV: 0.56

                Component.onCompleted: initFromColor(Theme.accentColor)

                function initFromColor(c) {
                    var hsv = rgbToHsv(c.r, c.g, c.b)
                    pickerH = hsv.h
                    pickerS = hsv.s
                    pickerV = hsv.v
                }

                function rgbToHsv(r, g, b) {
                    var max = Math.max(r, g, b), min = Math.min(r, g, b)
                    var delta = max - min
                    var h = 0, s = 0, v = max
                    if (max > 0) s = delta / max
                    if (delta > 0) {
                        if (max === r)      h = ((g - b) / delta) % 6
                        else if (max === g) h = (b - r) / delta + 2
                        else               h = (r - g) / delta + 4
                        h /= 6
                        if (h < 0) h += 1
                    }
                    return { h: h, s: s, v: v }
                }

                function hsvToHex(h, s, v) {
                    var i = Math.floor(h * 6), f = h * 6 - i
                    var p = v * (1 - s), q = v * (1 - f * s), t = v * (1 - (1 - f) * s)
                    var r, g, b
                    switch (i % 6) {
                        case 0: r = v; g = t; b = p; break
                        case 1: r = q; g = v; b = p; break
                        case 2: r = p; g = v; b = t; break
                        case 3: r = p; g = q; b = v; break
                        case 4: r = t; g = p; b = v; break
                        case 5: r = v; g = p; b = q; break
                    }
                    function x2h(n) { var s = Math.round(n * 255).toString(16); return s.length === 1 ? "0"+s : s }
                    return "#" + x2h(r) + x2h(g) + x2h(b)
                }

                function updateAccent() {
                    Theme.setAccentColor(hsvToHex(pickerH, pickerS, pickerV))
                }

                // ── Saturation / brightness field ─────────────────
                Canvas {
                    id: fieldCanvas
                    anchors.top: parent.top
                    anchors.left: parent.left
                    anchors.right: parent.right
                    height: 120

                    Connections {
                        target: colorPicker
                        function onPickerHChanged() { fieldCanvas.requestPaint() }
                    }

                    onPaint: {
                        var ctx = getContext("2d"), w = width, h = height
                        // Base: pure hue at full saturation + value
                        ctx.fillStyle = colorPicker.hsvToHex(colorPicker.pickerH, 1.0, 1.0)
                        ctx.fillRect(0, 0, w, h)
                        // White → transparent (left = white, right = saturated)
                        var wg = ctx.createLinearGradient(0, 0, w, 0)
                        wg.addColorStop(0.0, "rgba(255,255,255,1)")
                        wg.addColorStop(1.0, "rgba(255,255,255,0)")
                        ctx.fillStyle = wg; ctx.fillRect(0, 0, w, h)
                        // Transparent → black (top = bright, bottom = dark)
                        var bg = ctx.createLinearGradient(0, 0, 0, h)
                        bg.addColorStop(0.0, "rgba(0,0,0,0)")
                        bg.addColorStop(1.0, "rgba(0,0,0,1)")
                        ctx.fillStyle = bg; ctx.fillRect(0, 0, w, h)
                    }

                    // Crosshair cursor
                    Rectangle {
                        x: colorPicker.pickerS * fieldCanvas.width  - width  / 2
                        y: (1 - colorPicker.pickerV) * fieldCanvas.height - height / 2
                        width: 14; height: 14; radius: 7
                        color: "transparent"
                        border.color: "#FFFFFF"; border.width: 2
                        antialiasing: true
                        Rectangle {
                            anchors.centerIn: parent
                            width: 6; height: 6; radius: 3
                            color: "transparent"
                            border.color: Qt.rgba(0, 0, 0, 0.55); border.width: 1
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.CrossCursor
                        function pick(mouse) {
                            colorPicker.pickerS = Math.max(0, Math.min(1, mouse.x / width))
                            colorPicker.pickerV = Math.max(0, Math.min(1, 1 - mouse.y / height))
                            colorPicker.updateAccent()
                        }
                        onPressed:         (mouse) => pick(mouse)
                        onPositionChanged: (mouse) => { if (pressed) pick(mouse) }
                    }
                }

                // ── Hue strip ─────────────────────────────────────
                Item {
                    id: hueRow
                    anchors.top: fieldCanvas.bottom
                    anchors.topMargin: 8
                    anchors.left: parent.left
                    anchors.right: parent.right
                    height: 14

                    Canvas {
                        id: hueCanvas
                        anchors.fill: parent
                        onPaint: {
                            var ctx = getContext("2d")
                            var grad = ctx.createLinearGradient(0, 0, width, 0)
                            for (var i = 0; i <= 12; i++) {
                                var stop = i / 12
                                grad.addColorStop(stop, "hsl(" + Math.round(stop * 360) + ",100%,50%)")
                            }
                            var r = 4
                            ctx.beginPath()
                            ctx.moveTo(r, 0); ctx.lineTo(width - r, 0)
                            ctx.arcTo(width, 0,      width,      r,          r)
                            ctx.lineTo(width, height - r)
                            ctx.arcTo(width, height, width - r,  height,     r)
                            ctx.lineTo(r, height)
                            ctx.arcTo(0, height,     0,          height - r, r)
                            ctx.lineTo(0, r)
                            ctx.arcTo(0, 0,          r,          0,          r)
                            ctx.closePath()
                            ctx.fillStyle = grad; ctx.fill()
                        }
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            function pick(mouse) {
                                colorPicker.pickerH = Math.max(0, Math.min(0.9999, mouse.x / width))
                                fieldCanvas.requestPaint()
                                colorPicker.updateAccent()
                            }
                            onPressed:         (mouse) => pick(mouse)
                            onPositionChanged: (mouse) => { if (pressed) pick(mouse) }
                        }
                    }

                    // Thumb indicator
                    Rectangle {
                        x: colorPicker.pickerH * hueRow.width - width / 2
                        y: -2
                        width: 5; height: hueRow.height + 4; radius: 2.5
                        color: "#FFFFFF"
                        border.color: Qt.rgba(0, 0, 0, 0.45); border.width: 1
                        antialiasing: true
                    }
                }
            }

            // ── AUDIO section ──────────────────────────────
            Text {
                Layout.leftMargin: 4
                Layout.bottomMargin: 12
                text: "AUDIO"
                font.family: "JetBrains Mono"
                font.pixelSize: 10
                font.letterSpacing: 1.5
                color: Theme.accentMuted
            }

            // ── Output (Sortie) ──────────────────────────────────
            Text {
                Layout.leftMargin: 4
                Layout.bottomMargin: 8
                text: "SORTIE"
                font.family: "JetBrains Mono"
                font.pixelSize: 10
                font.letterSpacing: 1.5
                color: Theme.accentMuted
            }

            AudioComboBox {
                Layout.fillWidth: true
                Layout.bottomMargin: 16
                devices: root.sinks
                onActivate: (id) => {
                    root.pendingId = id;
                    setDefaultProc.running = true;
                }
            }

            // ── Input ─────────────────────────────────────────────
            Text {
                Layout.leftMargin: 4
                Layout.bottomMargin: 8
                text: "ENTRÉE"
                font.family: "JetBrains Mono"
                font.pixelSize: 10
                font.letterSpacing: 1.5
                color: Theme.accentMuted
            }

            AudioComboBox {
                Layout.fillWidth: true
                Layout.bottomMargin: 16
                devices: root.sources
                onActivate: (id) => {
                    root.pendingId = id;
                    setDefaultProc.running = true;
                }
            }

            Item { Layout.preferredHeight: 8 }
        }
    }

    // ── Styled audio device ComboBox ─────────────────────────────
    component AudioComboBox: ComboBox {
        id: audioCombo
        property var devices: []
        signal activate(string id)

        model: devices.map(d => d.desc)
        currentIndex: {
            const idx = devices.findIndex(d => d.active);
            return idx >= 0 ? idx : 0;
        }

        onActivated: (index) => {
            if (index >= 0 && index < devices.length)
                activate(devices[index].id);
        }

        // ── Dropdown arrow ────────────────────────────────────
        indicator: Text {
            x: parent.width - width - 12
            anchors.verticalCenter: parent.verticalCenter
            text: "expand_more"
            font.family: "Material Symbols Rounded"
            font.pixelSize: 18
            color: Theme.textSecondary
        }

        // ── Selected value text ───────────────────────────────
        contentItem: Text {
            leftPadding: 12
            rightPadding: 36
            text: parent.displayText
            font.family: "JetBrains Mono"
            font.pixelSize: 12
            color: Theme.textPrimary
            verticalAlignment: Text.AlignVCenter
            elide: Text.ElideRight
        }

        // ── Box background ────────────────────────────────────
        background: Rectangle {
            radius: 8
            color: parent.pressed ? Theme.bgElevated
                 : parent.hovered ? Qt.lighter(Theme.bgElevated, 1.05)
                 : Theme.bgInput
            border.color: parent.popup.visible ? Theme.accentColor : Theme.bgElevated
            border.width: 1
            implicitHeight: 40
        }

        // ── Dropdown popup ────────────────────────────────────
        popup: Popup {
            y: parent.height + 4
            width: parent.width
            padding: 0

            background: Rectangle {
                radius: 8
                color: Theme.bgInput
                border.color: Theme.bgElevated
                border.width: 1
            }

            contentItem: ListView {
                implicitHeight: contentHeight
                model: audioCombo.delegateModel
                clip: true
            }
        }

        // ── Per-item delegate ─────────────────────────────────
        delegate: ItemDelegate {
            required property int index
            required property string modelData

            width: audioCombo.width
            highlighted: audioCombo.currentIndex === index

            contentItem: Text {
                leftPadding: 12
                rightPadding: 12
                text: modelData
                font.family: "JetBrains Mono"
                font.pixelSize: 12
                color: Theme.textPrimary
                verticalAlignment: Text.AlignVCenter
                elide: Text.ElideRight
            }

            background: Rectangle {
                color: parent.highlighted ? Theme.accentColor
                     : parent.hovered     ? Theme.bgElevated
                     : "transparent"
                radius: 6
            }

            implicitHeight: 40
        }
    }
}
