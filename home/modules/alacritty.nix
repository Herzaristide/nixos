{ config, ... }:

{
  # Config statique gérée déclarativement par home-manager.  Les couleurs
  # vivent dans un fragment écrit par paletted sous
  # ~/.config/accent/fragments/alacritty-colors.toml, importé via la
  # directive `general.import` d'Alacritty (qui surveille les fichiers
  # importés et auto-reload sur changement).
  programs.alacritty = {
    enable = true;
    settings = {
      general.import = [
        "${config.home.homeDirectory}/.config/accent/fragments/alacritty-colors.toml"
      ];

      font = {
        size = 10.0;
        normal = {
          family = "JetBrains Mono";
          style = "Regular";
        };
      };

      window = {
        opacity = 1.0;
        decorations = "None";
        padding = {
          x = 16;
          y = 16;
        };
        dynamic_padding = false;
      };

      scrolling.history = 5000;

      cursor.style = {
        shape = "Beam";
        blinking = "On";
      };

      bell.duration = 0;

      # Le démarrage automatique de zellij est géré par l'intégration fish
      # (programs.zellij.enableFishIntegration = true) — fish lance zellij
      # à l'ouverture du shell interactif.  On retire Alt+Q (Quit) côté
      # Alacritty pour que zellij gère lui-même la fermeture: Alt+Q ferme
      # un pane, et quand le dernier pane disparaît zellij quitte → Alacritty
      # se ferme automatiquement (plus de processus enfant).
      terminal.shell.program = "fish";

      keyboard.bindings = [
        {
          key = "E";
          mods = "Alt";
          action = "CreateNewWindow";
        }
        {
          key = "T";
          mods = "Control|Shift";
          action = "SpawnNewInstance";
        }
      ];

      mouse.bindings = [
        {
          mouse = "Middle";
          action = "Paste";
        }
      ];
    };
  };
}
