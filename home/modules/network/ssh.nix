{ ... }:

{
  # ssh-agent OpenSSH (celui de gnome-keyring rejette ed25519). siddhartha n'y
  # est plus chargée à l'ouverture de session (service ssh-add-siddhartha
  # retiré le 2026-11-03) : une clé chargée est utilisable en silence par tout
  # processus de la session. Elle l'est au premier ssh/git qui en a besoin
  # (`AddKeysToAgent`, passphrase demandée dans le terminal), puis oubliée par
  # l'agent au bout de 12 h (`AddKeysToAgent = "12h"`).
  services.ssh-agent.enable = true;

  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;
    # After the first unlock, keep keys in ssh-agent (no passphrase on every git/ssh).
    # Directives nommées comme dans ssh_config(5) (CamelCase upstream OpenSSH).
    settings = {
      # GitHub (clé siddhartha pour l'auth)
      "github.com" = {
        AddKeysToAgent = "12h";
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
      # Serveur gary (clé siddhartha — même clé que GitHub, autorisée via modules/common.nix).
      # IP Tailscale : fixe tant que le nœud n'est pas réenregistré, et joignable
      # hors du LAN, contrairement à l'ancienne 192.168.1.138 (DHCP).
      "gary" = {
        AddKeysToAgent = "12h";
        HostName = "100.90.139.70";
        User = "aristide";
        IdentityFile = "~/.ssh/siddhartha";
        IdentitiesOnly = true;
      };
      # Laptop bernanos, via Tailscale (pour l'atteindre depuis gary).
      "bernanos" = {
        AddKeysToAgent = "12h";
        HostName = "100.67.220.15";
        User = "aristide";
        IdentityFile = "~/.ssh/siddhartha";
        IdentitiesOnly = true;
      };
      # Serveur kafka (NixOS headless, voir hosts/kafka/configuration.nix)
      "kafka" = {
        AddKeysToAgent = "12h";
        HostName = "192.168.1.143";
        User = "aristide";
        IdentityFile = "~/.ssh/siddhartha";
        IdentitiesOnly = true;
      };
    };
  };
}
