{ pkgs, ... }:

let
  prism = pkgs.prismlauncher.override {
    jdks = with pkgs; [
      jdk8
      jdk17
      jdk21
      jdk25
    ];
  };
in
{
  # Pas d'épinglage sur le GPU discret : PrismLauncher a sa propre case
  # « Use discrete GPU », par instance.
  home.packages = [ prism ];
}
