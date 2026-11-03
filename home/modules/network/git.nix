{ lib, pkgs, ... }:

{
  programs.lazygit.enable = true;

  programs.git = {
    enable = true;
    settings = {
      user.name = "Herzaristide";
      user.email = "aristide.pichereau@gmail.com";
      init.defaultBranch = "main";
      pull.rebase = false;
      # Identifiants HTTPS fournis par les CLI : `gh auth login` pour github.com,
      # `glab auth login --hostname <host>` pour tout autre hôte. Le token va dans
      # GNOME Keyring quand il y en a un (postes),
      # sinon dans ~/.config/gh/hosts.yml / ~/.config/glab-cli (persistés dans
      # modules/impermanence.nix). Les remotes SSH ne passent pas par ici.
      credential.helper = "!${lib.getExe pkgs.glab} auth git-credential";
      # "" vide la liste : github.com ne demande qu'à gh.
      credential."https://github.com".helper = [
        ""
        "!${lib.getExe pkgs.gh} auth git-credential"
      ];
    };
  };

  # Helper déclaré à la main ci-dessus, avec glab comme repli pour les autres hôtes.
  programs.gh = {
    enable = true;
    settings = {
      git_protocol = "ssh";
      editor = "micro";
    };
    gitCredentialHelper.enable = false;
  };

  home.packages = [
    pkgs.glab # pas de module home-manager : supprimé upstream (#8066)
  ];
}
