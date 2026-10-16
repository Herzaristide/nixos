{
  config,
  lib,
  pkgs,
  ...
}:

{
  services.upower.enable = true;

  services.udev.extraRules = ''
    SUBSYSTEM=="usb", DRIVERS=="usbhid", ATTR{power/wakeup}="enabled"
  '';

  services.logind.settings.Login = lib.mkMerge [
    {
      HandleLidSwitch = "ignore";
      HandleLidSwitchDocked = "ignore";
      HandleLidSwitchExternalPower = "ignore";
      HandlePowerKey = "poweroff";
    }

    # Veille réservée aux postes : un serveur headless (gary, kafka) garde le
    # défaut de systemd, IdleAction = "ignore", et reste joignable en SSH.
    (lib.mkIf config.head {
      IdleAction = "suspend";
      IdleActionSec = "30min";
      HandleSuspendKey = "suspend";
      HandleHibernateKey = "hibernate";
    })
  ];

  environment.systemPackages = with pkgs; [
    upower
    powertop
    acpi
  ];
}
