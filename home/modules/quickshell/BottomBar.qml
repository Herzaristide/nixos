import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Services.UPower

PanelWindow {
    id: window
    anchors {
        bottom: true
        left: true
        right: true
    }

    margins {
        bottom: 10
        left: 0
        right: 0
    }

    height: 36
    color: "transparent"
    mask: null  // Disable window mask
    visible: true

    WlrLayershell {
        layer: WlrLayer.Bottom
        keyboardFocus: WlrKeyboardFocus.None
        namespace: "quickshell-bottombar"
    }

    // Roman numeral conversion function
    function toRoman(num) {
        const romanNumerals = ["I", "II", "III", "IV", "V"];
        return romanNumerals[num - 1] || "";
    }

    // Main content container
    Rectangle {
        anchors.fill: parent
        color: "transparent"

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 20
            anchors.rightMargin: 20

            // Workspaces (left side)
            RowLayout {
                Layout.alignment: Qt.AlignLeft
                spacing: 24

                Repeater {
                    model: 5

                    Text {
                        required property int index

                        text: window.toRoman(index + 1)
                        font.family: "Terminus"
                        font.pixelSize: 16
                        font.weight: Hyprland.focusedWorkspace?.id === (index + 1) ? Font.Bold : Font.Normal
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

            // Spacer
            Item {
                Layout.fillWidth: true
            }

            // Battery (right side)
            RowLayout {
                Layout.alignment: Qt.AlignRight
                spacing: 8

                Text {
                    id: batteryIcon
                    visible: UPower.displayDevice !== null
                    text: {
                        if (!UPower.displayDevice) return "";
                        const percentage = UPower.displayDevice.percentage;
                        const isCharging = UPower.displayDevice.state === UPower.DeviceState.Charging;

                        if (isCharging) return "⚡";
                        if (percentage > 80) return "󰁹";
                        if (percentage > 60) return "󰂀";
                        if (percentage > 40) return "󰁿";
                        if (percentage > 20) return "󰁼";
                        return "󰁺";
                    }
                    font.pixelSize: 16
                    color: "#FFFFFF"
                    opacity: {
                        if (!UPower.displayDevice) return 0.8;
                        return UPower.displayDevice.percentage < 20 ? 1.0 : 0.8;
                    }
                }

                Text {
                    id: batteryText
                    visible: UPower.displayDevice !== null
                    text: {
                        if (!UPower.displayDevice) return "N/A";
                        return Math.round(UPower.displayDevice.percentage) + "%";
                    }
                    font.family: "Terminus"
                    font.pixelSize: 16
                    color: "#FFFFFF"
                    opacity: {
                        if (!UPower.displayDevice) return 0.8;
                        return UPower.displayDevice.percentage < 20 ? 1.0 : 0.8;
                    }
                }
            }
        }
    }
}
