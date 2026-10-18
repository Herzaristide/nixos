{ config, ... }:

{
  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
    settings.General.Experimental = true;
  };

  # GUI tray applet — only on hosts with a desktop session. blueman-applet is
  # started with Hyprland (home/modules/hyprland/hyprland.nix): its pairing
  # requests and connection notices reach karenine's notification server.
  services.blueman.enable = config.head;
}
