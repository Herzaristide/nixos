# Agents Claude autonomes, directement sur l'hôte, sous l'utilisateur `claude`.
#
# Importé par les serveurs de dev (gary, kafka). Remplace les microVM de dev
# (ex-modules/devbox.nix, retiré le 2026-10-18) : presque tous les projets ont
# besoin du GPU, qu'une VM ne pouvait avoir qu'en passthrough (carte retirée à
# l'hôte, RAM de la VM figée). L'hôte est vidé de
# tout secret personnel ; la frontière passe entre deux comptes Unix :
#   - `aristide` : administration (wheel) et travail supervisé ;
#   - `claude`   : agents sans supervision. Pas de wheel ni de sudo, home en 0700
#     des deux côtés, réseau limité à Internet, RAM plafonnée.
#
# À faire une fois sous `claude` (`ssh claude@<hôte>`) : `gh auth login` avec un
# token fine-grained (dépôts choisis, Contents + Pull requests, sans Workflows,
# jamais le dépôt nixos), `claude auth login`, puis pour chaque dépôt cloné dans
# ~/code : `claude remote-control` une fois pour accepter RC et la confiance au dossier.
{
  config,
  lib,
  pkgs,
  ...
}:

let
  uid = 1001;
  host = config.networking.hostName;
  # GPU de calcul disponible (gary : RX 7600 XT) ; kafka n'en a pas.
  rocm = config.nixpkgs.config.rocmSupport or false;
in
{
  # Clé d'exupery : elle n'ouvre que les serveurs de dev (ce module), pas les
  # autres hôtes ni GitHub, contrairement aux clés de modules/common.nix.
  # S'ajoute à la liste commune, donc vaut aussi pour `claude` (ci-dessous).
  users.users.aristide.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILxa24l5t4C9ZHBE6NDE823vui27oYX2bQuTLtDY3lY/ aristide@exupery"
  ];

  users.users.claude = {
    isNormalUser = true;
    inherit uid;
    homeMode = "700";
    description = "Agents Claude Code autonomes";
    shell = pkgs.fish;
    # Pas de mot de passe : connexion par clé seulement.
    openssh.authorizedKeys.keys = config.users.users.aristide.openssh.authorizedKeys.keys;
    # GPU (ROCm : /dev/kfd et /dev/dri) ; volontairement ni wheel ni docker.
    extraGroups = [
      "video"
      "render"
    ];
    # Les services utilisateur (Remote Control, Docker rootless) tournent sans session ouverte.
    linger = true;
  };

  # /home est remis à zéro à chaque boot (modules/impermanence.nix, importé par
  # chaque hôte qui importe ce module) : seul ce qui suit survit. Les clones vont
  # dans ~/code, car impermanence ne sait pas persister la racine d'un home.
  environment.persistence."/keep".users.claude = {
    files = [
      ".claude.json"
      ".local/share/fish/fish_history"
    ];
    directories = [
      "code"
      ".claude" # session claude.ai (credentials), réglages, historique
      {
        directory = ".config/gh"; # token GitHub fine-grained
        mode = "0700";
      }
      ".local/share/docker" # Docker rootless : images, conteneurs, volumes
      ".docker"
      ".local/share/direnv" # allow-list des devShells
      ".local/share/rtk"
      # Caches lourds à reconstruire : paquets Python, modèles, shaders.
      ".local/share/uv"
      ".cache/uv"
      ".cache/huggingface"
      ".cache/mesa_shader_cache"
    ];
  };

  # Plafond de toute la session de `claude` (services, Docker rootless, builds) :
  # un agent qui dérape ne fait pas tomber l'hôte. En pourcentage de la RAM, pour
  # valoir sur chaque hôte (24 Gio sur les 30 de gary). CPUWeight sous la valeur par
  # défaut (100) : une session interactive d'aristide garde la main.
  systemd.slices."user-${toString uid}" = {
    overrideStrategy = "asDropin";
    sliceConfig = {
      MemoryHigh = "65%";
      MemoryMax = "80%";
      CPUWeight = 50;
    };
  };

  # `claude` sort vers Internet, pas vers le LAN, le tailnet ni les autres plages
  # privées. Le DNS passe par systemd-resolved sur 127.0.0.53, d'où l'exception
  # pour le loopback ; les réponses aux connexions entrantes (apps ouvertes depuis
  # le tailnet, ssh) restent permises. Table mangle, pas filter : même raison que
  # l'ex-chaîne devbox-fwd, tailscaled insère ses propres règles d'acceptation en
  # tête de filter.
  networking.firewall.extraCommands = ''
    for ipt in iptables ip6tables; do
      $ipt -w -t mangle -N agents-out 2>/dev/null || $ipt -w -t mangle -F agents-out
      $ipt -w -t mangle -D OUTPUT -m owner --uid-owner ${toString uid} -j agents-out 2>/dev/null || true
      $ipt -w -t mangle -I OUTPUT -m owner --uid-owner ${toString uid} -j agents-out
      $ipt -w -t mangle -A agents-out -o lo -j RETURN
      $ipt -w -t mangle -A agents-out -m conntrack --ctstate ESTABLISHED,RELATED -j RETURN
    done
    for net in 10.0.0.0/8 172.16.0.0/12 192.168.0.0/16 100.64.0.0/10 169.254.0.0/16; do
      iptables -w -t mangle -A agents-out -d "$net" -j DROP
    done
    # fc00::/7 couvre aussi le préfixe Tailscale fd7a:115c:a1e0::/48.
    for net in fc00::/7 fe80::/10; do
      ip6tables -w -t mangle -A agents-out -d "$net" -j DROP
    done
  '';
  networking.firewall.extraStopCommands = ''
    for ipt in iptables ip6tables; do
      $ipt -w -t mangle -D OUTPUT -m owner --uid-owner ${toString uid} -j agents-out 2>/dev/null || true
      $ipt -w -t mangle -F agents-out 2>/dev/null || true
      $ipt -w -t mangle -X agents-out 2>/dev/null || true
    done
  '';

  home-manager.users.claude =
    { ... }:
    {
      # Même shell et même Claude Code (réglages, LSP, rtk, tous les MCP)
      # qu'aristide ; rien d'autre de home/ : le reste embarque des clés et des
      # accès (ssh, git-credential-manager, coffre).
      imports = [
        ../home/modules/shell
        ../home/modules/code/ia/common.nix
      ];
      home.stateVersion = "25.11";

      programs.claude-code.context = ''
        # Environnement

        Tu tournes sur `${host}`, serveur de dev de l'utilisateur, sous le compte
        `claude` : pas de sudo, réseau limité à Internet (ni LAN ni tailnet).${lib.optionalString rocm " Le GPU (AMD RX 7600 XT, ROCm) est disponible."} Les apps sont joignables depuis
        le tailnet sous `http://${host}:<port>`, comme une préprod.

        ## Les projets

        - Les projets sont clonés dans `~/code` (`~/code/<projet>`), seul
          dossier de travail qui survit au reboot : rien d'autre dans `~`. Les sessions
          lancées depuis claude.ai/code ou l'app mobile ont chacune leur git
          worktree : travaille dedans, sur sa branche, jamais sur `main`.
        - Une feature finie : commit, push de la branche, puis Pull Request avec `gh pr
          create`. Ne merge jamais toi-même, c'est l'utilisateur qui relit et merge.
        - Les outils du projet viennent de son `flake.nix` (`nix develop`, ou direnv
          après `direnv allow` dans le worktree).

        ## Montrer ton travail

        - **8000-8009 sont réservés à la préprod** du projet (sa pile
          `docker-compose.preprod.yml`, projet compose `<nom>-preprod`) : n'y touche pas,
          ne l'arrête pas, ne réutilise pas ses volumes.
        - Pour faire tester ton travail, expose-le sur un port de **8010-8099**, en
          écoutant sur `0.0.0.0` (pas `127.0.0.1`), puis donne l'URL
          `http://${host}:<port>`.
        - Plusieurs tâches tournent en parallèle sur ce serveur : avant de prendre un
          port, vérifie qu'il est libre (`ss -ltn`) et ne coupe jamais un service que tu
          n'as pas lancé.
        - Avec Docker Compose (rootless), publie le port de cette plage
          (`ports: ["8010:3000"]`) ; garde les ports internes des services tels quels.
          Donne au projet un nom propre au worktree (`docker compose -p <dépôt>-<branche>`)
          pour ne pas écraser les conteneurs d'une autre session sur le même dépôt.
      ''
      + lib.optionalString rocm ''
        - Le GPU est partagé avec les autres sessions : libère-le (arrête le
          processus) quand tu as fini.
      '';

      programs.git = {
        enable = true;
        settings = {
          user.name = "Herzaristide";
          user.email = "aristide.pichereau@gmail.com";
          init.defaultBranch = "main";
          # Identifiants fournis par `gh auth login`, rangés dans ~/.config/gh.
          credential."https://github.com".helper = "!${lib.getExe pkgs.gh} auth git-credential";
        };
      };
      home.packages = with pkgs; [
        gh
        docker-compose
        ripgrep
        fd
        jq
        curl
      ];

      # Même mapping gfx1102 → gfx1100 que la variable système de l'hôte, que les
      # services utilisateur ne voient pas (environment.variables = sessions seules).
      systemd.user.sessionVariables = lib.mkIf rocm { HSA_OVERRIDE_GFX_VERSION = "11.0.0"; };

      # Remote Control permanent, à la manière des sessions cloud : chaque dépôt
      # git cloné dans ~/code est servi à claude.ai/code et à l'app mobile
      # sous `<hôte>-<dépôt>`, chaque session lancée de là-bas dans son propre git
      # worktree. Tant que `claude auth login` puis `claude remote-control` n'ont
      # pas été faits à la main dans le dépôt, l'instance échoue et réessaie.
      systemd.user.services."claude-rc@" = {
        Unit = {
          Description = "Claude Code Remote Control pour ~/code/%I";
          After = [ "network-online.target" ];
          ConditionPathExists = "%h/code/%I/.git";
          StartLimitIntervalSec = 0;
        };
        Service = {
          WorkingDirectory = "%h/code/%I";
          # PATH d'une session : claude, git, nix, docker. direnv charge le
          # devShell du projet, hérité par les sessions et leurs commandes.
          Environment = [
            "PATH=/etc/profiles/per-user/claude/bin:/run/current-system/sw/bin:/run/wrappers/bin"
          ];
          ExecStart = "${pkgs.direnv}/bin/direnv exec %h/code/%I claude remote-control --spawn worktree --permission-mode acceptEdits --remote-control-session-name-prefix ${host}-%I";
          Restart = "always";
          RestartSec = 30;
        };
      };
      # Démarre une instance par dépôt de ~/code, au boot puis chaque minute : un dépôt
      # tout juste cloné est servi sans rien déclarer. Démarrer une instance déjà
      # active ne fait rien.
      systemd.user.services.claude-rc-scan = {
        Unit.Description = "Remote Control pour chaque dépôt git de ~/code";
        Service = {
          Type = "oneshot";
          ExecStart = toString (
            pkgs.writeShellScript "claude-rc-scan" ''
              for git in "$HOME"/code/*/.git; do
                [ -e "$git" ] || continue
                repo=$(basename "$(dirname "$git")")
                ${pkgs.systemd}/bin/systemctl --user start --no-block \
                  "claude-rc@$(${pkgs.systemd}/bin/systemd-escape "$repo").service"
              done
            ''
          );
        };
      };
      systemd.user.timers.claude-rc-scan = {
        Unit.Description = "Cherche les nouveaux dépôts de ~/code à servir";
        Timer = {
          OnStartupSec = "10s";
          OnUnitActiveSec = "1min";
        };
        Install.WantedBy = [ "timers.target" ];
      };
    };
}
