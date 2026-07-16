{
  config,
  pkgs,
  lib,
  ...
}:

let
  # Wrapper qui préserve le pinning GPU (AQ_DRM_DEVICES, cf. modules/common.nix
  # `renderDevice`) auparavant fait dans programs.fish.loginShellInit avant
  # l'exec direct de Hyprland à l'autologin. `start-hyprland` (pas `Hyprland`)
  # est le wrapper fourni par le paquet nixpkgs : il importe les variables
  # d'environnement dans systemd/dbus (nécessaire aux portails XDG).
  hyprlandSessionScript = pkgs.writeShellScriptBin "quickshell-hyprland-session" ''
    ${lib.optionalString (config.renderDevice != null) ''
      if [ -e "${config.renderDevice}" ]; then
        export AQ_DRM_DEVICES="$(${pkgs.coreutils}/bin/readlink -f ${config.renderDevice})"
      fi
    ''}
    exec ${config.programs.hyprland.package}/bin/start-hyprland
  '';

  # Session déclarée explicitement (plutôt que de dépendre du .desktop
  # auto-généré par programs.hyprland, dont on ne maîtrise pas l'Exec=)
  # pour garantir que le pinning GPU ci-dessus est bien appliqué.
  hyprlandSessionEntry =
    pkgs.writeTextFile {
      name = "quickshell-hyprland-session";
      destination = "/share/wayland-sessions/hyprland.desktop";
      text = ''
        [Desktop Entry]
        Name=Hyprland
        Comment=Hyprland compositor (Quickshell)
        Exec=${hyprlandSessionScript}/bin/quickshell-hyprland-session
        Type=Application
        DesktopNames=Hyprland
      '';
    }
    // {
      # Requis par services.displayManager.sessionPackages : doit lister le(s)
      # nom(s) de base des .desktop fournis (cf. nixos/modules/services/display-managers/default.nix).
      providedSessions = [ "hyprland" ];
    };
in
{
  services.displayManager.sessionPackages = [ hyprlandSessionEntry ];

  # Écran de login (remplace l'autologin) : greetd + regreet, dans cage
  # (compositeur Wayland minimal en kiosque, faible surface d'attaque).
  # Reskin manuel pour se rapprocher de la palette Quickshell (services/Theme.qml
  # dans le repo karenine) : fond #0d0d0d, accent #5277c3, police JetBrains Mono.
  # Ce n'est pas un rendu QML identique (regreet est du GTK4) — cf. discussion :
  # un greeter Quickshell natif est un développement bien plus lourd, écarté
  # au profit d'un logiciel mature reskinné.
  programs.regreet = {
    enable = true;

    font = {
      name = "JetBrains Mono";
      size = 12;
      package = pkgs.jetbrains-mono;
    };

    theme.name = "Adwaita";

    settings = {
      GTK.application_prefer_dark_theme = true;
      appearance.greeting_msg = "Bonjour, aristide.";
    };

    extraCss = ''
      window.background {
        background-color: #0d0d0d;
      }

      label {
        color: #e0e0ff;
      }

      entry {
        background-color: #1a1a1a;
        color: #e0e0ff;
        border: 2px solid #5277c3;
        border-radius: 8px;
        padding: 6px 10px;
      }

      entry:focus {
        border-color: #7ebae4;
      }

      button {
        background-color: #1a1a1a;
        color: #e0e0ff;
        border: 1px solid #2a2a2a;
        border-radius: 8px;
      }

      button:hover,
      button:focus {
        background-color: #5277c3;
        color: #0d0d0d;
      }
    '';
  };
}
