import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

Item {
    id: root

    property string modelName: "llama3.2:3b"
    property bool isStreaming: false

    ListModel { id: messages }
    ListModel { id: availableModels }

    function fetchModels() {
        var xhr = new XMLHttpRequest();
        xhr.open("GET", "http://localhost:11434/api/tags");
        xhr.onreadystatechange = function() {
            if (xhr.readyState === 4 && xhr.status === 200) {
                try {
                    var data = JSON.parse(xhr.responseText);
                    availableModels.clear();
                    for (var i = 0; i < data.models.length; i++)
                        availableModels.append({ name: data.models[i].name });
                    // Select current model if present, else first
                    var found = false;
                    for (var j = 0; j < availableModels.count; j++) {
                        if (availableModels.get(j).name === root.modelName) {
                            modelCombo.currentIndex = j;
                            found = true;
                            break;
                        }
                    }
                    if (!found && availableModels.count > 0) {
                        modelCombo.currentIndex = 0;
                        root.modelName = availableModels.get(0).name;
                    }
                } catch (e) {}
            }
        };
        xhr.send();
    }

    Component.onCompleted: fetchModels()

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
                        } else if (obj.error) {
                            messages.setProperty(assistantIdx, "content",
                                "[Erreur Ollama : " + obj.error + "]");
                            gotChunk = true;
                        }
                    } catch (e) {}
                }
            }
            if (xhr.readyState === 4) {
                if (!gotChunk) {
                    var networkErr = xhr.status === 0
                        ? "impossible de joindre Ollama sur localhost:11434"
                        : "réponse inattendue (HTTP " + xhr.status + ")";
                    messages.setProperty(assistantIdx, "content",
                        "[Erreur : " + networkErr + "]");
                }
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

            ComboBox {
                id: modelCombo
                Layout.preferredWidth: 150
                Layout.preferredHeight: 24
                model: availableModels
                textRole: "name"
                enabled: !root.isStreaming
                onActivated: root.modelName = availableModels.get(currentIndex).name

                contentItem: Text {
                    leftPadding: 6
                    text: modelCombo.displayText
                    font.family: "JetBrains Mono"
                    font.pixelSize: 11
                    color: "#FFFFFF"
                    verticalAlignment: Text.AlignVCenter
                    elide: Text.ElideRight
                }

                background: Rectangle {
                    color: modelCombo.pressed ? "#2a2a5e" : "#1a1a2e"
                    radius: 4
                    border.color: "#3a3a6e"
                    border.width: 1
                }

                popup: Popup {
                    y: modelCombo.height + 2
                    width: modelCombo.width
                    implicitHeight: contentItem.implicitHeight
                    padding: 1

                    contentItem: ListView {
                        clip: true
                        implicitHeight: contentHeight
                        model: modelCombo.popup.visible ? modelCombo.delegateModel : null

                        ScrollIndicator.vertical: ScrollIndicator {}
                    }

                    background: Rectangle {
                        color: "#1a1a2e"
                        radius: 4
                        border.color: "#3a3a6e"
                        border.width: 1
                    }
                }

                delegate: ItemDelegate {
                    required property string name
                    required property int index
                    width: modelCombo.width
                    highlighted: modelCombo.highlightedIndex === index

                    contentItem: Text {
                        text: name
                        font.family: "JetBrains Mono"
                        font.pixelSize: 11
                        color: "#FFFFFF"
                        verticalAlignment: Text.AlignVCenter
                    }

                    background: Rectangle {
                        color: highlighted ? "#2a2a5e" : "transparent"
                    }
                }
            }

            // Refresh button
            Rectangle {
                width: 20
                height: 24
                radius: 4
                color: refreshMa.containsMouse ? "#2a2a4e" : "transparent"

                Text {
                    anchors.centerIn: parent
                    text: "⟳"
                    color: "#FFFFFF"
                    opacity: 0.6
                    font.pixelSize: 13
                }

                MouseArea {
                    id: refreshMa
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.fetchModels()
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
