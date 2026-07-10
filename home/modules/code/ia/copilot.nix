{ pkgs, ... }:

{
  programs.github-copilot-cli = {
    enable = true;
    package = pkgs.github-copilot-cli;

    # Consume programs.mcp.servers (defined in ./mcp.nix) — Copilot CLI writes
    # them into ~/.copilot/mcp-config.json with the right shape.
    enableMcpIntegration = true;

    # Hook PreToolUse rtk : réécrit transparemment les commandes avant
    # exécution (ex: "git status" -> "rtk git status"). Deux clés car VS Code
    # Copilot Chat et Copilot CLI n'utilisent pas la même casse/schéma pour
    # le même fichier. Voir ./rtk.nix pour le package.
    # settings.hooks = {
    #   PreToolUse = [
    #     {
    #       type = "command";
    #       command = "rtk hook copilot";
    #       cwd = ".";
    #       timeout = 5;
    #     }
    #   ];
    #   preToolUse = [
    #     {
    #       type = "command";
    #       bash = "rtk hook copilot";
    #       powershell = "rtk hook copilot";
    #       cwd = ".";
    #       timeoutSec = 5;
    #     }
    #   ];
    # };
  };
}
