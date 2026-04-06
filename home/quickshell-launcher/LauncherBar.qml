import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland

PanelWindow {
    id: window
    anchors {
        bottom: true
        left: true
        right: true
    }

    margins {
        bottom: 15
        left: 0
        right: 0
    }

    height: 45
    color: "transparent"

    WlrLayershell {
        layer: WlrLayer.Top
        keyboardFocus: WlrKeyboardFocus.Exclusive
        namespace: "quickshell-launcher"
    }

    // Main container
    Rectangle {
        id: barContainer
        anchors.centerIn: parent
        width: Math.min(600, parent.width * 0.4)  // 40% of screen width, max 600px
        height: parent.height
        radius: 20
        color: "#DD000000"  // Semi-transparent black
        border.color: "#D90202"  // Bright red border
        border.width: 2

        RowLayout {
            anchors.fill: parent
            anchors.margins: 10
            spacing: 8

            // Search icon
            Text {
                text: "🔍"
                font.pixelSize: 20
                color: "#D90202"
                Layout.alignment: Qt.AlignVCenter
            }

            // Input field
            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                color: "transparent"

                TextInput {
                    id: searchInput
                    anchors.fill: parent
                    anchors.margins: 3
                    font.pixelSize: 14
                    font.family: "MonoidNerdFont"
                    color: "#33D4C4"  // Cyan
                    verticalAlignment: TextInput.AlignVCenter
                    activeFocusOnTab: true

                    Text {
                        text: "Rechercher des applications..."
                        font.pixelSize: 14
                        font.family: "MonoidNerdFont"
                        color: "#666666"
                        visible: searchInput.text === ""
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    Component.onCompleted: {
                        searchInput.forceActiveFocus()
                    }

                    Keys.onReturnPressed: {
                        if (searchInput.text !== "") {
                            // Launch rofi with the search text
                            Quickshell.Process.exec("/run/current-system/sw/bin/rofi",
                                          ["-show", "drun", "-filter", searchInput.text])
                            searchInput.text = ""
                        } else {
                            // Launch rofi normally
                            Quickshell.Process.exec("/run/current-system/sw/bin/rofi",
                                          ["-show", "drun"])
                        }
                    }

                    Keys.onEscapePressed: {
                        searchInput.text = ""
                    }

                    onTextChanged: {
                        // Optionally trigger search as you type
                        if (searchInput.text.length > 2) {
                            searchTimer.restart()
                        }
                    }
                }
            }

            // Launch button
            Rectangle {
                Layout.preferredWidth: 80
                Layout.fillHeight: true
                color: "#FFFFFF"
                radius: 12

                Text {
                    anchors.centerIn: parent
                    text: "⏎"
                    font.pixelSize: 20
                    color: "#D90202"
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (searchInput.text !== "") {
                            Quickshell.Process.exec("/run/current-system/sw/bin/rofi",
                                          ["-show", "drun", "-filter", searchInput.text])
                            searchInput.text = ""
                        } else {
                            Quickshell.Process.exec("/run/current-system/sw/bin/rofi",
                                          ["-show", "drun"])
                        }
                        searchInput.forceActiveFocus()
                    }
                }
            }
        }
    }

    // Timer for search-as-you-type (optional)
    Timer {
        id: searchTimer
        interval: 500
        repeat: false
        onTriggered: {
            // Could implement live filtering here if needed
        }
    }
}
