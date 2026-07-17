{ pkgs, osConfig, ... }:

let
  isHead = osConfig.head or false;

  # Head hosts (zola, gary) have GNOME Keyring as session daemon → secretservice.
  # Headless hosts (kafka, exupery) fall back to in-memory cache (re-prompt after timeout).
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
      gpg.format = "ssh";
      commit.gpgSign = true;
      init.defaultBranch = "main";
      pull.rebase = false;
      # Git Credential Manager (HTTPS); SSH remotes still use ssh config above
      credential.helper = "${pkgs.git-credential-manager}/bin/git-credential-manager";
      credential.credentialStore = credentialStore;
      # Disable GCM's Avalonia GUI (broken on Wayland/Hyprland): use device code flow in terminal.
      credential.guiPrompt = "false";
    };
    signing = {
      key = "~/.ssh/siddhartha.pub";
      signByDefault = true;
    };
  };

  home.packages = [ pkgs.git-credential-manager ];
}
