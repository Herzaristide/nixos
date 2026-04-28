import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell.Io
import Quickshell.Hyprland

Item {
    id: root

    property string modelName: "qwen3:latest"
    property bool isStreaming: false
    property bool voiceEnabled: false
    property string voiceStatus: "OFF"

    property string systemPrompt: "Tu es un assistant IA intégré au bureau Linux (Hyprland/NixOS) de l'utilisateur. Tu peux exécuter des actions sur son système via les outils disponibles. Tu as aussi accès à des outils NixOS pour reconstruire le système, mettre à jour le flake, gérer les générations et le garbage collection. La configuration NixOS se trouve dans /etc/nixos. Tu peux démarrer et arrêter des enregistrements audio du microphone vers /records/ (start_recording / stop_recording). Tu peux ouvrir des URLs et faire des recherches web dans le navigateur par défaut (Zen) avec l'outil open_url : utilise-le quand l'utilisateur demande d'ouvrir un site, chercher une recette, regarder YouTube, trouver des informations en ligne, etc. Quand l'utilisateur te demande d'effectuer une action, utilise l'outil approprié. Réponds toujours en français."

    // Tool definitions and execution are in OllamaTools.qml
    OllamaTools {
        id: llmTools
        onToolResult: (toolName, assistantIdx, result) => handleToolResult(toolName, assistantIdx, result)
    }


    ListModel { id: messages }

    // Internal context for Ollama (includes tool role messages not shown in UI)
    property var conversationContext: []

    Process {
        id: copyProcess
        command: ["wl-copy"]
        stdinEnabled: true
        onExited: running = false
    }

    // ── Voice assistant process ────────────────────────────────
    Process {
        id: voiceProcess
        command: ["bash", "-c", "exec $HOME/.config/quickshell/voice-assistant.sh"]
        running: root.voiceEnabled
        stdinEnabled: true

        stdout: SplitParser {
            onRead: (data) => {
                if (data.startsWith("STATUS:")) {
                    root.voiceStatus = data.substring(7);
                } else if (data.startsWith("TRANSCRIPT:")) {
                    var text = data.substring(11).trim();
                    if (text !== "") {
                        root.voiceSubmit(text);
                    }
                } else if (data.startsWith("DEBUG:")) {
                    // Whisper heard this while waiting for the wake word.
                    // Logged so you can tune WAKE_WORD_REGEX to your voice.
                    console.log("[wake-stream]", data.substring(6));
                } else if (data.startsWith("ERROR:")) {
                    var errMsg = data.substring(6);
                    console.warn("Voice assistant error:", errMsg);
                    // Show error in chat so the user knows what went wrong
                    messages.append({ role: "assistant", content: "⚠️ Voix : " + errMsg, msgType: "text" });
                }
            }
        }
        stderr: SplitParser {
            onRead: (data) => { console.warn("voice-assistant:", data) }
        }

        onExited: (code, status) => {
            if (root.voiceEnabled) {
                root.voiceStatus = "ERROR";
                root.voiceEnabled = false;
            }
        }
    }

    function speakText(text) {
        if (!root.voiceEnabled) return;
        // Send TTS request to voice assistant via stdin
        voiceProcess.write("SPEAK:" + text + "\n");
    }

    function voiceSubmit(text) {
        if (root.isStreaming) return;
        // Write transcript into the input field so the user sees it,
        // then re-use the normal sendMessage() path.
        inputField.text = text;
        root.pendingVoiceResponse = true;
        sendMessage();
    }

    property bool pendingVoiceResponse: false

    property bool ttsEnabled: false
    property var ttsPendingQueue: []

    // ── TTS process: piper → aplay, indépendant du mode voix ───────
    // Le texte est passé via la commande shell (pas via stdin) pour éviter
    // que closeStdin() bloque les appels suivants au redémarrage du process.
    Process {
        id: ttsProcess
        running: false
        onExited: {
            running = false;
            if (root.ttsPendingQueue.length > 0) {
                var nextText = root.ttsPendingQueue.shift();
                Qt.callLater(function() { root._ttsRun(nextText); });
            }
        }
    }

    function _ttsRun(text) {
        // Single-quote escaping : remplace ' par '\'' (safe pour tout texte arbitraire)
        var q = "'" + text.replace(/'/g, "'\\''") + "'";
        ttsProcess.command = [
            "bash", "-c",
            "printf '%s' " + q + " | piper -m \"$HOME/.local/share/piper/fr_FR-siwis-medium.onnx\" --length-scale 0.75 --output-raw 2>/dev/null | " +
            "aplay -r 22050 -f S16_LE -t raw -q 2>/dev/null"
        ];
        ttsProcess.running = true;
    }

    // Lit le texte d'une réponse IA via piper (nettoyage markdown basique).
    function speakResponse(text) {
        if (!root.ttsEnabled) return;
        var clean = text
            .replace(/\*{1,2}([^*]*)\*{1,2}/g, "$1")
            .replace(/`[^`]*`/g, "")
            .replace(/#{1,6}\s*/g, "")
            .replace(/\n+/g, " ")
            .trim();
        if (clean === "") return;
        if (ttsProcess.running)
            root.ttsPendingQueue.push(clean);
        else
            root._ttsRun(clean);
    }

    function sendMessage() {
        var text = inputField.text.trim();
        if (text === "" || root.isStreaming) return;

        inputField.text = "";
        // Prefix voice-initiated messages with a mic icon
        var displayText = root.pendingVoiceResponse ? "\uD83C\uDF99 " + text : text;
        messages.append({ role: "user", content: displayText, msgType: "text" });

        // Add to internal context
        root.conversationContext.push({ role: "user", content: text });

        continueConversation();
    }

    function continueConversation() {
        messages.append({ role: "assistant", content: "", msgType: "text" });
        var assistantIdx = messages.count - 1;

        // Build full context with system prompt
        var ctx = [{ role: "system", content: root.systemPrompt }];
        for (var i = 0; i < root.conversationContext.length; i++)
            ctx.push(root.conversationContext[i]);

        root.isStreaming = true;
        var lastPos = 0;
        var gotChunk = false;
        var fullResponse = "";
        var pendingToolCalls = [];

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
                        // Accumulate text content
                        if (obj.message && typeof obj.message.content === "string" && obj.message.content !== "") {
                            var cur = messages.get(assistantIdx).content;
                            messages.setProperty(assistantIdx, "content", cur + obj.message.content);
                            fullResponse += obj.message.content;
                            gotChunk = true;
                        }
                        // Accumulate tool calls from ANY chunk (they arrive in done:false chunks)
                        if (obj.message && obj.message.tool_calls && obj.message.tool_calls.length > 0) {
                            for (var t = 0; t < obj.message.tool_calls.length; t++)
                                pendingToolCalls.push(obj.message.tool_calls[t]);
                            gotChunk = true;
                        }
                        if (obj.error) {
                            messages.setProperty(assistantIdx, "content",
                                "[Erreur Ollama : " + obj.error + "]");
                            gotChunk = true;
                        }
                        // When stream is done, process accumulated tool calls
                        if (obj.done === true) {
                            root.isStreaming = false;

                            if (pendingToolCalls.length > 0) {
                                // Add assistant message with tool_calls to context
                                root.conversationContext.push({
                                    role: "assistant",
                                    content: fullResponse,
                                    tool_calls: pendingToolCalls
                                });

                                // Process the first tool call
                                var tc = pendingToolCalls[0];
                                var fn = tc["function"];
                                var toolName = fn.name;
                                var toolArgs = fn.arguments || {};

                                // Show action bubble
                                var actionText = "\u2699 " + llmTools.formatToolAction(toolName, toolArgs);
                                messages.setProperty(assistantIdx, "content", actionText);
                                messages.setProperty(assistantIdx, "msgType", "action");

                                llmTools.executeToolCall(toolName, toolArgs, assistantIdx);
                                return;
                            }

                            // Normal text response
                            root.conversationContext.push({ role: "assistant", content: fullResponse });
                            // TTS : mode global lit toutes les réponses ; mode voix lit les réponses initiées par micro
                            if (root.ttsEnabled && fullResponse !== "") {
                                root.speakResponse(fullResponse);
                            } else if (root.pendingVoiceResponse && fullResponse !== "") {
                                root.speakText(fullResponse);
                            }
                            root.pendingVoiceResponse = false;
                            return;
                        }
                    } catch (e) {}
                }
            }
            if (xhr.readyState === 4 && !gotChunk) {
                var networkErr = xhr.status === 0
                    ? "impossible de joindre Ollama sur localhost:11434"
                    : "réponse inattendue (HTTP " + xhr.status + ")";
                messages.setProperty(assistantIdx, "content",
                    "[Erreur : " + networkErr + "]");
                root.isStreaming = false;
            }
        };

        xhr.send(JSON.stringify({
            model: root.modelName,
            messages: ctx,
            tools: llmTools.toolDefinitions,
            stream: true
        }));
    }

    function handleToolResult(toolName, assistantIdx, result) {
        // Truncate very long results
        if (result.length > 2000)
            result = result.substring(0, 2000) + "\n... (tronqué)";

        // For screenshots, insert an image bubble in the chat
        if (toolName === "screenshot") {
            var screenshotPath = result.trim();
            if (screenshotPath !== "")
                messages.append({ role: "assistant", content: screenshotPath, msgType: "screenshot" });
        }

        // Add tool result to context
        root.conversationContext.push({ role: "tool", content: result });

        // Continue conversation so the AI can respond with the result
        continueConversation();
    }

    function clearChat() {
        messages.clear();
        root.conversationContext = [];
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 8
        spacing: 6

        // -- Header: voice status only --
        Text {
            visible: root.voiceEnabled
            Layout.alignment: Qt.AlignRight
            text: {
                switch (root.voiceStatus) {
                    case "LISTENING": return "\uD83D\uDD0A";
                    case "TRIGGERED": return "\uD83C\uDFA4";
                    case "PROCESSING": return "\u2699";
                    case "SPEAKING": return "\uD83D\uDD0A";
                    case "DOWNLOADING_MODEL": return "\u2B07";
                    case "DOWNLOADING_VOICE": return "\u2B07";
                    default: return "\u23F3";
                }
            }
            color: Theme.accentColor
            font.pixelSize: 11
            opacity: 0.6

            SequentialAnimation on opacity {
                id: voiceStatusAnim
                running: root.voiceStatus === "LISTENING"
                loops: Animation.Infinite
                NumberAnimation { to: 1.0; duration: 800 }
                NumberAnimation { to: 0.3; duration: 800 }
                onStopped: parent.opacity = 0.6
            }
        }

        // -- Message list --
        ListView {
            id: msgList
            Layout.fillWidth: true
            Layout.fillHeight: true
            visible: messages.count > 0
            clip: true
            spacing: 6
            model: messages

            property bool userScrolledUp: false

            function scrollToEndIfNeeded() {
                if (!userScrolledUp)
                    positionViewAtEnd();
            }

            onCountChanged: {
                userScrolledUp = false;
                Qt.callLater(positionViewAtEnd);
            }
            onContentHeightChanged: Qt.callLater(scrollToEndIfNeeded)
            onDragStarted: userScrolledUp = true
            onFlickStarted: userScrolledUp = true
            onMovementStarted: userScrolledUp = true
            onAtYEndChanged: {
                if (atYEnd)
                    userScrolledUp = false;
            }

            delegate: Item {
                required property string role
                required property string content
                required property string msgType

                width: msgList.width
                height: msgType === "screenshot" ? screenshotCol.height + 4 : msgRow.height + 4

                // Screenshot bubble
                Column {
                    id: screenshotCol
                    visible: msgType === "screenshot"
                    width: parent.width
                    spacing: 4

                    Text {
                        text: "\uD83D\uDCF7 " + content
                        color: "#666666"
                        font.family: "JetBrains Mono"
                        font.pixelSize: 10
                        wrapMode: Text.WrapAnywhere
                        width: parent.width
                    }

                    Image {
                        id: screenshotImg
                        source: msgType === "screenshot" ? "file://" + content : ""
                        width: parent.width
                        height: status === Image.Ready
                                ? Math.min(width * sourceSize.height / sourceSize.width, 300)
                                : 50
                        fillMode: Image.PreserveAspectFit
                        smooth: true
                        cache: false
                    }
                }

                Row {
                    id: msgRow
                    visible: msgType !== "screenshot"
                    width: parent.width

                    Text {
                        id: prefixText
                        text: role === "user" ? "> " : (msgType === "action" ? "$ " : "  ")
                        color: role === "user" ? Theme.accentColor : (msgType === "action" ? "#FFCC44" : Theme.textInactive)
                        font.family: "JetBrains Mono"
                        font.pixelSize: 12
                    }

                    TextEdit {
                        id: msgBodyText
                        width: msgRow.width - prefixText.implicitWidth - (copyBtn.visible ? copyBtn.implicitWidth + 6 : 0)
                        readOnly: true
                        selectByMouse: true
                        text: (role === "assistant" && content === "" && root.isStreaming)
                              ? "\u258B" : content
                        color: {
                            if (role === "user") return Theme.accentColor;
                            if (msgType === "action") return "#FFCC44";
                            return Theme.textBody;
                        }
                        selectionColor: Theme.accentColor
                        selectedTextColor: Theme.selectedTextColor
                        font.family: "JetBrains Mono"
                        font.pixelSize: 12
                        wrapMode: TextEdit.Wrap
                    }

                    Text {
                        id: copyBtn
                        visible: role === "assistant" && content !== "" && !root.isStreaming
                        text: copyTimer.running ? "[copied]" : "[copy]"
                        color: copyMa.containsMouse ? Theme.accentColor : Theme.textSubtle
                        font.family: "JetBrains Mono"
                        font.pixelSize: 10
                        leftPadding: 6

                        MouseArea {
                            id: copyMa
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                copyProcess.running = false;
                                copyProcess.running = true;
                                copyProcess.write(content);
                                copyProcess.closeStdin();
                                copyTimer.restart();
                            }
                        }

                        Timer {
                            id: copyTimer
                            interval: 2000
                        }
                    }
                }
            }
        }

        // Spacer: centers input when conversation is empty
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true
            visible: messages.count === 0
        }

        // -- Input bar --
        RowLayout {
            Layout.fillWidth: true
            Layout.minimumHeight: 28
            spacing: 0
            clip: true

            Text {
                text: "> "
                color: root.isStreaming ? Theme.textInactive : Theme.accentColor
                font.family: "JetBrains Mono"
                font.pixelSize: 12
                Layout.alignment: Qt.AlignTop
                topPadding: 4
            }

            ScrollView {
                Layout.fillWidth: true
                Layout.minimumHeight: 28
                Layout.maximumHeight: 120
                ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
                ScrollBar.vertical.policy: ScrollBar.AsNeeded
                clip: true

                TextArea {
                    id: inputField
                    wrapMode: TextArea.Wrap
                    placeholderText: root.isStreaming ? "\u2026" : "message"
                    placeholderTextColor: Theme.placeholderColor
                    font.family: "JetBrains Mono"
                    font.pixelSize: 12
                    color: Theme.accentColor
                    background: Item {}
                    enabled: !root.isStreaming
                    topPadding: 4
                    bottomPadding: 4
                    leftPadding: 0
                    rightPadding: 0
                    Keys.onReturnPressed: (event) => {
                        if (event.modifiers & Qt.ShiftModifier) {
                            // Shift+Enter = line break
                            insert(cursorPosition, "\n");
                        } else {
                            root.sendMessage();
                        }
                    }
                }
            }
        }

        // -- Bottom controls --
        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            // Model selector styled as "// model"
            Text {
                text: "// "
                color: Theme.accentColor
                opacity: 0.4
                font.family: "JetBrains Mono"
                font.pixelSize: 10
                verticalAlignment: Text.AlignVCenter
                height: modelCombo.height
            }

            ComboBox {
                id: modelCombo
                editable: true
                model: [
                    "qwen3:latest",
                    "qwen3:8b",
                    "llama3.2:latest",
                    "llama3.1:latest",
                    "mistral:latest",
                    "gemma3:latest",
                    "deepseek-r1:latest",
                    "phi4:latest"
                ]
                currentIndex: 0
                implicitWidth: 130
                implicitHeight: 18

                onAccepted: {
                    var v = editText.trim();
                    if (v !== "") root.modelName = v;
                }
                onActivated: (idx) => {
                    root.modelName = model[idx];
                }

                Component.onCompleted: {
                    var idx = find(root.modelName);
                    currentIndex = idx >= 0 ? idx : 0;
                    editText = root.modelName;
                }

                contentItem: TextInput {
                    text: modelCombo.editText
                    font.family: "JetBrains Mono"
                    font.pixelSize: 10
                    color: Theme.accentColor
                    opacity: 0.4
                    verticalAlignment: TextInput.AlignVCenter
                    leftPadding: 0
                    rightPadding: modelCombo.indicator.width + 2
                    selectByMouse: true
                    onTextEdited: modelCombo.editText = text
                }

                indicator: Text {
                    x: modelCombo.width - width
                    y: (modelCombo.height - height) / 2
                    text: "\u25BE"
                    color: Theme.accentColor
                    opacity: modelCombo.hovered ? 0.7 : 0.3
                    font.family: "JetBrains Mono"
                    font.pixelSize: 10
                }

                background: Item {}

                popup: Popup {
                    y: modelCombo.height - height
                    width: modelCombo.width + 40
                    padding: 1

                    background: Rectangle {
                        color: "#0d0d0d"
                        border.color: Theme.accentColor
                        border.width: 1
                        opacity: 0.97
                    }

                    contentItem: ListView {
                        clip: true
                        implicitHeight: contentHeight
                        model: modelCombo.popup.visible ? modelCombo.delegateModel : null
                        ScrollIndicator.vertical: ScrollIndicator {}
                    }
                }

                delegate: ItemDelegate {
                    required property string modelData
                    required property int index
                    width: modelCombo.popup.width - 2
                    height: 20
                    padding: 0
                    leftPadding: 6

                    contentItem: Text {
                        text: modelData
                        font.family: "JetBrains Mono"
                        font.pixelSize: 10
                        color: modelCombo.highlightedIndex === index ? Theme.selectedTextColor : Theme.accentColor
                        opacity: modelCombo.highlightedIndex === index ? 1.0 : 0.6
                        verticalAlignment: Text.AlignVCenter
                    }

                    background: Rectangle {
                        color: modelCombo.highlightedIndex === index ? Theme.accentColor : "transparent"
                    }
                }
            }

            Item { Layout.fillWidth: true }

            // Mic toggle
            Text {
                text: root.voiceEnabled ? "[mic:on]" : "[mic]"
                color: root.voiceEnabled ? Theme.accentColor : Theme.textInactive
                font.family: "JetBrains Mono"
                font.pixelSize: 10
                opacity: micMa.containsMouse ? 1.0 : 0.7

                MouseArea {
                    id: micMa
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        root.voiceEnabled = !root.voiceEnabled;
                        if (!root.voiceEnabled)
                            root.voiceStatus = "OFF";
                    }
                }
            }

            // TTS toggle
            Text {
                text: root.ttsEnabled ? "[tts:on]" : "[tts]"
                color: root.ttsEnabled ? Theme.accentColor : Theme.textInactive
                font.family: "JetBrains Mono"
                font.pixelSize: 10
                opacity: ttsMa.containsMouse ? 1.0 : 0.7

                MouseArea {
                    id: ttsMa
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.ttsEnabled = !root.ttsEnabled
                }
            }

            // Clear
            Text {
                text: "[clear]"
                color: clearMa.containsMouse ? "#FF6666" : Theme.textInactive
                font.family: "JetBrains Mono"
                font.pixelSize: 10

                MouseArea {
                    id: clearMa
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.clearChat()
                }
            }
        }

        // Spacer: balances centering when conversation is empty
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true
            visible: messages.count === 0
        }
    }
}
