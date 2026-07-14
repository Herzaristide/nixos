# Source de vérité unique pour tous les raccourcis clavier : Hyprland, zellij,
# Zed, Alacritty, micro. Chaque module consommateur importe ce fichier et
# transforme les entrées vers le format natif de son outil — voir
# home/modules/{alacritty,hyprland/hyprland,shell/{zellij,micro},code/zed}.nix.
{
  pkgs,
  # Chemin du script hypr-closed-lid-layout (dérivation construite dans
  # hyprland.nix via pkgs.writeShellScript). Seul hyprland.nix le fournit ;
  # les autres modules ne touchent jamais aux entrées "hyprland" donc n'ont
  # pas besoin de cette valeur (null par défaut, jamais forcé grâce à la
  # laziness de Nix).
  lidLayoutPath ? null,
}:
{
  # ── Hyprland (gestionnaire de fenêtres) ──────────────────────────────────
  # `lua` = corps de l'appel Lua exécuté par le binding (configType = "lua").
  # `opts` optionnel = table d'options hyprland (mouse, locked, repeating...).
  hyprland = [
    {
      keys = "SUPER + Return";
      lua = ''hl.dsp.exec_cmd("alacritty")'';
      desc = "Ouvrir Alacritty";
    }
    {
      keys = "SUPER + Z";
      lua = ''hl.dsp.exec_cmd("${pkgs.zed-editor}/bin/zeditor")'';
      desc = "Ouvrir Zed";
    }
    {
      keys = "SUPER + F";
      lua = ''hl.dsp.exec_cmd("dolphin")'';
      desc = "Ouvrir Dolphin (fichiers)";
    }
    {
      keys = "SUPER + D";
      lua = ''hl.dsp.exec_cmd("vesktop")'';
      desc = "Ouvrir Vesktop (Discord)";
    }
    {
      keys = "SUPER + Y";
      lua = ''hl.dsp.exec_cmd("ytmusic-pwa")'';
      desc = "Ouvrir YouTube Music";
    }
    {
      keys = "SUPER + space";
      lua = ''hl.dsp.exec_cmd("tofi-drun --drun-launch=true")'';
      desc = "Lanceur d'applications (tofi)";
    }
    {
      keys = "SUPER + SHIFT + R";
      lua = ''hl.dsp.exec_cmd("pkill quickshell; quickshell &")'';
      desc = "Redémarrer Quickshell";
    }

    {
      keys = "SUPER + Q";
      lua = "hl.dsp.window.close()";
      desc = "Fermer la fenêtre";
    }
    {
      keys = "SUPER + T";
      lua = ''hl.dsp.window.float({ action = "toggle" })'';
      desc = "Basculer flottant";
    }
    {
      keys = "SUPER + SHIFT + V";
      lua = ''hl.dsp.window.float({ action = "toggle" })'';
      desc = "Basculer flottant (alt)";
    }
    {
      keys = "SUPER + J";
      lua = ''hl.dsp.layout("togglesplit")'';
      desc = "Basculer le split";
    }
    {
      keys = "SUPER + SHIFT + M";
      lua = "hl.dsp.exit()";
      desc = "Quitter Hyprland";
    }

    {
      keys = "SUPER + left";
      lua = ''hl.dsp.focus({ direction = "left" })'';
      desc = "Focus fenêtre gauche";
    }
    {
      keys = "SUPER + right";
      lua = ''hl.dsp.focus({ direction = "right" })'';
      desc = "Focus fenêtre droite";
    }
    {
      keys = "SUPER + up";
      lua = ''hl.dsp.focus({ direction = "up" })'';
      desc = "Focus fenêtre haut";
    }
    {
      keys = "SUPER + down";
      lua = ''hl.dsp.focus({ direction = "down" })'';
      desc = "Focus fenêtre bas";
    }
    {
      keys = "SUPER + bracketleft";
      lua = ''hl.dsp.exec_cmd("hyprctl dispatch focusmonitor -1")'';
      desc = "Focus moniteur précédent";
    }
    {
      keys = "SUPER + bracketright";
      lua = ''hl.dsp.exec_cmd("hyprctl dispatch focusmonitor +1")'';
      desc = "Focus moniteur suivant";
    }

    # Workspaces AZERTY (& é " ' ( pour 1-5, - pour 6, ² pour 9)
    {
      keys = "SUPER + ampersand";
      lua = "hl.dsp.focus({ workspace = 1 })";
      desc = "Focus workspace 1";
    }
    {
      keys = "SUPER + eacute";
      lua = "hl.dsp.focus({ workspace = 2 })";
      desc = "Focus workspace 2";
    }
    {
      keys = "SUPER + quotedbl";
      lua = "hl.dsp.focus({ workspace = 3 })";
      desc = "Focus workspace 3";
    }
    {
      keys = "SUPER + apostrophe";
      lua = "hl.dsp.focus({ workspace = 4 })";
      desc = "Focus workspace 4";
    }
    {
      keys = "SUPER + parenleft";
      lua = "hl.dsp.focus({ workspace = 5 })";
      desc = "Focus workspace 5";
    }
    {
      keys = "SUPER + minus";
      lua = "hl.dsp.focus({ workspace = 6 })";
      desc = "Focus workspace 6";
    }
    {
      keys = "SUPER + twosuperior";
      lua = "hl.dsp.focus({ workspace = 9 })";
      desc = "Focus workspace 9";
    }

    {
      keys = "SUPER + SHIFT + ampersand";
      lua = "hl.dsp.window.move({ workspace = 1 })";
      desc = "Déplacer fenêtre vers workspace 1";
    }
    {
      keys = "SUPER + SHIFT + eacute";
      lua = "hl.dsp.window.move({ workspace = 2 })";
      desc = "Déplacer fenêtre vers workspace 2";
    }
    {
      keys = "SUPER + SHIFT + quotedbl";
      lua = "hl.dsp.window.move({ workspace = 3 })";
      desc = "Déplacer fenêtre vers workspace 3";
    }
    {
      keys = "SUPER + SHIFT + apostrophe";
      lua = "hl.dsp.window.move({ workspace = 4 })";
      desc = "Déplacer fenêtre vers workspace 4";
    }
    {
      keys = "SUPER + SHIFT + parenleft";
      lua = "hl.dsp.window.move({ workspace = 5 })";
      desc = "Déplacer fenêtre vers workspace 5";
    }
    {
      keys = "SUPER + SHIFT + minus";
      lua = "hl.dsp.window.move({ workspace = 6 })";
      desc = "Déplacer fenêtre vers workspace 6";
    }
    {
      keys = "SUPER + SHIFT + twosuperior";
      lua = "hl.dsp.window.move({ workspace = 9 })";
      desc = "Déplacer fenêtre vers workspace 9";
    }

    {
      keys = "SUPER + G";
      lua = ''hl.dsp.exec_cmd("chromium")'';
      desc = "Scratchpad Gemini (chromium)";
    }
    {
      keys = "SUPER + C";
      lua = ''hl.dsp.workspace.toggle_special("claude")'';
      desc = "Scratchpad Claude";
    }

    {
      keys = "SUPER + F1";
      lua = ''hl.dsp.exec_cmd("echo widget:0 > /tmp/qs-panel.fifo")'';
      desc = "Widget Quickshell 0";
    }
    {
      keys = "SUPER + F2";
      lua = ''hl.dsp.exec_cmd("echo widget:1 > /tmp/qs-panel.fifo")'';
      desc = "Widget Quickshell 1";
    }
    {
      keys = "SUPER + F3";
      lua = ''hl.dsp.exec_cmd("echo widget:2 > /tmp/qs-panel.fifo")'';
      desc = "Widget Quickshell 2";
    }
    {
      keys = "SUPER + F4";
      lua = ''hl.dsp.exec_cmd("echo widget:3 > /tmp/qs-panel.fifo")'';
      desc = "Widget Quickshell 3";
    }
    {
      keys = "SUPER + F5";
      lua = ''hl.dsp.exec_cmd("echo widget:4 > /tmp/qs-panel.fifo")'';
      desc = "Widget Quickshell 4";
    }

    {
      keys = "SUPER + mouse:272";
      lua = "hl.dsp.window.drag()";
      opts = {
        mouse = true;
      };
      desc = "Déplacer fenêtre (drag souris)";
    }
    {
      keys = "SUPER + mouse:273";
      lua = "hl.dsp.window.resize()";
      opts = {
        mouse = true;
      };
      desc = "Redimensionner fenêtre (drag souris)";
    }

    {
      keys = "XF86AudioRaiseVolume";
      lua = ''hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 3%+")'';
      opts = {
        locked = true;
        repeating = true;
      };
      desc = "Volume +";
    }
    {
      keys = "XF86AudioLowerVolume";
      lua = ''hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 3%-")'';
      opts = {
        locked = true;
        repeating = true;
      };
      desc = "Volume -";
    }
    {
      keys = "XF86AudioMute";
      lua = ''hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle")'';
      opts = {
        locked = true;
      };
      desc = "Mute";
    }
    {
      keys = "XF86MonBrightnessUp";
      lua = ''hl.dsp.exec_cmd("brightnessctl set 5%+")'';
      opts = {
        locked = true;
        repeating = true;
      };
      desc = "Luminosité +";
    }
    {
      keys = "XF86MonBrightnessDown";
      lua = ''hl.dsp.exec_cmd("brightnessctl set 5%-")'';
      opts = {
        locked = true;
        repeating = true;
      };
      desc = "Luminosité -";
    }

    # Lid switch — en Lua, pas de "mod, key" : juste "switch:on:Lid Switch".
    {
      keys = "switch:on:Lid Switch";
      lua = ''hl.dsp.exec_cmd("${toString lidLayoutPath} --force")'';
      opts = {
        locked = true;
      };
      desc = "Fermeture du capot (zola)";
    }
    {
      keys = "switch:off:Lid Switch";
      lua = ''hl.dsp.exec_cmd("hyprctl keyword monitor 'eDP-1,preferred,auto-left,1.33'")'';
      opts = {
        locked = true;
      };
      desc = "Ouverture du capot (zola)";
    }
  ];

  # ── Zed (éditeur) ─────────────────────────────────────────────────────
  # `action` = string OU liste [action {options}], tel qu'attendu par userKeymaps.
  zed = [
    {
      context = "Editor";
      key = "alt-a";
      action = "editor::ToggleComments";
      desc = "Commenter/décommenter";
    }
    {
      context = "Editor";
      key = "alt-enter";
      action = "terminal_panel::ToggleFocus";
      desc = "Ouvrir/fermer le terminal";
    }
    {
      context = "Editor";
      key = "alt-r";
      action = "git_panel::ToggleFocus";
      desc = "Basculer le panneau git";
    }
    {
      context = "Editor";
      key = "alt-o";
      action = "workspace::Open";
      desc = "Ouvrir fichier/dossier";
    }
    {
      context = "Editor";
      key = "alt-f";
      action = "file_finder::Toggle";
      desc = "Sélecteur de fichiers";
    }
    {
      context = "Editor";
      key = "alt-z";
      action = "editor::ToggleSoftWrap";
      desc = "Basculer le retour à la ligne";
    }
    {
      context = "Editor";
      key = "alt-e";
      action = "markdown::OpenPreview";
      desc = "Preview markdown";
    }
    # Alt + déplacement du curseur = sélection. Remplace le déplacement de
    # ligne Alt+↑/Alt+↓ du keymap VS Code par défaut de Zed.
    {
      context = "Editor";
      key = "alt-up";
      action = "editor::SelectUp";
      desc = "Sélectionner vers le haut";
    }
    {
      context = "Editor";
      key = "alt-down";
      action = "editor::SelectDown";
      desc = "Sélectionner vers le bas";
    }
    {
      context = "Editor";
      key = "alt-left";
      action = "editor::SelectLeft";
      desc = "Sélectionner vers la gauche";
    }
    {
      context = "Editor";
      key = "alt-right";
      action = "editor::SelectRight";
      desc = "Sélectionner vers la droite";
    }
    {
      context = "Editor";
      key = "alt-home";
      action = [
        "editor::SelectToBeginningOfLine"
        {
          stop_at_soft_wraps = true;
          stop_at_indent = true;
        }
      ];
      desc = "Sélectionner jusqu'au début de ligne";
    }
    {
      context = "Editor";
      key = "alt-end";
      action = [
        "editor::SelectToEndOfLine"
        {
          stop_at_soft_wraps = true;
        }
      ];
      desc = "Sélectionner jusqu'à la fin de ligne";
    }
    {
      context = "Editor";
      key = "alt-pageup";
      action = "editor::SelectPageUp";
      desc = "Sélectionner une page vers le haut";
    }
    {
      context = "Editor";
      key = "alt-pagedown";
      action = "editor::SelectPageDown";
      desc = "Sélectionner une page vers le bas";
    }

    {
      context = "Workspace";
      key = "alt-p";
      action = "projects::OpenRecent";
      desc = "Projets récents";
    }
    {
      context = "Workspace";
      key = "alt-o";
      action = "workspace::Open";
      desc = "Ouvrir fichier/dossier";
    }
    {
      context = "Workspace";
      key = "alt-f";
      action = "file_finder::Toggle";
      desc = "Sélecteur de fichiers";
    }
    {
      context = "Workspace";
      key = "alt-c";
      action = "project_panel::ToggleFocus";
      desc = "Focus arborescence de fichiers";
    }
    {
      context = "Workspace";
      key = "alt-q";
      action = "pane::CloseActiveItem";
      desc = "Fermer l'onglet actif";
    }
    {
      context = "Workspace";
      key = "alt-r";
      action = "git_panel::ToggleFocus";
      desc = "Basculer le panneau git";
    }
    {
      context = "Workspace";
      key = "alt-enter";
      action = "terminal_panel::ToggleFocus";
      desc = "Ouvrir/fermer le terminal";
    }

    # Alt+E depuis l'arborescence → retour éditeur.
    {
      context = "ProjectPanel";
      key = "alt-e";
      action = "workspace::ActivateLastPane";
      desc = "Retour éditeur";
    }

    # Alt+E / Alt+Entrée depuis le terminal → retour éditeur / fermer (symétrie).
    # Alt+Haut/Bas et Alt+F alignés sur les bindings Alacritty
    # (home/modules/alacritty.nix) : scroll ligne par ligne + recherche.
    {
      context = "Terminal";
      key = "alt-e";
      action = "terminal_panel::ToggleFocus";
      desc = "Retour éditeur (depuis le terminal)";
    }
    {
      context = "Terminal";
      key = "alt-enter";
      action = "terminal_panel::ToggleFocus";
      desc = "Fermer le terminal (symétrie du toggle)";
    }
    {
      context = "Terminal";
      key = "alt-up";
      action = "terminal::ScrollLineUp";
      desc = "Scroll ligne haut";
    }
    {
      context = "Terminal";
      key = "alt-down";
      action = "terminal::ScrollLineDown";
      desc = "Scroll ligne bas";
    }
    {
      context = "Terminal";
      key = "alt-f";
      action = "buffer_search::Deploy";
      desc = "Recherche dans le scrollback";
    }

    # Alt+E depuis la preview markdown → revenir au code (bascule preview↔code).
    {
      context = "MarkdownPreview";
      key = "alt-e";
      action = "pane::ActivatePreviousItem";
      desc = "Retour au code";
    }
  ];

  # ── Alacritty (terminal) ─────────────────────────────────────────────────
  alacritty = [
    {
      key = "E";
      mods = "Alt";
      action = "CreateNewWindow";
      desc = "Nouvelle fenêtre";
    }
    {
      key = "T";
      mods = "Control|Shift";
      action = "SpawnNewInstance";
      desc = "Nouvelle instance";
    }
    {
      key = "PageUp";
      mods = "None";
      action = "ScrollPageUp";
      desc = "Scroll page haut (natif, sans Shift)";
    }
    {
      key = "PageDown";
      mods = "None";
      action = "ScrollPageDown";
      desc = "Scroll page bas (natif, sans Shift)";
    }
    {
      key = "Up";
      mods = "Alt";
      action = "ScrollLineUp";
      desc = "Scroll ligne haut";
    }
    {
      key = "Down";
      mods = "Alt";
      action = "ScrollLineDown";
      desc = "Scroll ligne bas";
    }
    {
      key = "F";
      mods = "Alt";
      action = "SearchForward";
      desc = "Recherche dans le scrollback";
    }
  ];

  # ── micro (éditeur en terminal) ──────────────────────────────────────────
  micro = [
    {
      key = "CtrlE";
      action = "lua:comment.comment";
      desc = "Commenter (plugin comment)";
    }
    {
      key = "Alt-f";
      action = "command:format";
      desc = "Formater (plugin autofmt)";
    }
  ];
}
