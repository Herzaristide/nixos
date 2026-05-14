{ pkgs, ... }:

{
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
      # GCM on Linux requires an explicit store; WSL has no Secret Service by default.
      # plaintext: persistent (dev/WSL). Alternatives: cache, gpg (pass), secretservice (GUI).
      credential.credentialStore = "plaintext";
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
