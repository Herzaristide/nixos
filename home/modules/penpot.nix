{ pkgs, ... }:

let
  penpot-mcp = pkgs.writeShellScriptBin "penpot-mcp" ''
    export PNPM_CONFIG_STRICT_DEP_BUILDS=false
    exec ${pkgs.nodejs_22}/bin/npx -y @penpot/mcp@stable "$@"
  '';
in
{
  home.packages = [
    pkgs.penpot-desktop
    penpot-mcp
  ];
}
