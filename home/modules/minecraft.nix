{ pkgs, osConfig, ... }:

let
  prism = pkgs.prismlauncher.override {
    jdks = with pkgs; [
      jdk8
      jdk17
      jdk21
      jdk25
    ];
  };

  dgpuPciId = "pci-0000_03_00_0";

  useDgpu = (osConfig.networking.hostName or "") == "gary";
in
{
  home.packages = [
    (
      if !useDgpu then
        prism
      else
        pkgs.symlinkJoin {
          name = "prismlauncher-dgpu";
          paths = [ prism ];
          nativeBuildInputs = [ pkgs.makeWrapper ];
          postBuild = ''
            wrapProgram $out/bin/prismlauncher \
              --set DRI_PRIME ${dgpuPciId}
          '';
        }
    )
  ];
}
