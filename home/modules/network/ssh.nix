{ ... }:

{
  services.ssh-agent.enable = true;

  programs.ssh = {
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
      # Serveur gary (clé siddhartha — même clé que GitHub, autorisée via modules/common.nix)
      "gary" = {
        addKeysToAgent = "yes";
        hostname = "192.168.1.138";
        user = "aristide";
        identityFile = "~/.ssh/siddhartha";
        identitiesOnly = true;
      };
      # Serveur kafka (NixOS headless, voir hosts/kafka/configuration.nix)
      "kafka" = {
        addKeysToAgent = "yes";
        hostname = "192.168.1.106 ";
        user = "aristide";
        identityFile = "~/.ssh/siddhartha";
        identitiesOnly = true;
      };
    };
  };
}
