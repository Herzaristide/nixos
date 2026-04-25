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

    property string systemPrompt: "Tu es un assistant IA intégré au bureau Linux (Hyprland/NixOS) de l'utilisateur. Tu peux exécuter des actions sur son système via les outils disponibles. Tu as aussi accès à des outils NixOS pour reconstruire le système, mettre à jour le flake, gérer les générations et le garbage collection. La configuration NixOS se trouve dans /etc/nixos. Tu peux démarrer et arrêter des enregistrements audio du microphone vers /records/ (start_recording / stop_recording). Quand l'utilisateur te demande d'effectuer une action, utilise l'outil approprié. Réponds toujours en français."

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
        },
        {
            type: "function",
            "function": {
                name: "nixos_rebuild",
                description: "Rebuild the NixOS system configuration from /etc/nixos. Action can be: switch (apply immediately, default), boot (apply on next reboot), test (apply temporarily without making permanent). Requires sudo.",
                parameters: {
                    type: "object",
                    properties: {
                        action: { type: "string", description: "switch (default), boot, or test" }
                    }
                }
            }
        },
        {
            type: "function",
            "function": {
                name: "nix_flake_update",
                description: "Update all flake inputs (nixpkgs, home-manager, DMS, etc.) in the NixOS configuration",
                parameters: { type: "object", properties: {} }
            }
        },
        {
            type: "function",
            "function": {
                name: "nix_flake_check",
                description: "Check the NixOS flake configuration for errors without building anything",
                parameters: { type: "object", properties: {} }
            }
        },
        {
            type: "function",
            "function": {
                name: "nix_gc",
                description: "Run Nix garbage collection to free disk space. If delete_old is true, deletes all old system generations first (more aggressive cleanup).",
                parameters: {
                    type: "object",
                    properties: {
                        delete_old: { type: "boolean", description: "Delete all old generations before GC (sudo nix-collect-garbage -d)" }
                    }
                }
            }
        },
        {
            type: "function",
            "function": {
                name: "nix_list_generations",
                description: "List all NixOS system generations with their dates, to see available rollback points",
                parameters: { type: "object", properties: {} }
            }
        },
        {
            type: "function",
            "function": {
                name: "nixos_rollback",
                description: "Rollback to the previous NixOS generation (undo last rebuild)",
                parameters: { type: "object", properties: {} }
            }
        },
        {
            type: "function",
            "function": {
                name: "start_recording",
                description: "Start recording microphone input to a WAV file in /records/. Optionally specify a filename (without path or extension).",
                parameters: {
                    type: "object",
                    properties: {
                        filename: { type: "string", description: "Optional filename without extension. Defaults to a timestamp-based name like rec_2026-04-25T14-30-00." }
                    }
                }
            }
        },
        {
            type: "function",
            "function": {
                name: "stop_recording",
                description: "Stop the current microphone recording and save the WAV file to /records/",
                parameters: { type: "object", properties: {} }
            }
        },
        {
            type: "function",
            "function": {
                name: "set_accent_color",
                description: "Change the desktop accent color used by Hyprland window borders, the shell bar, and terminal colors. Accepts a hex color (#rrggbb) or a preset name: nixos (#5277c3), nixos-light (#7ebae4), teal (#44aa88), coral (#cc5544), amber (#ccaa44), purple (#7755cc).",
                parameters: {
                    type: "object",
                    properties: {
                        color: { type: "string", description: "Hex color (#rrggbb) or preset name: nixos, nixos-light, teal, coral, amber, purple" }
                    },
                    required: ["color"]
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

    // ── Audio recorder process ────────────────────────────────
    Process {
        id: recordProcess
        property string currentFile: ""
        property string pendingToolName: ""
        property int pendingAssistantIdx: -1

        stdout: SplitParser { onRead: (data) => {} }
        stderr: SplitParser { onRead: (data) => {} }

        onExited: (code, status) => {
            if (pendingAssistantIdx >= 0) {
                root.handleToolResult(pendingToolName, pendingAssistantIdx,
                    "Enregistrement sauvegardé : " + currentFile);
                pendingAssistantIdx = -1;
            }
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
            case "nixos_rebuild": return "nixos-rebuild " + (args.action || "switch") + " --flake .#$(hostname)";
            case "nix_flake_update": return "nix flake update...";
            case "nix_flake_check": return "nix flake check...";
            case "nix_gc": return args.delete_old ? "nix-collect-garbage -d (toutes générations)" : "nix-collect-garbage";
            case "nix_list_generations": return "nixos-rebuild list-generations";
            case "nixos_rollback": return "nixos-rebuild switch --rollback";
            case "start_recording": return "\uD83C\uDF99 Enregistrement \u2192 /records/" + (args.filename || "rec_...") + ".wav";
            case "stop_recording": return "\u23F9 Arr\u00EAt enregistrement";
            case "set_accent_color": return "\uD83C\uDFA8 Couleur d'accent \u2192 " + (args.color || "?");
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
                var ts = Qt.formatDateTime(new Date(), "yyyyMMdd_HHmmss");
                var savePath = "/tmp/screenshot-" + ts + ".png";
                toolProcess.command = ["sh", "-c",
                    "grimblast copysave " + region + " '" + savePath + "' >/dev/null 2>&1 && echo '" + savePath + "'"];
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

            case "nixos_rebuild":
                toolProcess.pendingToolName = name;
                toolProcess.pendingAssistantIdx = assistantIdx;
                var rebuildAction = args.action || "switch";
                toolProcess.command = ["sh", "-c",
                    "cd /etc/nixos && sudo nixos-rebuild " + rebuildAction + " --flake .#$(hostname) 2>&1"];
                toolProcess.running = true;
                break;

            case "nix_flake_update":
                toolProcess.pendingToolName = name;
                toolProcess.pendingAssistantIdx = assistantIdx;
                toolProcess.command = ["sh", "-c", "cd /etc/nixos && nix flake update 2>&1"];
                toolProcess.running = true;
                break;

            case "nix_flake_check":
                toolProcess.pendingToolName = name;
                toolProcess.pendingAssistantIdx = assistantIdx;
                toolProcess.command = ["sh", "-c", "cd /etc/nixos && nix flake check 2>&1"];
                toolProcess.running = true;
                break;

            case "nix_gc":
                toolProcess.pendingToolName = name;
                toolProcess.pendingAssistantIdx = assistantIdx;
                if (args.delete_old)
                    toolProcess.command = ["sh", "-c", "sudo nix-collect-garbage -d 2>&1"];
                else
                    toolProcess.command = ["sh", "-c", "nix-collect-garbage 2>&1"];
                toolProcess.running = true;
                break;

            case "nix_list_generations":
                toolProcess.pendingToolName = name;
                toolProcess.pendingAssistantIdx = assistantIdx;
                toolProcess.command = ["nixos-rebuild", "list-generations"];
                toolProcess.running = true;
                break;

            case "nixos_rollback":
                toolProcess.pendingToolName = name;
                toolProcess.pendingAssistantIdx = assistantIdx;
                toolProcess.command = ["sh", "-c", "sudo nixos-rebuild switch --rollback 2>&1"];
                toolProcess.running = true;
                break;

            case "start_recording": {
                if (recordProcess.running) {
                    handleToolResult(name, assistantIdx, "Un enregistrement est déjà en cours : " + recordProcess.currentFile);
                    break;
                }
                var now = new Date();
                var pad = function(n) { return String(n).padStart(2, "0"); };
                var ts = now.getFullYear() + "-" + pad(now.getMonth()+1) + "-" + pad(now.getDate()) +
                         "T" + pad(now.getHours()) + "-" + pad(now.getMinutes()) + "-" + pad(now.getSeconds());
                var fname = (args.filename && args.filename.trim() !== "") ? args.filename.trim() : ("rec_" + ts);
                var outPath = "/records/" + fname + ".wav";
                recordProcess.currentFile = outPath;
                recordProcess.command = ["sh", "-c", "mkdir -p /records && arecord -f cd -t wav " + outPath];
                recordProcess.running = true;
                handleToolResult(name, assistantIdx, "Enregistrement démarré : " + outPath);
                break;
            }

            case "stop_recording":
                if (!recordProcess.running) {
                    handleToolResult(name, assistantIdx, "Aucun enregistrement en cours.");
                    break;
                }
                recordProcess.pendingToolName = name;
                recordProcess.pendingAssistantIdx = assistantIdx;
                recordProcess.running = false;
                break;

            case "set_accent_color": {
                var colorInput = (args.color || "").trim().toLowerCase();
                var presetMap = {
                    "nixos":       "#5277c3",
                    "nixos-light": "#7ebae4",
                    "teal":        "#44aa88",
                    "coral":       "#cc5544",
                    "amber":       "#ccaa44",
                    "purple":      "#7755cc"
                };
                var hexColor = presetMap[colorInput] || colorInput;
                if (!/^#[0-9a-f]{6}$/.test(hexColor)) {
                    handleToolResult(name, assistantIdx, "Couleur invalide : '" + args.color + "'. Utilise #rrggbb ou un nom : nixos, nixos-light, teal, coral, amber, purple.");
                    break;
                }
                Theme.setAccentColor(hexColor);
                handleToolResult(name, assistantIdx, "Couleur d'accent changée en " + hexColor);
                break;
            }

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

        // -- Header --
        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            Text {
                text: "// qwen3:latest"
                color: Theme.accentColor
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

            // Mic toggle
            Text {
                text: root.voiceEnabled ? "[mic:on]" : "[mic]"
                color: root.voiceEnabled ? Theme.accentColor : "#444444"
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
                        color: role === "user" ? Theme.accentColor : (msgType === "action" ? "#FFCC44" : "#444444")
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
                            return "#CCCCCC";
                        }
                        selectionColor: Theme.accentColor
                        selectedTextColor: "#000000"
                        font.family: "JetBrains Mono"
                        font.pixelSize: 12
                        wrapMode: TextEdit.Wrap
                    }

                    Text {
                        id: copyBtn
                        visible: role === "assistant" && content !== "" && !root.isStreaming
                        text: copyTimer.running ? "[copied]" : "[copy]"
                        color: copyMa.containsMouse ? Theme.accentColor : "#333333"
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
                color: root.isStreaming ? "#444444" : Theme.accentColor
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
                color: Theme.accentColor
                background: Item {}
                enabled: !root.isStreaming
                Keys.onReturnPressed: root.sendMessage()
            }
        }
    }
}
