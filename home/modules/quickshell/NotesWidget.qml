import QtQuick
import QtQuick.Controls
import QtCore

Item {
    id: root

    Settings {
        id: settings
        category: "notes"
        property string content: ""
    }

    Timer {
        id: saveTimer
        interval: 1500
        onTriggered: settings.content = editor.text
    }

    ScrollView {
        id: scroll
        anchors.fill: parent
        anchors.margins: 8
        ScrollBar.horizontal.policy: ScrollBar.AlwaysOff

        TextArea {
            id: editor
            width: scroll.availableWidth
            text: settings.content
            font.family: "JetBrains Mono"
            font.pixelSize: 13
            color: "#FFFFFF"
            wrapMode: TextEdit.Wrap
            selectByMouse: true
            placeholderText: "Vos notes…"
            placeholderTextColor: "#40FFFFFF"
            background: Rectangle { color: "transparent" }
            onTextChanged: saveTimer.restart()
            Component.onCompleted: cursorPosition = text.length
        }
    }
}
