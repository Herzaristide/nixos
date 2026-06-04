{ pkgs, ... }:

{
  # --- Kernel hardening (sysctl) ---
  boot.kernel.sysctl = {
    # Hide kernel pointers from /proc — defeats kASLR leak via /proc/kallsyms
    "kernel.kptr_restrict" = 2;
    # Restrict dmesg to root — exfil source for kernel addresses, hardware info
    "kernel.dmesg_restrict" = 1;
    # ptrace_scope=1: a non-root process can only ptrace its descendants.
    # Blocks an attacker who compromises one user-process from dumping memory
    # of other user processes (e.g. ssh-agent, browser session keys).
    "kernel.yama.ptrace_scope" = 1;

    # TCP/IP hardening
    "net.ipv4.tcp_syncookies" = 1; # SYN flood mitigation (default-on on recent kernels, declared for clarity)
    "net.ipv4.conf.all.rp_filter" = 1; # Strict reverse-path (anti-spoofing)
    "net.ipv4.conf.default.rp_filter" = 1;
    "net.ipv4.conf.all.accept_redirects" = 0; # Ignore ICMP redirects
    "net.ipv4.conf.default.accept_redirects" = 0;
    "net.ipv4.conf.all.send_redirects" = 0;
    "net.ipv6.conf.all.accept_redirects" = 0;
    "net.ipv6.conf.default.accept_redirects" = 0;
    "net.ipv4.conf.all.accept_source_route" = 0; # Drop source-routed packets
    "net.ipv6.conf.all.accept_source_route" = 0;
    "net.ipv4.conf.all.log_martians" = 1; # Log spoofed packets to dmesg
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

  # --- fail2ban: SSH brute-force protection ---
  # Still relevant even after disabling password auth: it deals with the constant
  # noise of scanners hitting :22 and the few key-auth attempts they try.
  services.fail2ban = {
    enable = true;
    maxretry = 5;
    bantime = "1h";
    bantime-increment = {
      enable = true;
      multipliers = "1 2 4 8 16 32 64";
      maxtime = "168h"; # 1 week
    };
    # Pre-built jail for sshd, enabled by default in NixOS when fail2ban is enabled.
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
