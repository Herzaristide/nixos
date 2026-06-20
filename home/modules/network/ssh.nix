{ ... }:

{
  services.ssh-agent.enable = true;

  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;
    # After the first unlock, keep keys in ssh-agent (no passphrase on every git/ssh).
    # Directives nommées comme dans ssh_config(5) (CamelCase upstream OpenSSH).
    settings = {
      # GitHub (clé siddhartha pour auth + signing)
      "github.com" = {
        AddKeysToAgent = "yes";
        HostName = "github.com";
        User = "git";
        IdentityFile = "~/.ssh/siddhartha";
        IdentitiesOnly = true;
      };
      # GitLab (clé sisyphe)
      #"gitlab.com" = {
      #  HostName = "gitlab.com";
      #  User = "git";
      #  IdentityFile = "~/.ssh/sisyphe";
      #  IdentitiesOnly = true;
      #};
      # Serveur gary (clé siddhartha — même clé que GitHub, autorisée via modules/common.nix)
      "gary" = {
        AddKeysToAgent = "yes";
        HostName = "192.168.1.138";
        User = "aristide";
        IdentityFile = "~/.ssh/siddhartha";
        IdentitiesOnly = true;
      };
      # Serveur kafka (NixOS headless, voir hosts/kafka/configuration.nix)
      "kafka" = {
        AddKeysToAgent = "yes";
        HostName = "192.168.1.143";
        User = "aristide";
        IdentityFile = "~/.ssh/siddhartha";
        IdentitiesOnly = true;
      };
    };
  };
}
