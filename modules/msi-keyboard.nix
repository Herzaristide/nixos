{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.msiKeyboard;
  msiRgbSet = pkgs.callPackage ../msi-rgb { };
  user = cfg.user;
in
{
  options.msiKeyboard = {
    enable = lib.mkEnableOption "MSI laptop RGB keyboard (SteelSeries KLC 1038:113a) — udev config + boot/resume reapply";
    user = lib.mkOption {
      type = lib.types.str;
      default = "aristide";
      description = "User that owns /var/lib/msi-rgb (the watcher writes the cached color from a user session).";
    };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [ msiRgbSet ];

    # The kernel ships with bConfigurationValue empty for this controller —
    # on Windows MSI Center selects config 1. Without this udev rule no USB
    # interfaces appear and no /dev/hidraw* gets created.
    # The ATTR{bConfigurationValue}!="1" guard skips the write if the kernel
    # already picked the right config (post-resume, repeated add events).
    services.udev.extraRules = ''
      ACTION=="add", SUBSYSTEM=="usb", ATTR{idVendor}=="1038", ATTR{idProduct}=="113a", ATTR{bConfigurationValue}!="1", ATTR{bConfigurationValue}="1"
      SUBSYSTEM=="hidraw", ATTRS{idVendor}=="1038", ATTRS{idProduct}=="113a", MODE="0666"
    '';

    # Cache file the watcher writes from the user session and the boot/resume
    # hooks read from. Owned by the user so user-side writes don't need root.
    systemd.tmpfiles.rules = [
      "d /var/lib/msi-rgb 0755 ${user} users -"
    ];

    # Re-apply the last known color at boot. The controller loses RGB state
    # across both reboot and suspend.
    # Single attempt — msi-rgb-set itself is fail-fast, and if the device is
    # missing or wedged we don't want a retry loop spamming writes.
    systemd.services.msi-rgb-boot = {
      description = "Re-apply MSI keyboard RGB at boot";
      wantedBy = [ "multi-user.target" ];
      after = [
        "local-fs.target"
        "systemd-udev-settle.service"
      ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = false;
        ExecStart = pkgs.writeShellScript "msi-rgb-boot" ''
          set -u
          cache=/var/lib/msi-rgb/last-color
          [ -s "$cache" ] || { echo "msi-rgb-boot: no cached color, skipping" >&2; exit 0; }
          color=$(cat "$cache")

          # Let udev + USB enumeration fully settle before touching the device.
          sleep 3

          hidraw=
          for h in /sys/class/hidraw/hidraw*; do
            [ -e "$h/device/uevent" ] || continue
            if grep -q "1038:0000113A" "$h/device/uevent"; then
              hidraw=$h
              break
            fi
          done
          if [ -z "$hidraw" ]; then
            echo "msi-rgb-boot: no hidraw for 1038:113a — controller absent or wedged" >&2
            exit 0
          fi

          exec ${msiRgbSet}/bin/msi-rgb-set "$color"
        '';
      };
    };

    # Same idea after resume — the controller forgets its state.
    # Single attempt, no retry, fail silent.
    powerManagement.resumeCommands = ''
      cache=/var/lib/msi-rgb/last-color
      if [ -s "$cache" ]; then
        color=$(cat "$cache")
        sleep 2  # let USB come back
        ${msiRgbSet}/bin/msi-rgb-set "$color" || true
      fi
    '';
  };
}
