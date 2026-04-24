{
  config,
  pkgs,
  inputs,
  head ? false,
  ...
}:

{
  imports = [
    ./modules/shell
    ./modules/vscode/vscode-server.nix
  ]
  ++ (
    if head then
      [
        ./head.nix
      ]
    else
      [ ]
  );

  nixpkgs.config.allowUnfree = true;

  # Home Manager settings
  home.username = "aristide";
  home.homeDirectory = "/home/aristide";
  home.stateVersion = "25.11";

  # SSL certificate environment variables for all sessions
  home.sessionVariables = {
    SSL_CERT_FILE = "/etc/ssl/certs/ca-bundle.crt";
    NIX_SSL_CERT_FILE = "/etc/ssl/certs/ca-bundle.crt";
    NODE_TLS_REJECT_UNAUTHORIZED = "0";
    GIT_SSL_NO_VERIFY = "true";
  };

  home.file.".curlrc".text = "insecure\n";

  home.file.".wgetrc".text = "check_certificate = off\n";

  # Services
  services.ssh-agent.enable = true;

  # Programs available on all systems
  programs = {
    git = {
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
      };
      signing = {
        key = "~/.ssh/siddhartha.pub";
        signByDefault = true;
      };
    };

    ssh = {
      enable = true;
      enableDefaultConfig = false;
      # After the first unlock, keep keys in ssh-agent (no passphrase on every git/ssh)
      matchBlocks = {
        # GitHub (clé siddhartha pour auth + signing)
        "github.com" = {
          addKeysToAgent = "yes";
          hostname = "github.com";
          user = "git";
          identityFile = "~/.ssh/siddhartha";
          identitiesOnly = true;
        };
        # GitLab (clé sisyphe)
        #"gitlab.com" = {
        #  hostname = "gitlab.com";
        #  user = "git";
        #  identityFile = "~/.ssh/sisyphe";
        #  identitiesOnly = true;
        #};
        # Serveur gary (clé salammbo)
        "gary" = {
          addKeysToAgent = "yes";
          hostname = "192.168.1.138";
          user = "aristide";
          identityFile = "~/.ssh/salammbo";
          identitiesOnly = true;
        };
        # Serveur kafka (NixOS headless, voir hosts/kafka/configuration.nix)
        "kafka" = {
          addKeysToAgent = "yes";
          hostname = "192.168.1.64";
          user = "aristide";
          identityFile = "~/.ssh/salammbo";
          identitiesOnly = true;
        };
      };
    };

    direnv = {
      enable = true;
      nix-direnv.enable = true;
      enableFishIntegration = true;
    };
  };

  # Packages available on all systems (non-hardware)
  home.packages = with pkgs; [
    claude-code
    sox # Audio recording (required for Claude Code voice mode)
    gemini-cli
    mistral-vibe # Mistral Vibe CLI (`vibe`)
    git-credential-manager
    cmatrix # Matrix-style falling characters
    glances # Advanced system monitoring

    # Code formatters (pour autofmt plugin de micro)
    nixfmt # Nix
    prettier # JS/TS/JSON/YAML/Markdown/HTML/CSS
    black # Python
    shfmt # Shell scripts
    rustfmt # Rust
  ];
}
