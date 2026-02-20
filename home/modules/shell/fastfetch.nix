{ pkgs, lib, ... }:

let
  # Download the custom NixOS ASCII art
  nixos-logo = pkgs.fetchurl {
    url = "https://codeberg.org/permafrozen/ascii/raw/branch/main/src/nixos_filled.txt";
    hash = "sha256-N2643TJsB9fAgmkUd7eJ1AyeJH4+lzaaGNuRnHyhEoQ=";
  };

  # Custom configuration using the custom ASCII logo
  fastfetch-config = pkgs.writeText "config.jsonc" ''
    {
      "$schema": "https://github.com/fastfetch-cli/fastfetch/raw/dev/doc/json_schema.json",
      "logo": {
        "source": "${nixos-logo}",
        "color": {
          "1": "red"
        },
        "padding": {
          "top": 1,
          "right": 2
        }
      },
      "display": {
        "separator": "  ",
        "color": {
          "keys": "red"
        },
        "key": {
          "width": 3
        }
      },
      "modules": [
        { "type": "break" },
        { "type": "break" },
        { "type": "break" },
        {
          "type": "title",
          "color": {
            "user": "red",
            "at": "red",
            "host": "red"
          }
        },
        { "type": "break" },
        { "type": "os",       "key": "◆ ",     "keyColor": "red" },
        { "type": "kernel",   "key": "◆ ",     "keyColor": "red" },
        { "type": "cpu",      "key": "◆ ",     "keyColor": "red" },
        { "type": "gpu",      "key": "◆ ",     "keyColor": "red" },
        { "type": "memory",   "key": "◆ ",     "keyColor": "red" },
        { "type": "disk",     "key": "◆ ",     "keyColor": "red" },
      ]
    }
  '';

  nf = pkgs.writeShellScriptBin "nf" ''
    ${pkgs.fastfetch}/bin/fastfetch --config ${fastfetch-config} "$@"
  '';
in
{
  home.packages = [
    pkgs.fastfetch
    nf
  ];
}
