{ pkgs, ... }:

{
  # UPower: battery/UPS/power-source D-Bus service (consumed by Quickshell and other clients)
  services.upower.enable = true;

  # USB wakeup — allow keyboard/mouse to wake the PC from suspend
  services.udev.extraRules = ''
    SUBSYSTEM=="usb", DRIVERS=="usbhid", ATTR{power/wakeup}="enabled"
  '';

  # Sleep / power management — suspend on idle, wake on keyboard/mouse
  services.logind.settings.Login = {
    HandleLidSwitch = "ignore";
    HandleLidSwitchDocked = "ignore";
    HandleLidSwitchExternalPower = "ignore";
    IdleAction = "suspend";
    IdleActionSec = "5min";
    HandleSuspendKey = "suspend";
    HandleHibernateKey = "hibernate";
    HandlePowerKey = "poweroff";
  };

  environment.systemPackages = with pkgs; [
    upower
    powertop # Power consumption analyzer
    acpi # Battery status CLI tool
  ];
}
