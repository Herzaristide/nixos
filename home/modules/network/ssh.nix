{
  pkgs,
  lib,
  osConfig,
  ...
}:

let
  isHead = osConfig.head or false;

  # SSH_ASKPASS qui lit la passphrase de siddhartha dans GNOME Keyring au lieu
  # de la demander. Elle y est rangée une fois pour toutes, à la main :
  #   secret-tool store --label="SSH siddhartha" ssh-key siddhartha
  sshAskpassKeyring = pkgs.writeShellScript "ssh-askpass-keyring" ''
    exec ${pkgs.libsecret}/bin/secret-tool lookup ssh-key siddhartha
  '';
in
{
  services.ssh-agent.enable = true;

  # Postes graphiques : la clé est chargée dans ssh-agent dès l'ouverture de
  # session, le trousseau étant déverrouillé par pam_gnome_keyring au login.
  # On garde l'agent OpenSSH (celui de gnome-keyring rejette ed25519) : le
  # trousseau ne fournit que la passphrase. Si elle n'y est pas, ou si le
  # trousseau est verrouillé, l'unité échoue sans bloquer et `AddKeysToAgent`
  # redemande la passphrase au premier ssh, comme avant.
  home.packages = lib.mkIf isHead [ pkgs.libsecret ];

  systemd.user.services.ssh-add-siddhartha = lib.mkIf isHead {
    Unit = {
      Description = "Charge la clé SSH siddhartha depuis GNOME Keyring";
      After = [
        "ssh-agent.service"
        "gnome-keyring.service"
      ];
      Requires = [ "ssh-agent.service" ];
      PartOf = [ "graphical-session.target" ];
    };
    Service = {
      Type = "oneshot";
      Environment = [
        "SSH_AUTH_SOCK=%t/ssh-agent"
        "SSH_ASKPASS=${sshAskpassKeyring}"
        "SSH_ASKPASS_REQUIRE=force"
      ];
      ExecStart = "${pkgs.openssh}/bin/ssh-add %h/.ssh/siddhartha";
    };
    Install.WantedBy = [ "graphical-session.target" ];
  };

  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;
    # After the first unlock, keep keys in ssh-agent (no passphrase on every git/ssh).
    # Directives nommées comme dans ssh_config(5) (CamelCase upstream OpenSSH).
    settings = {
      # GitHub (clé siddhartha pour l'auth)
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
      # Serveur gary (clé siddhartha — même clé que GitHub, autorisée via modules/common.nix).
      # IP Tailscale : fixe tant que le nœud n'est pas réenregistré, et joignable
      # hors du LAN, contrairement à l'ancienne 192.168.1.138 (DHCP).
      "gary" = {
        AddKeysToAgent = "yes";
        HostName = "100.90.139.70";
        User = "aristide";
        IdentityFile = "~/.ssh/siddhartha";
        IdentitiesOnly = true;
      };
      # Laptop bernanos, via Tailscale (pour l'atteindre depuis gary).
      "bernanos" = {
        AddKeysToAgent = "yes";
        HostName = "100.67.220.15";
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
