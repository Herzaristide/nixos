{ pkgs, ... }:

{
  programs.github-copilot-cli = {
    enable = true;
    package = pkgs.github-copilot-cli;

    # Réutilise programs.mcp.servers (défini dans ./mcp.nix) — écrit dans
    # ~/.copilot/mcp-config.json au bon format. Y compris codegraph, qui est
    # donc exposé à Copilot CLI comme à Claude Code.
    enableMcpIntegration = true;

    # Modèle par défaut. Copilot CLI réécrit settings.json quand on change de
    # modèle/thème à l'exécution : mutableSettings = true fusionne la valeur
    # déclarative dans un fichier inscriptible au lieu de le lier depuis le
    # store (un lien store serait remplacé au premier changement runtime).
    mutableSettings = true;
    settings.model = "claude-opus-5.5";
  };
}
