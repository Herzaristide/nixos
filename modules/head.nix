{ config, pkgs, inputs, ... }:

{
  imports = [
    ./theme.nix
    ./audio.nix
  ];

  # udisks2 + gvfs: detect and mount external drives (required for Nautilus "Other Locations")
  services.udisks2.enable = true;
  services.gvfs.enable = true;

  # XDG Portal (for file picker, screen sharing in Hyprland)
  xdg.portal = {
    enable = true;
    extraPortals = [ pkgs.xdg-desktop-portal-hyprland ];
    config.common.default = "*";
  };

  # X11 (for XWayland) and Hyprland
  services.xserver.enable = true;
  services.displayManager.gdm.enable = true;

  # Auto-login (services.displayManager.autoLogin, pas gdm.autoLogin)
  services.displayManager.autoLogin = {
    enable = true;
    user = "aristide";
  };

  programs.hyprland.enable = true;
  services.xserver.xkb = {
    layout = "fr";
    variant = "";
  };
  console.keyMap = "fr";

  # Audio
  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    jack.enable = true;
    wireplumber.extraConfig = {
      # Allow Chrome/BandLab PWA to access microphone and audio
      "50-chrome-bandlab-access" = {
        "access.rules" = [
          {
            matches = [
              { "application.process.binary" = "google-chrome-stable"; }
              { "application.process.binary" = "google-chrome"; }
              { "application.process.binary" = "chromium"; }
              { "application.process.binary" = "chromium-browser"; }
            ];
            actions = {
              "update-props" = {
                "default_permissions" = "all";
              };
            };
          }
        ];
      };
    };
  };

  # Printing
  services.printing.enable = true;
}

