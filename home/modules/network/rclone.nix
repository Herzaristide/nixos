{
  pkgs,
  config,
  osConfig,
  lib,
  ...
}:

let
  isHead = osConfig.head or false;

  # Nom du remote rclone. À créer une fois (Google Drive, OAuth interactif) :
  #   rclone config create gdrive drive scope=drive --all
  # Le flag --all lance le flux OAuth dans le navigateur ; sur un hôte sans
  # navigateur, faire `rclone authorize "drive"` sur une machine graphique et
  # coller le token. Aucun secret dans ce fichier : le token vit dans
  # ~/.config/rclone/rclone.conf, hors du repo git.
  remote = "gdrive";

  # Dossier local synchronisé bidirectionnellement avec la racine du Drive.
  localDir = "${config.home.homeDirectory}/cl0ud";

  # Fréquence de synchronisation.
  interval = "5m";

  # Dossiers régénérables : des dizaines de milliers de petits fichiers, sans
  # valeur une fois hors de leur machine. Drive facture la latence au fichier et
  # non à l'octet, donc les exclure change tout sur la durée d'un passage.
  # Syntaxe rclone : un motif sans « / » initial matche à n'importe quelle
  # profondeur, et « dir/** » exclut le contenu du dossier partout où il apparaît.
  filters = pkgs.writeText "rclone-filters-${remote}" ''
    # Environnements et dépendances (réinstallables)
    - .venv/**
    - venv/**
    - node_modules/**
    - vendor/**
    # Caches de build et d'outillage
    - __pycache__/**
    - .mypy_cache/**
    - .pytest_cache/**
    - .ruff_cache/**
    - .direnv/**
    - target/**
    - dist/**
    - build/**
    - .cache/**
    # Dépôts git : l'historique a déjà un remote, le dupliquer ici n'aide personne
    - .git/**
    # Liens de build Nix (pointent vers /nix/store, inutilisables ailleurs)
    - result
    - result-*
    # Bruit d'OS et fichiers compilés
    - .DS_Store
    - Thumbs.db
    - *.pyc
    - *.pyo
  '';

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
      # Les Docs/Sheets/Slides natifs n'ont pas de contenu téléchargeable :
      # bisync échouerait dessus à chaque passage.
      --drive-skip-gdocs
      --filter-from ${filters}
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
