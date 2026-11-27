# Ce que la flotte d'anna (karenine, servers.rs) lit d'une machine : en HTTP
# sur le tailnet plutôt que par ssh. node_exporter sert les mesures standard
# (CPU, mémoire, uptime, charge, température, systèmes de fichiers), les
# services systemd en échec (collecteur systemd) et, par son
# collecteur textfile (/run/node-exporter), deux fichiers :
#   - extras.prom : disques physiques et Wake-on-LAN, écrit par
#     node-extras (script du flake karenine), ici, sur chaque hôte ;
#   - gpu.prom : le GPU, écrit par un service gpu-metrics propre à la machine,
#     déclaré dans son configuration.nix (bernanos, gary ; pas ailleurs).
# Deux exporteurs de plus, lus par anna sur le même chemin :
#   - smartctl_exporter (:9633) : la santé SMART des disques (usure,
#     température, heures, secteurs réalloués), découverts seuls ;
#   - cAdvisor (:9080) : les conteneurs Docker (CPU, mémoire, réseau), ceux du
#     Docker rootless de l'utilisateur (common.nix).
# node_exporter lit aussi les compteurs RAPL (consommation du CPU en watts),
# réservés à root par défaut : un groupe `powercap` les lui ouvre.
#
# Importé par chaque hôte du tailnet (bernanos, exupery, gary, kafka), depuis
# son configuration.nix. L'extinction, le redémarrage et le secours d'un hôte
# muet sur 9100 passent toujours par ssh.
{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:

let
  dir = "/run/node-exporter";
  node = config.services.prometheus.exporters.node;
  node-extras = inputs.karenine.packages.${pkgs.stdenv.hostPlatform.system}.node-extras;
in
{
  services.prometheus.exporters.node = {
    enable = true;
    # Pas d'openFirewall : le port n'est ouvert que sur tailscale0 (ci-dessous).
    # systemd : les services en échec, un bouton sur la carte de la machine.
    enabledCollectors = [ "systemd" ];
    extraFlags = [
      "--collector.textfile.directory=${dir}"
      # Les services seulement : 5 lignes par unité, la page est lue chaque
      # seconde.
      "--collector.systemd.unit-include=.+\\.service"
    ];
  };

  networking.firewall.interfaces.tailscale0.allowedTCPPorts = [
    node.port
    config.services.prometheus.exporters.smartctl.port
    config.services.cadvisor.port
  ];

  # ── RAPL : la consommation du CPU ──
  # Les compteurs d'énergie (energy_uj) sont en 0400 root depuis l'attaque
  # PLATYPUS : plutôt que de les ouvrir à tous, un groupe dédié les lit, et
  # node_exporter (utilisateur dynamique) y entre.
  users.groups.powercap = { };
  services.udev.extraRules = ''
    ACTION=="add", SUBSYSTEM=="powercap", RUN+="${pkgs.coreutils}/bin/chgrp powercap /sys%p/energy_uj", RUN+="${pkgs.coreutils}/bin/chmod 0440 /sys%p/energy_uj"
  '';
  systemd.services.prometheus-node-exporter.serviceConfig.SupplementaryGroups = [ "powercap" ];

  # ── Les disques : smartctl_exporter ──
  # Pas d'openFirewall : ouvert sur tailscale0 seulement (ci-dessus).
  services.prometheus.exporters.smartctl.enable = true;

  # ── Les conteneurs : cAdvisor ──
  # Docker est rootless (common.nix) : le démon de l'utilisateur, pas celui du
  # système. Seuls les conteneurs Docker, et seulement CPU, mémoire, réseau :
  # sa page reste petite.
  services.cadvisor = {
    enable = true;
    listenAddress = "0.0.0.0";
    port = 9080;
    extraOptions = [
      "-docker=unix:///run/user/1000/docker.sock"
      "-docker_only=true"
      "-enable_metrics=cpu,memory,network"
      "-housekeeping_interval=10s"
    ];
  };

  # Partagé par node-extras et gpu-metrics : pas de RuntimeDirectory, qui
  # appartiendrait à un seul service. Lisible par node_exporter (utilisateur
  # dynamique).
  systemd.tmpfiles.rules = [ "d ${dir} 0755 root root -" ];

  systemd.services.node-extras = {
    description = "Disques et Wake-on-LAN pour node_exporter (anna)";
    path = [
      pkgs.util-linux
      pkgs.iproute2
      pkgs.systemd
    ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${lib.getExe node-extras} ${dir}";
      ReadWritePaths = [ dir ];
      ProtectSystem = "strict";
      ProtectHome = true;
      PrivateTmp = true;
      NoNewPrivileges = true;
    };
  };

  systemd.timers.node-extras = {
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnBootSec = "5s";
      OnUnitActiveSec = "15s";
      AccuracySec = "1s";
    };
  };
}
