{
  config,
  pkgs,
  lib,
  accentDaemon,
  darkMode ? true,
  ...
}:

let
  # NixOS blue — used to seed accent.hex on first install only.
  defaultAccent = "#5277c3";
  defaultMode = if darkMode then "dark" else "light";

  # ── VSCode settings template ──────────────────────────────────────────
  # Generated at Nix evaluation time so store paths are resolved literally.
  # Colour slots use @TOKEN@ strings which paletted substitutes at runtime.
  vscodeSettingsTemplate = builtins.toJSON {
    # ── per-language formatters ──
    "[go]" = {
      "editor.defaultFormatter" = "golang.go";
      "editor.formatOnSave" = true;
    };
    "[javascript]" = {
      "editor.defaultFormatter" = "esbenp.prettier-vscode";
      "editor.formatOnSave" = true;
    };
    "[javascriptreact]" = {
      "editor.defaultFormatter" = "esbenp.prettier-vscode";
      "editor.formatOnSave" = true;
    };
    "[json]" = {
      "editor.defaultFormatter" = "esbenp.prettier-vscode";
      "editor.formatOnSave" = true;
    };
    "[jsonc]" = {
      "editor.defaultFormatter" = "esbenp.prettier-vscode";
      "editor.formatOnSave" = true;
    };
    "[nix]" = {
      "editor.defaultFormatter" = "jnoortheen.nix-ide";
      "editor.formatOnSave" = true;
    };
    "[python]" = {
      "editor.codeActionsOnSave" = {
        "source.fixAll.ruff" = "explicit";
      };
      "editor.defaultFormatter" = "charliermarsh.ruff";
      "editor.formatOnSave" = true;
    };
    "[rust]" = {
      "editor.defaultFormatter" = "rust-lang.rust-analyzer";
      "editor.formatOnSave" = true;
    };
    "[terraform-vars]" = {
      "editor.defaultFormatter" = "hashicorp.terraform";
      "editor.formatOnSave" = true;
    };
    "[terraform]" = {
      "editor.defaultFormatter" = "hashicorp.terraform";
      "editor.formatOnSave" = true;
    };
    "[typescript]" = {
      "editor.defaultFormatter" = "esbenp.prettier-vscode";
      "editor.formatOnSave" = true;
    };
    "[typescriptreact]" = {
      "editor.defaultFormatter" = "esbenp.prettier-vscode";
      "editor.formatOnSave" = true;
    };
    # ── editor ──
    "editor.detectIndentation" = false;
    "editor.fontFamily" = "'JetBrains Mono', monospace";
    "editor.fontLigatures" = true;
    "editor.fontSize" = 12;
    "editor.insertSpaces" = false;
    "editor.mouseWheelZoom" = true;
    "editor.tabSize" = 4;
    "editor.tabSizeType" = "fixed";
    "editor.wordWrap" = "on";
    # ── extensions ──
    "extensions.ignoreRecommendations" = true;
    # ── nix LSP ──
    "nix.enableLanguageServer" = true;
    "nix.serverPath" = "${pkgs.nixd}/bin/nixd";
    "nix.serverSettings" = {
      "nixd" = {
        "formatting" = {
          "command" = [ "${pkgs.nixfmt}/bin/nixfmt" ];
        };
      };
    };
    # ── misc tools ──
    "sonarlint.pathToNodeExecutable" = "${pkgs.nodejs_22}/bin/node";
    # ── terminal ──
    "terminal.integrated.fontFamily" = "JetBrains Mono";
    "terminal.integrated.fontSize" = 12;
    # ── workbench ──
    "workbench.activityBar.location" = "top";
    "workbench.editor.wrapTabs" = true;
    # ── colour customizations (tokens replaced by paletted at runtime) ──
    "workbench.colorCustomizations" = {
      # general chrome
      "focusBorder" = "@ACCENT@";
      "selection.background" = "@BASE02@";
      # title bar
      "titleBar.activeBackground" = "@BASE01@";
      "titleBar.activeForeground" = "@BASE05@";
      "titleBar.inactiveBackground" = "@BASE00@";
      "titleBar.inactiveForeground" = "@BASE03@";
      # menu bar
      "menubar.selectionBackground" = "@BASE02@";
      "menu.background" = "@BASE01@";
      "menu.selectionBackground" = "@BASE02@";
      "menu.separatorBackground" = "@BASE03@";
      # activity bar
      "activityBar.background" = "@BASE01@";
      "activityBar.foreground" = "@BASE05@";
      "activityBar.inactiveForeground" = "@BASE03@";
      "activityBar.activeBorder" = "@ACCENT@";
      "activityBarBadge.background" = "@ACCENT@";
      "activityBarBadge.foreground" = "@BASE00@";
      # side bar
      "sideBar.background" = "@BASE01@";
      "sideBar.foreground" = "@BASE05@";
      "sideBarSectionHeader.background" = "@BASE02@";
      "sideBarSectionHeader.foreground" = "@BASE05@";
      "sideBarSectionHeader.border" = "@BASE03@";
      # editor
      "editor.background" = "@BASE00@";
      "editor.foreground" = "@BASE05@";
      "editor.lineHighlightBackground" = "@BASE01@";
      "editor.selectionBackground" = "@BASE02@";
      "editor.inactiveSelectionBackground" = "@BASE01@";
      "editor.wordHighlightBackground" = "@BASE02@";
      "editor.findMatchBackground" = "@BASE02@";
      "editor.findMatchHighlightBackground" = "@BASE01@";
      "editorCursor.foreground" = "@ACCENT@";
      "editorLineNumber.foreground" = "@BASE03@";
      "editorLineNumber.activeForeground" = "@BASE04@";
      "editorBracketMatch.background" = "@BASE02@";
      "editorBracketMatch.border" = "@ACCENT@";
      "editorIndentGuide.background1" = "@BASE02@";
      "editorIndentGuide.activeBackground1" = "@ACCENT_MUTED@";
      "editorRuler.foreground" = "@BASE02@";
      "editorWidget.background" = "@BASE01@";
      "editorWidget.border" = "@BASE03@";
      "editorSuggestWidget.background" = "@BASE01@";
      "editorSuggestWidget.border" = "@BASE03@";
      "editorSuggestWidget.selectedBackground" = "@BASE02@";
      "editorHoverWidget.background" = "@BASE01@";
      "editorHoverWidget.border" = "@BASE03@";
      # editor group / tabs
      "editorGroupHeader.tabsBackground" = "@BASE01@";
      "tab.activeBackground" = "@BASE00@";
      "tab.activeForeground" = "@BASE06@";
      "tab.activeBorderTop" = "@ACCENT@";
      "tab.inactiveBackground" = "@BASE01@";
      "tab.inactiveForeground" = "@BASE04@";
      "tab.unfocusedActiveBorderTop" = "@BASE03@";
      "tab.border" = "@BASE01@";
      # panel (terminal, problems, etc.)
      "panel.background" = "@BASE00@";
      "panel.border" = "@BASE02@";
      "panelTitle.activeBorder" = "@ACCENT@";
      "panelTitle.activeForeground" = "@BASE05@";
      "panelTitle.inactiveForeground" = "@BASE03@";
      # terminal
      "terminal.background" = "@BASE00@";
      "terminal.foreground" = "@BASE05@";
      "terminalCursor.foreground" = "@ACCENT@";
      "terminal.ansiBlack" = "@BASE00@";
      "terminal.ansiRed" = "@ACCENT@";
      "terminal.ansiGreen" = "@BASE0B@";
      "terminal.ansiYellow" = "@BASE0A@";
      "terminal.ansiBlue" = "@BASE0D@";
      "terminal.ansiMagenta" = "@BASE0F@";
      "terminal.ansiCyan" = "@BASE0C@";
      "terminal.ansiWhite" = "@BASE04@";
      "terminal.ansiBrightBlack" = "@BASE03@";
      "terminal.ansiBrightRed" = "@ACCENT@";
      "terminal.ansiBrightGreen" = "@BASE0B@";
      "terminal.ansiBrightYellow" = "@BASE0A@";
      "terminal.ansiBrightBlue" = "@BASE0D@";
      "terminal.ansiBrightMagenta" = "@BASE0F@";
      "terminal.ansiBrightCyan" = "@BASE0C@";
      "terminal.ansiBrightWhite" = "@BASE05@";
      # status bar
      "statusBar.background" = "@BASE01@";
      "statusBar.foreground" = "@BASE05@";
      "statusBar.noFolderBackground" = "@BASE01@";
      "statusBarItem.hoverBackground" = "@BASE02@";
      "statusBarItem.remoteBackground" = "@BASE02@";
      "statusBarItem.remoteForeground" = "@BASE05@";
      # input / quick pick
      "input.background" = "@BASE01@";
      "input.foreground" = "@BASE05@";
      "input.border" = "@BASE03@";
      "inputOption.activeBorder" = "@ACCENT@";
      "inputOption.activeBackground" = "@BASE02@";
      "quickInput.background" = "@BASE01@";
      "quickInputList.focusBackground" = "@BASE02@";
      # lists / trees
      "list.activeSelectionBackground" = "@ACCENT_DARK@";
      "list.activeSelectionForeground" = "@BASE07@";
      "list.hoverBackground" = "@BASE02@";
      "list.focusBackground" = "@BASE02@";
      "list.inactiveSelectionBackground" = "@BASE01@";
      "list.highlightForeground" = "@ACCENT@";
      # buttons
      "button.background" = "@ACCENT@";
      "button.foreground" = "@BASE00@";
      "button.hoverBackground" = "@ACCENT_DARK@";
      # badges
      "badge.background" = "@ACCENT@";
      "badge.foreground" = "@BASE00@";
      # progress
      "progressBar.background" = "@ACCENT@";
      # notifications
      "notificationCenterHeader.background" = "@BASE01@";
      "notifications.background" = "@BASE01@";
      "notifications.border" = "@BASE03@";
      # breadcrumbs
      "breadcrumb.background" = "@BASE01@";
      "breadcrumb.foreground" = "@BASE04@";
      "breadcrumb.activeSelectionForeground" = "@ACCENT@";
      # scrollbar (semi-transparent look via closest solid)
      "scrollbarSlider.background" = "@BASE02@";
      "scrollbarSlider.hoverBackground" = "@BASE03@";
      "scrollbarSlider.activeBackground" = "@ACCENT_MUTED@";
      # gitlens / source control decorations
      "gitDecoration.addedResourceForeground" = "@BASE0B@";
      "gitDecoration.modifiedResourceForeground" = "@BASE0D@";
      "gitDecoration.deletedResourceForeground" = "@BASE08@";
      "gitDecoration.untrackedResourceForeground" = "@BASE0B@";
      "gitDecoration.ignoredResourceForeground" = "@BASE03@";
    };
  };
in
{
  home.packages = [
    accentDaemon # provides both `paletted` and `palette` binaries
  ];

  # Templates installed read-only under ~/.config/accent/templates/
  # (starship, micro et fastfetch ne sont PAS listés ici : leurs configs sont
  # statiques et déclarées dans home/modules/shell/{starship,micro,fastfetch}.nix.
  # Elles utilisent l'ANSI bleu, remappé par wezterm vers l'accent vif.)
  xdg.configFile."accent/templates/hyprland.conf.tmpl".source = ./templates/hyprland.conf.tmpl;
  xdg.configFile."accent/templates/wezterm-accent.lua.tmpl".source =
    ./templates/wezterm-accent.lua.tmpl;
  xdg.configFile."accent/templates/vesktop-quickcss.css.tmpl".source =
    ./templates/vesktop-quickcss.css.tmpl;
  xdg.configFile."accent/templates/gtk4.css.tmpl".source = ./templates/gtk4.css.tmpl;
  xdg.configFile."accent/templates/kdeglobals.tmpl".source = ./templates/kdeglobals.tmpl;
  # Generated at Nix eval time so Nix store paths are literal strings in the template.
  xdg.configFile."accent/templates/vscode-settings.json.tmpl".text = vscodeSettingsTemplate;

  # Remove settings.json.bak BEFORE home-manager checks for link-target collisions.
  # paletted replaces the nix-store symlink with a real file on first run; on the
  # next rebuild home-manager tries to back it up as settings.json.bak, but if that
  # file already exists from the previous run it aborts. Cleaning it here keeps the
  # path clear every time.
  home.activation.cleanVscodeBak = lib.hm.dag.entryBefore [ "checkLinkTargets" ] ''
    rm -f "$HOME/.config/Code/User/settings.json.bak"
  '';

  # Seed accent.hex / mode.txt on first install, then re-render all template
  # outputs via paletted --init.  Runs after linkGeneration so the nix-store
  # symlink for settings.json is in place before paletted overwrites it.
  home.activation.accentSeed =
    lib.hm.dag.entryAfter
      [
        "writeBoundary"
        "vscodeProfiles"
        "vscodeRemoteExtensions"
        "linkGeneration"
      ]
      ''
        accent_dir="$HOME/.config/accent"
        mkdir -p "$accent_dir" "$HOME/.config/wezterm" "$HOME/.config/vesktop/settings"

        # Seed accent.hex with the current persisted color (or the palette default
        # on first install) so paletted --init has a source of truth to read.
        if [ ! -s "$accent_dir/accent.hex" ]; then
          printf '%s' "${defaultAccent}" > "$accent_dir/accent.hex"
        fi
        if [ ! -s "$accent_dir/mode.txt" ]; then
          printf '%s' "${defaultMode}" > "$accent_dir/mode.txt"
        fi

        # One-shot render: re-generates all template outputs without starting
        # the socket server.  --no-hyprctl because Hyprland may not be running
        # during activation.
        ${accentDaemon}/bin/paletted --init --no-hyprctl 2>&1 || true
      '';

  # ── systemd user service ──────────────────────────────────────────────────
  # Started automatically when the graphical session begins.
  # QuickShell, the `palette` CLI, and any future subscriber connect to
  # $XDG_RUNTIME_DIR/paletted.sock to read or change colors.
  systemd.user.services.paletted = {
    Unit = {
      Description = "Accent color and palette daemon";
      After = [ "graphical-session.target" ];
      PartOf = [ "graphical-session.target" ];
    };
    Service = {
      ExecStart = "${accentDaemon}/bin/paletted";
      Restart = "on-failure";
      RestartSec = "2s";
    };
    Install.WantedBy = [ "graphical-session.target" ];
  };
}
