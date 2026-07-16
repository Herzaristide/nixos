{ ... }:

{
  # --- Kernel hardening (sysctl) ---
  boot.kernel.sysctl = {
    "kernel.kptr_restrict" = 2;
    "kernel.dmesg_restrict" = 1;
    "kernel.yama.ptrace_scope" = 1;
    "net.ipv4.tcp_syncookies" = 1;
    "net.ipv4.conf.all.rp_filter" = 1;
    "net.ipv4.conf.default.rp_filter" = 1;
    "net.ipv4.conf.all.accept_redirects" = 0;
    "net.ipv4.conf.default.accept_redirects" = 0;
    "net.ipv4.conf.all.send_redirects" = 0;
    "net.ipv6.conf.all.accept_redirects" = 0;
    "net.ipv6.conf.default.accept_redirects" = 0;
    "net.ipv4.conf.all.accept_source_route" = 0;
    "net.ipv6.conf.all.accept_source_route" = 0;
    "net.ipv4.conf.all.log_martians" = 1;
  };

  security.apparmor = {
    enable = true;
    killUnconfinedConfinables = false;
  };

  # --- auditd: trace privilege escalations and config changes ---
  security.auditd.enable = true;
  security.audit = {
    # NOTE: désactivé temporairement — audit-userspace 4.1.2-unstable-2025-09-06
    # (snapshot pris par nixos-unstable) régressé : `auditctl -R` échoue sur la
    # directive `-b N` du rules file, audit-rules-nixos.service ne démarre plus.
    # auditd reste actif (logging kernel-side). Réactiver à `true` une fois le
    # package stabilisé upstream.
    enable = false;
    rules = [
      # Watch authentication / authorization config
      "-w /etc/sudoers -p wa -k sudoers"
      "-w /etc/passwd -p wa -k passwd"
      "-w /etc/shadow -p wa -k shadow"
      "-w /etc/group -p wa -k group"
      # Watch SSH server config
      "-w /etc/ssh/sshd_config -p wa -k sshd_config"
      # Watch NixOS declarative config
      "-w /etc/nixos -p wa -k nixos_config"
      # Log every sudo invocation
      "-a always,exit -F arch=b64 -S execve -F path=/run/wrappers/bin/sudo -k sudo_exec"
    ];
  };

  services.fail2ban = {
    enable = true;
    maxretry = 5;
    bantime = "1h";
    bantime-increment = {
      enable = true;
      multipliers = "1 2 4 8 16 32 64";
      maxtime = "168h"; # 1 week
    };
  };

  # --- LUKS auto-unlock via USB keyfile ---
  # Le keyfile (4096 octets) vit au début d'une partition GPT labellée "LUKSKEY"
  # sur une clé USB dédiée. systemd-cryptsetup résout le symlink au boot et lit
  # les 4096 premiers octets. Clé absente → fallback automatique sur la passphrase
  # après keyFileTimeout secondes. Partlabel choisi (et non vendor/product IDs)
  # parce que les clés USB bon marché ont des descripteurs USB instables.
  #
  # Préparation d'une clé USB neuve :
  #   sudo wipefs -a /dev/sdX
  #   sudo sgdisk -n 1:0:+1M -t 1:8300 -c 1:"LUKSKEY" /dev/sdX
  #   sudo dd if=/dev/urandom of=/dev/sdX1 bs=4096 count=1 conv=fsync
  #
  # Enrôlement sur une nouvelle machine :
  #   sudo cryptsetup luksAddKey /dev/<partition-luks> /dev/sdX1 --new-keyfile-size 4096
  #
  # Test sans reboot :
  #   sudo cryptsetup open --test-passphrase /dev/<partition-luks> _t \
  #     --key-file /dev/disk/by-partlabel/LUKSKEY --keyfile-size 4096 && echo OK
  boot.initrd.luks.devices.cryptroot = {
    keyFile = "/dev/disk/by-partlabel/LUKSKEY";
    keyFileSize = 4096;
    keyFileOffset = 0;
    keyFileTimeout = 20;
  };

  boot.loader.systemd-boot.editor = false;
}
