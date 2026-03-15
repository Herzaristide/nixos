{ pkgs, lib, ... }:

let
  # Import shared VSCode configuration
  vscodeShared = import ./vscode-settings.nix { inherit pkgs; };

  # Extensions pre-installed on all SSH remote servers (cursor-server / vscode-server).
  # These are symlinked into ~/.cursor-server/extensions/ and ~/.vscode-server/extensions/
  # so the remote server finds them immediately without downloading from the marketplace.
  serverExtensions = vscodeShared.extensions;

  # Machine-level settings applied to all remote server sessions.
  # Written to ~/.cursor-server/data/Machine/settings.json (and vscode-server equivalent).
  serverSettings = vscodeShared.settings;

  settingsJson = builtins.toJSON serverSettings;

  # Build a shell snippet that symlinks all extensions from the nix store.
  # Each vscode extension in nixpkgs lives at ${pkg}/share/vscode/extensions/<id>/
  linkExtensions = lib.concatMapStrings (ext: ''
    for d in "${ext}/share/vscode/extensions"/*/; do
      ln -sfn "$d" "$extDir/$(basename "$d")"
    done
  '') serverExtensions;
in

{
  # Machine-level settings for both remote server variants
  home.file.".cursor-server/data/Machine/settings.json".text = settingsJson;
  home.file.".vscode-server/data/Machine/settings.json".text = settingsJson;

  # Symlink extensions from the nix store into the server extension directories
  home.activation.vscodeRemoteExtensions = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    for serverDir in "$HOME/.cursor-server" "$HOME/.vscode-server"; do
      extDir="$serverDir/extensions"
      mkdir -p "$extDir"
      ${linkExtensions}
    done
  '';
}
