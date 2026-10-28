{ pkgs, osConfig, ... }:

let
  isHead = osConfig.head or false;

  # Head hosts (zola, exupery) have GNOME Keyring as session daemon → secretservice.
  # Headless hosts (gary, kafka, wsl) fall back to in-memory cache (re-prompt after timeout).
  # The keyring is started as a systemd user service from home/head.nix, not left
  # to D-Bus activation — see the comment there.
  credentialStore = if isHead then "secretservice" else "cache";
in
{
  programs.lazygit.enable = true;

  programs.git = {
    enable = true;
    settings = {
      user.name = "Herzaristide";
      user.email = "aristide.pichereau@gmail.com";
      init.defaultBranch = "main";
      pull.rebase = false;
      # Git Credential Manager (HTTPS); SSH remotes still use ssh config above
      credential.helper = "${pkgs.git-credential-manager}/bin/git-credential-manager";
      credential.credentialStore = credentialStore;
      # Disable GCM's Avalonia GUI (broken on Wayland/Hyprland): use device code flow in terminal.
      credential.guiPrompt = "false";
    };
  };

  # gitCredentialHelper désactivé : git-credential-manager reste seul helper HTTPS.
  programs.gh = {
    enable = true;
    settings = {
      git_protocol = "ssh";
      editor = "micro";
    };
    gitCredentialHelper.enable = false;
  };

  home.packages = [
    pkgs.git-credential-manager
    pkgs.glab # pas de module home-manager : supprimé upstream (#8066)
  ];
}
