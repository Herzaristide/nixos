{ config, pkgs, ... }:

{
  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
    settings.General.Experimental = true;
  };

  # GUI tray applet — only on hosts with a desktop session
  services.blueman.enable = config.head;
}
