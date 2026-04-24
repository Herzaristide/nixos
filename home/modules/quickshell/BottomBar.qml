import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Services.UPower

PanelWindow {
    id: window

    // Configure the underlying wlr-layer-shell via attached properties.
    // PanelWindow IS the layer-shell window; NEVER nest a WlrLayershell{} child
    // — that creates a second ghost window (appears as a white rectangle).
    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.namespace: "quickshell-bottombar"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

    anchors {
        bottom: true
        left: true
        right: true
    }

    margins {
        bottom: 8
        left: 0
        right: 0
    }

    height: 20
    color: "transparent"

    // Only show on HDMI-A-1 (main monitor, workspaces 1–5)
    visible: screen && screen.name === "HDMI-A-1"

    // Roman numeral conversion function
    function toRoman(num) {
        const romanNumerals = ["I", "II", "III", "IV", "V"];
        return romanNumerals[num - 1] || "";
    }

    // Format seconds as "Hh Mm" (e.g. 15780 -> "4h 23m"). Empty string when unknown.
    function formatTime(seconds) {
        if (!seconds || seconds <= 0 || !isFinite(seconds)) return "";
        const totalMinutes = Math.round(seconds / 60);
        const h = Math.floor(totalMinutes / 60);
        const m = totalMinutes % 60;
        if (h <= 0) return m + "m";
        return h + "h " + m + "m";
    }

    // Prefer the first present hardware battery over UPower.displayDevice
    // (displayDevice is an aggregated synthetic device and can differ by ~1%).
    readonly property var batteryDevice: {
        const devs = UPower.devices ? UPower.devices.values : null;
        if (devs) {
            for (let i = 0; i < devs.length; i++) {
                const d = devs[i];
                if (d && d.isPresent && d.type === UPower.DeviceType.Battery)
                    return d;
            }
        }
        return UPower.displayDevice;
    }

    // Main content container
    Rectangle {
        anchors.fill: parent
        color: "transparent"

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 16
            anchors.rightMargin: 16
            spacing: 0

            // Left: NixOS logo
            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true

                Image {
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    source: "nixos.svg"
                    width: 20
                    height: 20
                    sourceSize.width: 64
                    sourceSize.height: 64
                    fillMode: Image.PreserveAspectFit
                    smooth: true
                    opacity: 0.8
                }
            }

            // Center: workspaces
            RowLayout {
                spacing: 8

                Repeater {
                    model: 5

                    Text {
                        required property int index

                        text: window.toRoman(index + 1)
                        font.family: "JetBrains Mono"
                        font.pixelSize: 16
                        font.weight: Font.Normal
                        color: "#FFFFFF"

                        // Opacity based on workspace state
                        opacity: {
                            const workspaceId = index + 1;
                            const isActive = Hyprland.focusedWorkspace?.id === workspaceId;

                            if (isActive) {
                                return 1.0;
                            }

                            // Check if workspace has windows
                            if (Hyprland.workspaces && Hyprland.workspaces.values) {
                                const workspace = Hyprland.workspaces.values.find(ws => ws.id === workspaceId);
                                const hasWindows = workspace && workspace.windows && workspace.windows.values && workspace.windows.values.length > 0;
                                return hasWindows ? 0.6 : 0.3;
                            }

                            return 0.3;
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                Hyprland.dispatch("workspace " + (parent.index + 1).toString());
                            }
                        }
                    }
                }
            }

            // Right: battery (hidden when no battery present)
            Item {
                id: batterySection
                Layout.fillWidth: true
                visible: dev !== null && dev.isPresent

                readonly property var  dev: window.batteryDevice
                readonly property real pct: dev ? dev.percentage : 0
                readonly property int  devState: dev ? dev.state : 0
                readonly property bool isCharging: devState === UPower.DeviceState.Charging
                readonly property bool isFullyCharged: devState === UPower.DeviceState.FullyCharged
                readonly property bool onAc: !UPower.onBattery
                readonly property int  timeSecs: {
                    if (!dev) return 0;
                    if (isCharging) return dev.timeToFull || 0;
                    return dev.timeToEmpty || 0;
                }
                readonly property real rowOpacity: pct > 0 && pct < 20 ? 1.0 : 0.8

                Row {
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 8

                    // AC indicator (visible whenever we're on mains power)
                    Text {
                        visible: batterySection.onAc
                        text: "AC"
                        font.family: "JetBrains Mono"
                        font.pixelSize: 16
                        color: "#FFFFFF"
                        opacity: batterySection.rowOpacity
                    }

                    // Battery glyph
                    Text {
                        visible: batterySection.dev !== null
                        text: {
                            if (!batterySection.dev) return "";
                            if (batterySection.isCharging) return "⚡";
                            const p = batterySection.pct;
                            if (p > 80) return "󰁹";
                            if (p > 60) return "󰂀";
                            if (p > 40) return "󰁿";
                            if (p > 20) return "󰁼";
                            return "󰁺";
                        }
                        font.pixelSize: 16
                        color: "#FFFFFF"
                        opacity: batterySection.rowOpacity
                    }

                    // Percentage
                    Text {
                        visible: batterySection.dev !== null
                        text: batterySection.dev ? (Math.round(batterySection.pct) + "%") : "N/A"
                        font.family: "JetBrains Mono"
                        font.pixelSize: 16
                        color: "#FFFFFF"
                        opacity: batterySection.rowOpacity
                    }

                    // Time remaining (hidden when FullyCharged or unknown)
                    Text {
                        readonly property string label: window.formatTime(batterySection.timeSecs)
                        visible: batterySection.dev !== null && !batterySection.isFullyCharged && label.length > 0
                        text: label
                        font.family: "JetBrains Mono"
                        font.pixelSize: 16
                        color: "#FFFFFF"
                        opacity: batterySection.rowOpacity
                    }
                }
            }
        }
    }
}
