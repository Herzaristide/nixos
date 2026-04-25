{ pkgs, lib, ... }:

let
  # `nf` invokes fastfetch with one of two configs generated at runtime by
  # accent-sync (see home/modules/accent/accent.nix). The configs live under
  # ~/.config/accent/ and are regenerated whenever the accent color changes.
  nf = pkgs.writeShellScriptBin "nf" ''
    CFG_DIR="$HOME/.config/accent"
    CFG_FULL="$CFG_DIR/fastfetch-full.jsonc"
    CFG_LOGO="$CFG_DIR/fastfetch-logo.jsonc"

    # Bail gracefully if accent-sync hasn't run yet.
    if [ ! -f "$CFG_FULL" ] || [ ! -f "$CFG_LOGO" ]; then
      exec ${pkgs.fastfetch}/bin/fastfetch "$@"
    fi

    COLS=$(${pkgs.ncurses}/bin/tput cols 2>/dev/null || echo 80)

    if [ "$COLS" -lt 80 ]; then
      exec ${pkgs.fastfetch}/bin/fastfetch --config "$CFG_LOGO" "$@"
    else
      exec ${pkgs.fastfetch}/bin/fastfetch --config "$CFG_FULL" "$@"
    fi
  '';
in
{
  home.packages = [
    pkgs.fastfetch
    nf
  ];
}
