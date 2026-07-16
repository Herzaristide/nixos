{ pkgs, ... }:

{
  services.upower.enable = true;

  services.udev.extraRules = ''
    SUBSYSTEM=="usb", DRIVERS=="usbhid", ATTR{power/wakeup}="enabled"
  '';

  services.logind.settings.Login = {
    HandleLidSwitch = "ignore";
    HandleLidSwitchDocked = "ignore";
    HandleLidSwitchExternalPower = "ignore";
    IdleAction = "suspend";
    IdleActionSec = "30min";
    HandleSuspendKey = "suspend";
    HandleHibernateKey = "hibernate";
    HandlePowerKey = "poweroff";
  };

  environment.systemPackages = with pkgs; [
    upower
    powertop
    acpi
  ];
}
