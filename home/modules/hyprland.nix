{ config, pkgs, lib, ... }:

let
  # Cursor projects: un workspace + une instance Cursor par projet
  cursorWorkspaceProjects = [
    { path = "/etc/nixos"; }
    # { path = "/home/aristide/projects/foo"; }
  ];
  cursorWithWorkspace = lib.imap1 (i: p: { workspace = i; path = p.path; }) cursorWorkspaceProjects;
  cursorExecOnce = map (p: "cursor ${lib.escapeShellArg p.path}") cursorWithWorkspace;
  cursorWorkspaceDefs = map (p: "${toString p.workspace}, monitor:VGA-1${if p.workspace == 1 then ", default:true" else ""}") cursorWithWorkspace;
  cursorWorkspaceRules = map (p: "${toString p.workspace}, class:^(Cursor)$, title:.*${lib.escapeRegex (builtins.baseNameOf p.path)}.*") cursorWithWorkspace;
  # Workspaces libres sur VGA après les projets Cursor (ws 1–3 sur VGA)
  maxCursorWs = builtins.length cursorWorkspaceProjects;
  freeWorkspaces = map (i: "${toString (maxCursorWs + i)}, monitor:VGA-1") (lib.range 1 (lib.max 0 (3 - maxCursorWs)));
in
{
  wayland.windowManager.hyprland = {
    enable = true;
    settings = {
      "$mod" = "SUPER";

      # French keyboard + mouse sans accélération (plus fluide, 1:1)
      input = {
        kb_layout = "fr";
        kb_variant = "";
        accel_profile = "flat";
        force_no_accel = true;
      };

      cursor = {
        no_hardware_cursors = 1;
      };

      # GPU: moins d'effets pour GT 630 + nouveau (blur/ombres coûtent cher)
      decoration = {
        rounding = 4;
        active_opacity = 1.0;
        inactive_opacity = 1.0;
      };

      # Special workspace apparaît depuis le bas
      animation = [
        "specialWorkspaceIn, 1, 8, default, slidevert bottom"
        "specialWorkspaceOut, 1, 8, default, slidevert bottom"
      ];

      # Monitors: HDMI-A-1 left (portrait), VGA-1 right, côte à côte sans gap
      # HDMI: 1920x1080 portrait, scale 1.33 → logical 812×1444
      # VGA: 1920x1080, scale 1.33 → logical 1444×812. Pos x=812 (à droite de HDMI), y centré: 722-406=316
      monitor = [
        "HDMI-A-1,1920x1080@60,0x0,1.33,transform,1"
        "VGA-1,1920x1080@60,812x316,1.33"
        ",preferred,auto,1"
      ];

      # Autostart: Cursor with one project per workspace (see cursorWorkspaceProjects), Chrome on ws 4
      exec-once = cursorExecOnce ++ [
        "google-chrome-stable --user-data-dir=$HOME/.config/google-chrome-$(hostname)"
      ];

      # Workspaces: 1–3 on VGA (main), 4 on HDMI. special:gemini = overlay (scratchpad)
      # Lock apps to workspaces (syntax moderne); Cursor per project by title (basename)
      workspace = cursorWorkspaceDefs ++ freeWorkspaces ++ [
        "4, monitor:HDMI-A-1"
        "special:gemini, on-created-empty:hypr-gemini-launch, gapsout:80 200 80 200, gapsin:30"
      ] ++ cursorWorkspaceRules ++ [
        "4, class:^(Google-chrome)$"
      ];

      # Minimal binds - terminal, apps
      bind = [
        "$mod, Return, exec, ghostty"
        "$mod, C, exec, cursor"
        "$mod, B, exec, bash -c 'google-chrome-stable --user-data-dir=$HOME/.config/google-chrome-$(hostname)'"
        "$mod, Q, killactive"
        "$mod, M, exit"
        "$mod, V, togglefloating"
        "$mod, P, pseudo"
        "$mod, J, togglesplit"
        "$mod, left, movefocus, l"
        "$mod, right, movefocus, r"
        "$mod, up, movefocus, u"
        "$mod, down, movefocus, d"
        # Focus prev/next monitor (bracket keys)
        "$mod, bracketleft, focusmonitor, -1"
        "$mod, bracketright, focusmonitor, +1"
        # Workspaces (AZERTY: & é " = 1 2 3)
        "$mod, ampersand, workspace, 1"
        "$mod, eacute, workspace, 2"
        "$mod, quotedbl, workspace, 3"
        "$mod, 1, workspace, 1"
        "$mod, 2, workspace, 2"
        "$mod, 3, workspace, 3"
        "$mod, 4, workspace, 4"
        # Workspace spécial Gemini (Super+G) – s'affiche en overlay
        "$mod, G, togglespecialworkspace, gemini"
      ];

      bindm = [
        "$mod, mouse:272, movewindow"
        "$mod, mouse:273, resizewindow"
      ];
    };
  };
}
