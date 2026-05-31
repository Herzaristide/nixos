# Déverrouillage LUKS à distance par SSH dans l'initrd.
#
# Au boot, l'initrd démarre systemd-networkd (DHCP) et un serveur SSH sur le
# port 2222. Connecte-toi avec :
#
#     ssh -p 2222 root@<ip-de-la-machine>
#
# Tu seras déposé sur l'invite de mot de passe ; tape la passphrase LUKS puis
# la connexion se ferme et le boot reprend.
#
# Prérequis (à exécuter UNE FOIS par hôte, hors Nix car la clé d'hôte ne doit
# pas vivre dans le store) :
#
#     sudo mkdir -p /etc/secrets/initrd
#     sudo ssh-keygen -t ed25519 -N "" -f /etc/secrets/initrd/ssh_host_ed25519_key
#
# Puis `sudo nixos-rebuild switch` et reboot.
{ ... }:

{
  boot.initrd = {
    # initrd basé sur systemd — nécessaire pour systemd-networkd + ssh fiable
    systemd.enable = true;

    # Pilotes réseau usuels (Intel / Realtek / Broadcom / virtio).
    # Inoffensif d'en charger qui ne correspondent pas au matériel.
    availableKernelModules = [
      "e1000e"
      "r8169"
      "r8125"
      "igb"
      "igc"
      "tg3"
      "virtio_net"
    ];

    network = {
      enable = true;
      ssh = {
        enable = true;
        port = 2222;
        hostKeys = [ "/etc/secrets/initrd/ssh_host_ed25519_key" ];
        authorizedKeys = [
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICpZkVir2j2/+z/E6eqLaGrWiR9ukLCE00YCMOx51KyT aristide.pichereau@gmail.com"
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINi5jJe0xviTwThXWub9t7JdgvJ4OSKhhPfGJSyXbpEg aristide.pichereau@gmail.com"
        ];
      };
    };

    # DHCP sur la première interface filaire détectée
    systemd.network.networks."10-wired" = {
      matchConfig.Name = "en* eth*";
      networkConfig.DHCP = "yes";
    };
  };

  # Ouvrir 2222 dans le firewall (utile uniquement si le système bootté
  # devait aussi exposer le port, mais on reste cohérent).
  networking.firewall.allowedTCPPorts = [ 2222 ];
}
