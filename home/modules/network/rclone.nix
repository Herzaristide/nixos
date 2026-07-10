{
  pkgs,
  config,
  osConfig,
  lib,
  ...
}:

let
  isHead = osConfig.head or false;

  # Nom du remote rclone (défini une fois via `rclone config`, voir bootstrap plus bas).
  remote = "gdrive";

  # Dossier local synchronisé bidirectionnellement avec la racine du Drive.
  localDir = "${config.home.homeDirectory}/gdrive";

  # Fréquence de synchronisation.
  interval = "5m";

  # Wrapper bisync : au tout premier lancement il n'existe aucun état de référence,
  # rclone refuse alors de tourner sans --resync. On détecte ce cas et on établit
  # la baseline automatiquement, puis les runs suivants sont incrémentaux.
  #
  # Flags de robustesse (recommandés par la doc rclone pour bisync non-interactif) :
  #   --resilient / --recover : reprend après une interruption au lieu de rester bloqué
  #   --max-lock              : libère un verrou périmé si une exécution a été tuée
  #   --conflict-resolve newer: en cas d'édition des deux côtés, garde le plus récent
  bisync = pkgs.writeShellScript "rclone-bisync-${remote}" ''
    set -euo pipefail
    RCLONE=${pkgs.rclone}/bin/rclone

    common=(
      "${remote}:" "${localDir}"
      --create-empty-src-dirs
      --resilient --recover
      --max-lock 2m
      --conflict-resolve newer
      --transfers 8
      --log-level INFO
    )

    # La baseline existe-t-elle déjà pour cette paire ?
    if $RCLONE bisync "''${common[@]}" 1>/dev/null 2>&1; then
      exit 0
    fi

    # Sinon : soit première exécution, soit état corrompu → on refait la baseline.
    echo "bisync: pas d'état de référence, exécution --resync"
    exec $RCLONE bisync "''${common[@]}" --resync
  '';
in
lib.mkIf isHead {
  home.packages = [ pkgs.rclone ];

  systemd.user.services.rclone-bisync = {
    Unit = {
      Description = "Synchronisation bidirectionnelle ${remote} <-> ${localDir}";
      # Inutile de tenter la synchro sans réseau.
      After = [ "network-online.target" ];
      Wants = [ "network-online.target" ];
    };
    Service = {
      Type = "oneshot";
      # Crée le dossier local avant la première synchro.
      ExecStartPre = "${pkgs.coreutils}/bin/mkdir -p ${localDir}";
      ExecStart = "${bisync}";
    };
  };

  systemd.user.timers.rclone-bisync = {
    Unit.Description = "Timer de synchronisation ${remote}";
    Timer = {
      OnBootSec = "2m";
      OnUnitActiveSec = interval;
      Persistent = true;
    };
    Install.WantedBy = [ "timers.target" ];
  };
}
