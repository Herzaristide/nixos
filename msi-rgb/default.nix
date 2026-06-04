{ pkgs, ... }:

pkgs.runCommand "msi-rgb-set"
  {
    nativeBuildInputs = [ pkgs.makeWrapper ];
    meta = {
      description = "Set a static color on the MSI SteelSeries KLC keyboard (USB 1038:113a)";
      mainProgram = "msi-rgb-set";
    };
  }
  ''
    mkdir -p $out/bin $out/share/msi-rgb-set
    cp ${./msi_rgb_set.py} $out/share/msi-rgb-set/msi_rgb_set.py

    # Pure stdlib Python — talks to /dev/hidraw via HIDIOCSFEATURE directly,
    # no hidapi/libusb wrapper needed.
    makeWrapper ${pkgs.python3}/bin/python3 $out/bin/msi-rgb-set \
      --add-flags $out/share/msi-rgb-set/msi_rgb_set.py
  ''
