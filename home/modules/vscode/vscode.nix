{ pkgs, ... }:

let
  # Import shared VSCode configuration (used by both Cursor and VSCode)
  vscodeShared = import ./vscode-settings.nix { inherit pkgs; };

  # Custom keybindings
  keybindings = [
    {
      key = "alt+a";
      command = "editor.action.commentLine";
      when = "editorTextFocus && !editorReadonly";
    }
  ];
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
        keybindings = keybindings;
      };
    };
  };

  # Apply same settings and keybindings to VSCode (Code uses ~/.config/Code/, Cursor uses programs.vscode above)
  home.file.".config/Code/User/settings.json" = {
    text = builtins.toJSON vscodeShared.settings;
  };

  home.file.".config/Code/User/keybindings.json" = {
    text = builtins.toJSON keybindings;
  };
}
