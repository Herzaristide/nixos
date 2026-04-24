import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

Item {
    id: root

    property string modelName: "llama3"
    property bool isStreaming: false

    ListModel { id: messages }

    // Build context array from current messages (excludes last placeholder)
    function buildContext(upToIdx) {
        var ctx = [];
        for (var i = 0; i < upToIdx; i++)
            ctx.push({ role: messages.get(i).role, content: messages.get(i).content });
        return ctx;
    }

    function sendMessage() {
        var text = inputField.text.trim();
        if (text === "" || root.isStreaming) return;

        inputField.text = "";
        messages.append({ role: "user", content: text });
        messages.append({ role: "assistant", content: "" });
        var assistantIdx = messages.count - 1;
        var ctx = root.buildContext(assistantIdx);

        root.isStreaming = true;
        var lastPos = 0;
        var gotChunk = false;

        var xhr = new XMLHttpRequest();
        xhr.open("POST", "http://localhost:11434/api/chat");
        xhr.setRequestHeader("Content-Type", "application/json");

        xhr.onreadystatechange = function() {
            if (xhr.readyState === 3 || xhr.readyState === 4) {
                var chunk = xhr.responseText.slice(lastPos);
                lastPos = xhr.responseText.length;
                var lines = chunk.split("\n");
                for (var j = 0; j < lines.length; j++) {
                    var line = lines[j].trim();
                    if (line === "") continue;
                    try {
                        var obj = JSON.parse(line);
                        if (obj.message && typeof obj.message.content === "string") {
                            var cur = messages.get(assistantIdx).content;
                            messages.setProperty(assistantIdx, "content",
                                cur + obj.message.content);
                            gotChunk = true;
                        }
                    } catch (e) {}
                }
            }
            if (xhr.readyState === 4) {
                if (!gotChunk)
                    messages.setProperty(assistantIdx, "content",
                        "[Erreur : impossible de joindre Ollama sur localhost:11434]");
                root.isStreaming = false;
            }
        };

        xhr.send(JSON.stringify({
            model: root.modelName,
            messages: ctx,
            stream: true
        }));
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 8
        spacing: 6

        // ── Header: model selector + clear ──────────────────────────
        RowLayout {
            Layout.fillWidth: true
            spacing: 6

            Text {
                text: "Modèle :"
                color: "#FFFFFF"
                opacity: 0.5
                font.family: "JetBrains Mono"
                font.pixelSize: 11
            }

            Rectangle {
                Layout.preferredWidth: 120
                height: 24
                color: "#1a1a2e"
                radius: 4

                TextField {
                    id: modelField
                    anchors.fill: parent
                    anchors.margins: 2
                    text: root.modelName
                    font.family: "JetBrains Mono"
                    font.pixelSize: 11
                    color: "#FFFFFF"
                    background: Item {}
                    onEditingFinished: root.modelName = text
                }
            }

            Item { Layout.fillWidth: true }

            Rectangle {
                width: 24
                height: 24
                radius: 4
                color: clearMa.containsMouse ? "#2a2a4e" : "transparent"

                Text {
                    anchors.centerIn: parent
                    text: "✕"
                    color: "#FFFFFF"
                    opacity: 0.6
                    font.pixelSize: 11
                }

                MouseArea {
                    id: clearMa
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: messages.clear()
                }
            }
        }

        // ── Message list ─────────────────────────────────────────────
        ListView {
            id: msgList
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            spacing: 6
            model: messages

            onCountChanged: Qt.callLater(positionViewAtEnd)
            onContentHeightChanged: Qt.callLater(positionViewAtEnd)

            delegate: Item {
                required property string role
                required property string content

                width: msgList.width
                height: bubble.height + 8

                Rectangle {
                    id: bubble
                    anchors.right: role === "user" ? parent.right : undefined
                    anchors.left: role === "assistant" ? parent.left : undefined
                    anchors.top: parent.top
                    anchors.margins: 4
                    width: msgText.width + 24
                    height: msgText.height + 16
                    radius: 8
                    color: role === "user" ? "#3a3a7e" : "#1e1e3e"

                    Text {
                        id: msgText
                        x: 12
                        y: 8
                        // Max width = 85% of list width minus bubble padding
                        width: Math.min(implicitWidth, msgList.width * 0.85 - 24)
                        text: (role === "assistant" && content === "" && root.isStreaming)
                              ? "…" : content
                        color: "#FFFFFF"
                        opacity: role === "user" ? 1.0 : 0.88
                        font.family: "JetBrains Mono"
                        font.pixelSize: 12
                        wrapMode: Text.Wrap
                    }
                }
            }
        }

        // ── Input bar ────────────────────────────────────────────────
        Rectangle {
            Layout.fillWidth: true
            height: 42
            radius: 8
            color: "#1a1a2e"

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 10
                anchors.rightMargin: 8
                anchors.topMargin: 4
                anchors.bottomMargin: 4
                spacing: 6

                TextField {
                    id: inputField
                    Layout.fillWidth: true
                    placeholderText: "Envoyer un message…"
                    placeholderTextColor: "#60FFFFFF"
                    font.family: "JetBrains Mono"
                    font.pixelSize: 12
                    color: "#FFFFFF"
                    background: Item {}
                    enabled: !root.isStreaming
                    Keys.onReturnPressed: root.sendMessage()
                }

                Rectangle {
                    width: 28
                    height: 28
                    radius: 6
                    color: sendMa.containsMouse && !root.isStreaming ? "#4a4a8e" : "#2a2a4e"
                    opacity: root.isStreaming ? 0.4 : 1.0

                    Text {
                        anchors.centerIn: parent
                        text: root.isStreaming ? "…" : "↑"
                        color: "#FFFFFF"
                        font.family: "JetBrains Mono"
                        font.pixelSize: 14
                    }

                    MouseArea {
                        id: sendMa
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.sendMessage()
                    }
                }
            }
        }
    }
}
