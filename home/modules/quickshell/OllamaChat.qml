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

    // Internal context for Ollama (includes tool role messages not shown in UI)
    property var conversationContext: []

    Process {
        id: copyProcess
        command: ["wl-copy"]
        stdinEnabled: true
        onExited: running = false
    }

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
                } else if (data.startsWith("ERROR:")) {
                    console.warn("Voice assistant error:", data.substring(6));
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
        inputField.text = "";
        messages.append({ role: "user", content: "\uD83C\uDF99 " + text, msgType: "text" });
        root.conversationContext.push({ role: "user", content: text });
        root.pendingVoiceResponse = true;
        continueConversation();
    }

    property bool pendingVoiceResponse: false

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
                            // TTS if this was a voice-initiated message
                            if (root.pendingVoiceResponse && fullResponse !== "") {
                                root.speakText(fullResponse);
                                root.pendingVoiceResponse = false;
                            }
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

        // -- Header --
        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            Text {
                text: "// qwen3:latest"
                color: "#00FF88"
                opacity: 0.4
                font.family: "JetBrains Mono"
                font.pixelSize: 10
            }

            Item { Layout.fillWidth: true }

            // Voice status indicator
            Text {
                visible: root.voiceEnabled
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
                color: "#00FF88"
                font.pixelSize: 11
                opacity: voiceStatusAnim.running ? undefined : 0.6

                SequentialAnimation on opacity {
                    id: voiceStatusAnim
                    running: root.voiceStatus === "LISTENING"
                    loops: Animation.Infinite
                    NumberAnimation { to: 1.0; duration: 800 }
                    NumberAnimation { to: 0.3; duration: 800 }
                }
            }

            // Mic toggle
            Text {
                text: root.voiceEnabled ? "[mic:on]" : "[mic]"
                color: root.voiceEnabled ? "#00FF88" : "#444444"
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

            // Clear
            Text {
                text: "[clear]"
                color: clearMa.containsMouse ? "#FF6666" : "#444444"
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
                height: msgRow.height + 4

                Row {
                    id: msgRow
                    width: parent.width

                    Text {
                        id: prefixText
                        text: role === "user" ? "> " : (msgType === "action" ? "$ " : "  ")
                        color: role === "user" ? "#00FF88" : (msgType === "action" ? "#FFCC44" : "#444444")
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
                            if (role === "user") return "#00FF88";
                            if (msgType === "action") return "#FFCC44";
                            return "#CCCCCC";
                        }
                        selectionColor: "#00FF88"
                        selectedTextColor: "#000000"
                        font.family: "JetBrains Mono"
                        font.pixelSize: 12
                        wrapMode: TextEdit.Wrap
                    }

                    Text {
                        id: copyBtn
                        visible: role === "assistant" && content !== "" && !root.isStreaming
                        text: copyTimer.running ? "[copied]" : "[copy]"
                        color: copyMa.containsMouse ? "#00FF88" : "#333333"
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

        // -- Input bar --
        RowLayout {
            Layout.fillWidth: true
            spacing: 0

            Text {
                text: "> "
                color: root.isStreaming ? "#444444" : "#00FF88"
                font.family: "JetBrains Mono"
                font.pixelSize: 12
            }

            TextField {
                id: inputField
                Layout.fillWidth: true
                placeholderText: root.isStreaming ? "\u2026" : "message"
                placeholderTextColor: "#30FFFFFF"
                font.family: "JetBrains Mono"
                font.pixelSize: 12
                color: "#00FF88"
                background: Item {}
                enabled: !root.isStreaming
                Keys.onReturnPressed: root.sendMessage()
            }
        }
    }
}
