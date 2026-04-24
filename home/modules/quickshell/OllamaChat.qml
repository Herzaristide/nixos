import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell.Io
import Quickshell.Hyprland

Item {
    id: root

    property string modelName: "llama3.2:3b"
    property bool isStreaming: false

    property string systemPrompt: "Tu es un assistant IA intégré au bureau Linux (Hyprland/NixOS) de l'utilisateur. Tu peux exécuter des actions sur son système via les outils disponibles. Quand l'utilisateur te demande d'effectuer une action, utilise l'outil approprié. Réponds toujours en français."

    property var toolDefinitions: [
        {
            type: "function",
            "function": {
                name: "switch_workspace",
                description: "Switch to a specific workspace by number (1-5)",
                parameters: {
                    type: "object",
                    properties: {
                        workspace_id: { type: "integer", description: "Workspace number from 1 to 5" }
                    },
                    required: ["workspace_id"]
                }
            }
        },
        {
            type: "function",
            "function": {
                name: "open_application",
                description: "Open/launch an application by its command name (e.g. firefox, nautilus, kitty)",
                parameters: {
                    type: "object",
                    properties: {
                        command: { type: "string", description: "Application command to launch" }
                    },
                    required: ["command"]
                }
            }
        },
        {
            type: "function",
            "function": {
                name: "close_active_window",
                description: "Close the currently focused/active window",
                parameters: { type: "object", properties: {} }
            }
        },
        {
            type: "function",
            "function": {
                name: "move_window_to_workspace",
                description: "Move the currently active window to a specific workspace",
                parameters: {
                    type: "object",
                    properties: {
                        workspace_id: { type: "integer", description: "Target workspace number (1-5)" }
                    },
                    required: ["workspace_id"]
                }
            }
        },
        {
            type: "function",
            "function": {
                name: "toggle_fullscreen",
                description: "Toggle fullscreen mode for the currently active window",
                parameters: { type: "object", properties: {} }
            }
        },
        {
            type: "function",
            "function": {
                name: "focus_direction",
                description: "Move window focus in a direction (left, right, up, down)",
                parameters: {
                    type: "object",
                    properties: {
                        direction: { type: "string", description: "Direction: l (left), r (right), u (up), d (down)" }
                    },
                    required: ["direction"]
                }
            }
        },
        {
            type: "function",
            "function": {
                name: "set_volume",
                description: "Set the system audio volume to a percentage",
                parameters: {
                    type: "object",
                    properties: {
                        percent: { type: "integer", description: "Volume percentage (0-100)" }
                    },
                    required: ["percent"]
                }
            }
        },
        {
            type: "function",
            "function": {
                name: "set_brightness",
                description: "Set screen brightness to a percentage",
                parameters: {
                    type: "object",
                    properties: {
                        percent: { type: "integer", description: "Brightness percentage (0-100)" }
                    },
                    required: ["percent"]
                }
            }
        },
        {
            type: "function",
            "function": {
                name: "screenshot",
                description: "Take a screenshot (full screen, active window, or selected area)",
                parameters: {
                    type: "object",
                    properties: {
                        region: { type: "string", description: "Region to capture: screen, active, or area" }
                    },
                    required: ["region"]
                }
            }
        },
        {
            type: "function",
            "function": {
                name: "send_notification",
                description: "Send a desktop notification",
                parameters: {
                    type: "object",
                    properties: {
                        title: { type: "string", description: "Notification title" },
                        body: { type: "string", description: "Notification body text" }
                    },
                    required: ["title", "body"]
                }
            }
        },
        {
            type: "function",
            "function": {
                name: "get_system_info",
                description: "Get system information (CPU usage, memory usage, uptime, disk usage)",
                parameters: { type: "object", properties: {} }
            }
        },
        {
            type: "function",
            "function": {
                name: "list_windows",
                description: "List all open windows with their titles, classes and workspaces",
                parameters: { type: "object", properties: {} }
            }
        },
        {
            type: "function",
            "function": {
                name: "run_command",
                description: "Run an arbitrary shell command and return its output",
                parameters: {
                    type: "object",
                    properties: {
                        command: { type: "string", description: "Shell command to execute" }
                    },
                    required: ["command"]
                }
            }
        }
    ]

    ListModel { id: messages }
    ListModel { id: availableModels }

    // Internal context for Ollama (includes tool role messages not shown in UI)
    property var conversationContext: []

    Process {
        id: toolProcess

        property string pendingToolName: ""
        property int pendingAssistantIdx: -1
        property string stdoutBuffer: ""
        property string stderrBuffer: ""

        stdout: SplitParser {
            onRead: (data) => { toolProcess.stdoutBuffer += data + "\n" }
        }
        stderr: SplitParser {
            onRead: (data) => { toolProcess.stderrBuffer += data + "\n" }
        }

        onExited: (code, status) => {
            var result = stdoutBuffer.trim() || stderrBuffer.trim() || "(commande terminée, code: " + code + ")";
            stdoutBuffer = "";
            stderrBuffer = "";
            root.handleToolResult(pendingToolName, pendingAssistantIdx, result);
        }
    }

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

    function sendMessage() {
        var text = inputField.text.trim();
        if (text === "" || root.isStreaming) return;

        inputField.text = "";
        messages.append({ role: "user", content: text, msgType: "text" });

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
                                var actionText = "\u2699 " + formatToolAction(toolName, toolArgs);
                                messages.setProperty(assistantIdx, "content", actionText);
                                messages.setProperty(assistantIdx, "msgType", "action");

                                executeToolCall(toolName, toolArgs, assistantIdx);
                                return;
                            }

                            // Normal text response
                            root.conversationContext.push({ role: "assistant", content: fullResponse });
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
            tools: root.toolDefinitions,
            stream: true
        }));
    }

    function formatToolAction(name, args) {
        switch (name) {
            case "switch_workspace": return "Workspace → " + (args.workspace_id || "?");
            case "open_application": return "Ouvrir : " + (args.command || "?");
            case "close_active_window": return "Fermer la fenêtre active";
            case "move_window_to_workspace": return "Déplacer fenêtre → workspace " + (args.workspace_id || "?");
            case "toggle_fullscreen": return "Basculer plein écran";
            case "focus_direction": return "Focus → " + (args.direction || "?");
            case "set_volume": return "Volume → " + (args.percent || "?") + "%";
            case "set_brightness": return "Luminosité → " + (args.percent || "?") + "%";
            case "screenshot": return "Capture d'écran (" + (args.region || "screen") + ")";
            case "send_notification": return "Notification : " + (args.title || "");
            case "get_system_info": return "Infos système...";
            case "list_windows": return "Liste des fenêtres...";
            case "run_command": return "$ " + (args.command || "?");
            default: return name;
        }
    }

    function executeToolCall(name, args, assistantIdx) {
        var result = "";

        switch (name) {
            case "switch_workspace":
                Hyprland.dispatch("workspace " + args.workspace_id);
                result = "Workspace changé vers " + args.workspace_id;
                handleToolResult(name, assistantIdx, result);
                break;

            case "open_application":
                Hyprland.dispatch("exec " + args.command);
                result = "Application lancée : " + args.command;
                handleToolResult(name, assistantIdx, result);
                break;

            case "close_active_window":
                Hyprland.dispatch("killactive");
                result = "Fenêtre active fermée";
                handleToolResult(name, assistantIdx, result);
                break;

            case "move_window_to_workspace":
                Hyprland.dispatch("movetoworkspace " + args.workspace_id);
                result = "Fenêtre déplacée vers workspace " + args.workspace_id;
                handleToolResult(name, assistantIdx, result);
                break;

            case "toggle_fullscreen":
                Hyprland.dispatch("fullscreen 0");
                result = "Plein écran basculé";
                handleToolResult(name, assistantIdx, result);
                break;

            case "focus_direction":
                Hyprland.dispatch("movefocus " + args.direction);
                result = "Focus déplacé vers " + args.direction;
                handleToolResult(name, assistantIdx, result);
                break;

            case "set_volume":
                toolProcess.pendingToolName = name;
                toolProcess.pendingAssistantIdx = assistantIdx;
                var vol = Math.max(0, Math.min(100, args.percent)) / 100.0;
                toolProcess.command = ["wpctl", "set-volume", "@DEFAULT_AUDIO_SINK@", vol.toString()];
                toolProcess.running = true;
                break;

            case "set_brightness":
                toolProcess.pendingToolName = name;
                toolProcess.pendingAssistantIdx = assistantIdx;
                toolProcess.command = ["brightnessctl", "set", args.percent + "%"];
                toolProcess.running = true;
                break;

            case "screenshot":
                toolProcess.pendingToolName = name;
                toolProcess.pendingAssistantIdx = assistantIdx;
                var region = args.region || "screen";
                toolProcess.command = ["grimblast", "copy", region];
                toolProcess.running = true;
                break;

            case "send_notification":
                toolProcess.pendingToolName = name;
                toolProcess.pendingAssistantIdx = assistantIdx;
                toolProcess.command = ["notify-send", args.title || "", args.body || ""];
                toolProcess.running = true;
                break;

            case "get_system_info":
                toolProcess.pendingToolName = name;
                toolProcess.pendingAssistantIdx = assistantIdx;
                toolProcess.command = ["sh", "-c",
                    "echo '=== CPU ===' && head -1 /proc/stat && echo '=== Memory ===' && free -h && echo '=== Uptime ===' && uptime && echo '=== Disk ===' && df -h /"];
                toolProcess.running = true;
                break;

            case "list_windows":
                toolProcess.pendingToolName = name;
                toolProcess.pendingAssistantIdx = assistantIdx;
                toolProcess.command = ["hyprctl", "clients", "-j"];
                toolProcess.running = true;
                break;

            case "run_command":
                toolProcess.pendingToolName = name;
                toolProcess.pendingAssistantIdx = assistantIdx;
                toolProcess.command = ["sh", "-c", args.command];
                toolProcess.running = true;
                break;

            default:
                result = "Outil inconnu : " + name;
                handleToolResult(name, assistantIdx, result);
                break;
        }
    }

    function handleToolResult(toolName, assistantIdx, result) {
        // Truncate very long results
        if (result.length > 2000)
            result = result.substring(0, 2000) + "\n... (tronqué)";

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

        // -- Header: model selector + clear --
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
                    text: "\u27F3"
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
                    text: "\u2715"
                    color: "#FFFFFF"
                    opacity: 0.6
                    font.pixelSize: 11
                }

                MouseArea {
                    id: clearMa
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.clearChat()
                }
            }
        }

        // -- Message list --
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
                required property string msgType

                width: msgList.width
                height: bubble.height + 8

                Rectangle {
                    id: bubble
                    anchors.right: role === "user" ? parent.right : undefined
                    anchors.left: role !== "user" ? parent.left : undefined
                    anchors.top: parent.top
                    anchors.margins: 4
                    width: msgText.width + 24
                    height: msgText.height + 16
                    radius: 8
                    color: {
                        if (msgType === "action") return "#1e3e2e";
                        if (role === "user") return "#3a3a7e";
                        return "#1e1e3e";
                    }
                    border.color: msgType === "action" ? "#2e5e3e" : "transparent"
                    border.width: msgType === "action" ? 1 : 0

                    Text {
                        id: msgText
                        x: 12
                        y: 8
                        width: Math.min(implicitWidth, msgList.width * 0.85 - 24)
                        text: (role === "assistant" && content === "" && root.isStreaming)
                              ? "\u2026" : content
                        color: msgType === "action" ? "#88DDAA" : "#FFFFFF"
                        opacity: {
                            if (msgType === "action") return 0.95;
                            if (role === "user") return 1.0;
                            return 0.88;
                        }
                        font.family: "JetBrains Mono"
                        font.pixelSize: msgType === "action" ? 11 : 12
                        wrapMode: Text.Wrap
                    }
                }
            }
        }

        // -- Input bar --
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
                    placeholderText: "Envoyer un message\u2026"
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
                        text: root.isStreaming ? "\u2026" : "\u2191"
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
