{ pkgs, ... }:

let
  yamlFormat = pkgs.formats.yaml { };

  # Config goose déclarative. Écrit en lecture seule sous ~/.config/goose/config.yaml
  # via un symlink vers le store : `goose configure` ne pourra donc plus le modifier,
  # tout changement passe par ce fichier Nix.
  #
  # Provider : ollama local (aucune clé API). Modèle par défaut : qwen3:latest
  #   (tool-calling correct, ~5 Go → tient sur zola et gary).
  #   Alternative plus costaude si le GPU suit : "mistral-small:24b".
  gooseConfig = {
    GOOSE_PROVIDER = "ollama";
    GOOSE_MODEL = "qwen3:latest";
    OLLAMA_HOST = "localhost";
    # smart_approve : goose demande confirmation avant les actions à risque
    # (auto = tout auto, chat = jamais d'action). Défaut goose = smart_approve.
    GOOSE_MODE = "smart_approve";
    GOOSE_TELEMETRY_ENABLED = false;

    extensions = {
      developer = {
        enabled = true;
        type = "platform";
        name = "developer";
        description = "Write and edit files, and execute shell commands";
        display_name = "Developer";
        bundled = true;
        available_tools = [ ];
      };
      analyze = {
        enabled = true;
        type = "platform";
        name = "analyze";
        description = "Analyze code structure with tree-sitter: directory overviews, file details, symbol call graphs";
        display_name = "Analyze";
        bundled = true;
        available_tools = [ ];
      };
      todo = {
        enabled = true;
        type = "platform";
        name = "todo";
        description = "Enable a todo list for goose so it can keep track of what it is doing";
        display_name = "Todo";
        bundled = true;
        available_tools = [ ];
      };
      summon = {
        enabled = true;
        type = "platform";
        name = "summon";
        description = "Load knowledge and delegate tasks to subagents";
        display_name = "Summon";
        bundled = true;
        available_tools = [ ];
      };
      extensionmanager = {
        enabled = true;
        type = "platform";
        name = "Extension Manager";
        description = "Enable extension management tools for discovering, enabling, and disabling extensions";
        display_name = "Extension Manager";
        bundled = true;
        available_tools = [ ];
      };
      apps = {
        enabled = true;
        type = "platform";
        name = "apps";
        description = "Create and manage custom Goose apps through chat. Apps are HTML/CSS/JavaScript and run in sandboxed windows.";
        display_name = "Apps";
        bundled = true;
        available_tools = [ ];
      };
      tom = {
        enabled = true;
        type = "platform";
        name = "tom";
        description = "Inject custom context into every turn via GOOSE_MOIM_MESSAGE_TEXT and GOOSE_MOIM_MESSAGE_FILE environment variables";
        display_name = "Top Of Mind";
        bundled = true;
        available_tools = [ ];
      };
      chatrecall = {
        enabled = false;
        type = "platform";
        name = "chatrecall";
        description = "Search past conversations and load session summaries for contextual memory";
        display_name = "Chat Recall";
        bundled = true;
        available_tools = [ ];
      };
      summarize = {
        enabled = false;
        type = "platform";
        name = "summarize";
        description = "Load files/directories and get an LLM summary in a single call";
        display_name = "Summarize";
        bundled = true;
        available_tools = [ ];
      };
      code_execution = {
        enabled = false;
        type = "platform";
        name = "code_execution";
        description = "Goose will make extension calls through code execution, saving tokens";
        display_name = "Code Mode";
        bundled = true;
        available_tools = [ ];
      };
    };
  };
in
{
  home.packages = [ pkgs.goose-cli ];

  xdg.configFile."goose/config.yaml".source = yamlFormat.generate "goose-config.yaml" gooseConfig;
}
