{ pkgs, ... }:

let
  # Import shared VSCode configuration
  vscodeShared = import ./vscode-settings.nix { inherit pkgs; };
in

{
  programs.vscode = {
    enable = true;
    package = pkgs.code-cursor;
    mutableExtensionsDir = true;
    profiles = {
      default = {
        extensions = vscodeShared.extensions;
        userSettings = vscodeShared.settings;
      };
    };
  };
}
