{ config, pkgs, ... }:

{
  # XDG Portal (for file picker, screen sharing in Hyprland)
  xdg.portal = {
    enable = true;
    extraPortals = [ pkgs.xdg-desktop-portal-hyprland ];
    config.common.default = "*";
  };

  # X11 (for XWayland) and Hyprland
  services.xserver.enable = true;
  services.xserver.displayManager.gdm.enable = true;

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
  };

  # Printing
  services.printing.enable = true;
}

