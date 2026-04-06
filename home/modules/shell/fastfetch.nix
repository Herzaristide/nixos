{ pkgs, lib, ... }:

let
  # ASCII art vendored in the flake (was fetchurl from Codeberg)
  nixos-logo = ../../../src/nixos_logo.txt;

  # Full configuration with hardware info
  fastfetch-config-full = pkgs.writeText "config-full.jsonc" ''
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

  # Logo-only configuration for small terminals
  fastfetch-config-logo = pkgs.writeText "config-logo.jsonc" ''
    {
      "$schema": "https://github.com/fastfetch-cli/fastfetch/raw/dev/doc/json_schema.json",
      "logo": {
        "source": "${nixos-logo}",
        "color": {
          "1": "red"
        },
        "padding": {
          "top": 1,
          "right": 0
        },
        "printRemaining": true
      },
      "modules": []
    }
  '';

  nf = pkgs.writeShellScriptBin "nf" ''
    # Get terminal width (default to 80 if tput fails)
    COLS=$(${pkgs.ncurses}/bin/tput cols 2>/dev/null || echo 80)

    # Use logo-only config if terminal width is less than 80 columns
    if [ "$COLS" -lt 80 ]; then
      ${pkgs.fastfetch}/bin/fastfetch --config ${fastfetch-config-logo} "$@"
    else
      ${pkgs.fastfetch}/bin/fastfetch --config ${fastfetch-config-full} "$@"
    fi
  '';
in
{
  home.packages = [
    pkgs.fastfetch
    nf
  ];
}
