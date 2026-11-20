# Ce que la flotte d'anna (karenine, servers.rs) lit d'une machine : en HTTP
# sur le tailnet plutôt que par ssh. node_exporter sert les mesures standard
# (CPU, mémoire, uptime, charge, température, systèmes de fichiers) et, par son
# collecteur textfile (/run/node-exporter), deux fichiers :
#   - extras.prom : disques physiques, services IA, Wake-on-LAN, écrit par
#     node-extras (script du flake karenine), ici, sur chaque hôte ;
#   - gpu.prom : le GPU, écrit par un service gpu-metrics propre à la machine,
#     déclaré dans son configuration.nix (bernanos, gary ; pas ailleurs).
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
    extraFlags = [ "--collector.textfile.directory=${dir}" ];
  };

  networking.firewall.interfaces.tailscale0.allowedTCPPorts = [ node.port ];

  # Partagé par node-extras et gpu-metrics : pas de RuntimeDirectory, qui
  # appartiendrait à un seul service. Lisible par node_exporter (utilisateur
  # dynamique).
  systemd.tmpfiles.rules = [ "d ${dir} 0755 root root -" ];

  systemd.services.node-extras = {
    description = "Disques, services IA et Wake-on-LAN pour node_exporter (anna)";
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
