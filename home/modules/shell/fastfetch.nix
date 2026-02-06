{ config, pkgs, ... }:

let
  fastfetch-config = pkgs.writeText "config.jsonc" ''
    {
      "$schema": "https://github.com/fastfetch-cli/fastfetch/raw/dev/doc/json_schema.json",
      "logo": {
        "source": "nixos",
        "padding": {
          "top": 8,
          "right": 8
        }
      },
      "display": {
        "separator": " ",
        "color": {
          "keys": "magenta"
        },
        "key": {
            "width": 3
        }
      },
      "modules": [
        {
          "type": "title",
          "color": {
              "user": "magenta",
              "at": "grey",
              "host": "magenta"
          }
        },
        {
          "type": "os",
          "key": "\uf004",
          "keyColor": "magenta"
        },
        {
          "type": "kernel",
          "key": "\ue23a",
          "keyColor": "magenta"
        },
        {
          "type": "memory",
          "key": "\uf35b",
          "keyColor": "magenta"
        },
        {
          "type": "packages",
          "key": "\uf0e5",
          "keyColor": "magenta"
        },
        {
          "type": "uptime",
          "key": "\uf017",
          "keyColor": "magenta"
        },
        {
          "type": "colors",
          "key": "\ue22b",
          "symbol": "block"
        }
      ]
    }
  '';

  nf = pkgs.writeShellScriptBin "nf" ''
    ${pkgs.fastfetch}/bin/fastfetch --config ${fastfetch-config} "$@"
  '';
in
{
  programs.fastfetch = {
    enable = true;
    package = pkgs.fastfetch;
  };

  home.packages = [ nf ];
}
