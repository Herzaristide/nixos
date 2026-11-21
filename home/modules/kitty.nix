{ pkgs, ... }:

# kitty, le terminal par défaut (TERMINAL, xdg-terminal-exec, SUPER + Return ;
# Alacritty et foot retirés le 2026-11-21). Ses couleurs viennent d'anna (karenine) : le fragment
# ~/.config/accent/fragments/kitty-colors.conf, que kitty relit seul quand il
# change (auto_reload_config, actif par défaut) et qu'anna lui fait relire
# aussi par SIGUSR1 après chaque changement d'accent ou de mode.
#
# Ce qu'il apporte de natif : le glisser-déposer (un fichier déposé colle son
# chemin), les chemins repérés à l'écran (ctrl+shift+p>f les insère,
# ctrl+shift+p>n ouvre un fichier:ligne dans Zed) et l'intégration au shell
# (fish), qui lui donne le dossier courant et les sauts entre prompts.
let
  shortcuts = import ./shortcuts.nix { inherit pkgs; };
in
{
  programs.kitty = {
    enable = true;
    font = {
      name = "JetBrains Mono";
      size = 10;
    };
    shellIntegration.enableFishIntegration = true;

    settings = {
      shell = "fish";

      # 16 px de marge. kitty compte en points (1 pt = 4/3 px).
      window_padding_width = 12;
      hide_window_decorations = "yes";
      confirm_os_window_close = 0;

      scrollback_lines = 5000;
      copy_on_select = "clipboard";

      cursor_shape = "beam";

      enable_audio_bell = "no";

      # Sinon kitty enregistre la taille et l'état de sa dernière fenêtre
      # (~/.cache/kitty/main.json) et les redemande à l'ouverture : une
      # fenêtre fermée maximisée fait rouvrir les suivantes maximisées par
      # Hyprland, par-dessus les fenêtres voisines au lieu d'être tuilées.
      remember_window_size = "no";

      # Relit kitty.conf quand il change (défaut, rappelé ici : anna compte
      # dessus, avec SIGUSR1 en plus).
      auto_reload_config = "0.1";
    };

    keybindings = builtins.listToAttrs (
      map (s: {
        name = s.keys;
        value = s.action;
      }) shortcuts.kitty
    );

    # Les couleurs d'anna. `include` après les réglages : elles passent devant.
    extraConfig = ''
      include ~/.config/accent/fragments/kitty-colors.conf
    '';
  };
}
