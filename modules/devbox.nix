# VMs de développement persistantes et génériques (microvm.nix + cloud-hypervisor).
#
# Ajouter une VM = une entrée sous son hôte dans `devbox-vms.nix`, puis rebuild.
# Importé par chaque hôte qui a des VMs (gary, zola).
#   - toujours allumées (autostart), et un `nixos-rebuild switch` ne les coupe pas
#     (restartIfChanged = false) : `systemctl restart microvm@<vm>` pour appliquer un changement ;
#   - état sous /var/lib/microvms/<vm>/ (sur @, hors impermanence de /home) ;
#   - /nix/store de gary partagé en lecture seule, overlay inscriptible remis à
#     zéro à chaque démarrage (la base Nix de l'invité l'oublierait de toute façon) ;
#   - aucun identifiant de l'hôte dans la VM : on s'y connecte soi-même une fois
#     (`gh auth login`, `claude`), les sessions restent sur le volume /home ;
#   - réseau : bridge `microvm` (sous-réseau de l'hôte) + NAT ; LAN, Tailscale et les autres
#     plages privées sont bloqués depuis les VMs (chaîne `devbox-fwd`).
#
# Accès depuis zola : `ssh <vm>` (ProxyJump gary, home/modules/network/ssh.nix) ;
# apps : http://<vm>:<port>, via la route Tailscale annoncée par l'hôte.
{
  config,
  inputs,
  lib,
  ...
}:

let
  hostCfg = (import ./devbox-vms.nix).${config.networking.hostName};
  inherit (hostCfg) vms subnet;

  bridge = "microvm";
  stateDir = "/var/lib/microvms";

  # MAC stable dérivée du nom (préfixe 02: = adresse administrée localement).
  macOf =
    name:
    let
      h = builtins.hashString "sha256" name;
      c = off: builtins.substring off 2 h;
    in
    "02:${c 0}:${c 2}:${c 4}:${c 6}:${c 8}";

  hostKeys = config.users.users.aristide.openssh.authorizedKeys.keys;

  mkDevVm = name: p: {
    restartIfChanged = false;
    config =
      { pkgs, ... }:
      {
        imports = [ inputs.home-manager.nixosModules.default ];

        system.stateVersion = "25.11";
        networking.hostName = name;

        microvm = {
          hypervisor = "cloud-hypervisor";
          # Permet à cloud-hypervisor de signaler le boot à systemd (sd_notify).
          vsock.cid = 100 + p.ip;
          inherit (p) mem vcpu;
          # Free page reporting : la VM rend à gary la RAM qu'elle n'utilise pas.
          balloon = true;

          shares = [
            {
              tag = "ro-store";
              proto = "virtiofs";
              source = "/nix/store";
              mountPoint = "/nix/.ro-store";
            }
          ];

          writableStoreOverlay = "/nix/.rw-store";
          preStart = "rm -f ${stateDir}/${name}/nix-overlay.img";

          volumes = [
            {
              image = "${stateDir}/${name}/home.img";
              mountPoint = "/home";
              size = 65536;
            }
            {
              image = "${stateDir}/${name}/docker.img";
              mountPoint = "/var/lib/docker";
              size = 65536;
            }
            {
              image = "${stateDir}/${name}/persist.img";
              mountPoint = "/persist";
              size = 256;
            }
            {
              image = "${stateDir}/${name}/nix-overlay.img";
              mountPoint = "/nix/.rw-store";
              size = 32768;
            }
          ];

          interfaces = [
            {
              type = "tap";
              id = "vm-${name}";
              mac = macOf name;
            }
          ];
        };

        # Réseau statique : pas de serveur DHCP sur l'hôte.
        networking.useNetworkd = true;
        systemd.network.networks."10-eth" = {
          matchConfig.MACAddress = macOf name;
          address = [ "${subnet}.${toString p.ip}/24" ];
          gateway = [ "${subnet}.1" ];
          dns = [
            "1.1.1.1"
            "9.9.9.9"
          ];
        };

        services.openssh = {
          enable = true;
          settings = {
            PasswordAuthentication = false;
            KbdInteractiveAuthentication = false;
            PermitRootLogin = "no";
          };
          # Le / de la VM est éphémère : sans ça, la clé d'hôte change à chaque boot.
          hostKeys = [
            {
              path = "/persist/ssh/ssh_host_ed25519_key";
              type = "ed25519";
            }
          ];
        };

        # La VM est la frontière d'isolation : root dedans ne touche pas gary.
        users.mutableUsers = false;
        users.users.aristide = {
          isNormalUser = true;
          uid = 1000;
          shell = pkgs.fish;
          extraGroups = [
            "wheel"
            "docker"
          ];
          openssh.authorizedKeys.keys = hostKeys;
          # Les sessions `claude --bg` survivent à la déconnexion SSH.
          linger = true;
        };
        security.sudo.wheelNeedsPassword = false;
        programs.fish.enable = true;

        # Consignes globales de Claude Code dans la VM (mémoire « managed », lue en
        # plus du CLAUDE.md de chaque projet).
        environment.etc."claude-code/CLAUDE.md".text = ''
          # Environnement

          Tu tournes dans la VM de dev `${name}` sur gary. Elle est joignable depuis le
          tailnet de l'utilisateur sous le nom `${name}`, comme une préprod.

          ## Le projet

          - La VM sert un seul projet, cloné dans `~/projet`. Les sessions lancées depuis
            claude.ai/code ou l'app mobile ont chacune leur git worktree : travaille
            dedans, sur sa branche, jamais sur `main`.
          - Une feature finie : commit, push de la branche, puis Pull Request avec `gh pr
            create`. Ne merge jamais toi-même, c'est l'utilisateur qui relit et merge.
          - Les outils du projet viennent de son `flake.nix` (`nix develop`, ou direnv
            après `direnv allow` dans le worktree).

          ## Montrer ton travail

          - Pour faire tester une app, expose-la sur un port de la plage **8000-8099**,
            en écoutant sur `0.0.0.0` (pas `127.0.0.1`), puis donne l'URL
            `http://${name}:<port>`.
          - Plusieurs tâches tournent en parallèle dans cette VM : avant de prendre un
            port, vérifie qu'il est libre (`ss -ltn`) et ne coupe jamais un service que tu
            n'as pas lancé.
          - Avec Docker Compose, publie le port de cette plage
            (`ports: ["8001:3000"]`) ; garde les ports internes des services tels quels.
        '';

        # Les ports applicatifs sont ouverts : la VM n'est joignable que depuis gary
        # et le tailnet (subnet router), jamais depuis le LAN.
        networking.firewall.allowedTCPPortRanges = [
          {
            from = 1024;
            to = 65535;
          }
        ];

        virtualisation.docker.enable = true;

        # /tmp est en RAM (/ de la VM en tmpfs) : les builds se font sur le volume de
        # l'overlay, remis à zéro à chaque démarrage de toute façon.
        systemd.services.nix-daemon.environment.TMPDIR = "/nix/.rw-store/build";

        nix.settings = {
          experimental-features = [
            "nix-command"
            "flakes"
          ];
          trusted-users = [ "aristide" ];
        };

        environment.systemPackages = with pkgs; [
          gh
          docker-compose
          micro
          ripgrep
          fd
          jq
          curl
        ];

        programs.git = {
          enable = true;
          config = {
            user.name = "Herzaristide";
            user.email = "aristide.pichereau@gmail.com";
            # Identifiants fournis par `gh auth login`, rangés dans ~/.config/gh.
            credential."https://github.com".helper = "!gh auth git-credential";
          };
        };

        # Environnement de l'utilisateur identique à zola et gary : le shell (fish,
        # starship, fastfetch, micro, yazi, direnv, zellij) et la partie commune de
        # Claude Code. Rien d'autre de home/ : le reste embarque des clés et des
        # accès (ssh, git-credential-manager, MCP à compte, coffre) qui n'ont rien
        # à faire ici.
        home-manager = {
          useGlobalPkgs = true;
          useUserPackages = true;
          # Un fichier déjà là (fish crée ~/.config/fish/config.fish au premier
          # lancement) est mis de côté au lieu de faire échouer l'activation.
          backupFileExtension = "hm-bak";
          users.aristide = {
            imports = [
              ../home/modules/shell
              # Réglages, LSP, rtk et MCP sans compte de Claude Code.
              ../home/modules/code/ia/common.nix
            ];
            home.stateVersion = "25.11";

            # Remote Control permanent, à la manière des sessions cloud : le projet
            # de la VM (un seul, cloné dans ~/projet) est servi à claude.ai/code et à
            # l'app mobile, et chaque session lancée de là-bas a son propre git
            # worktree. Une fois par VM à la main : `/login` (abonnement, pas de clé
            # API), puis `claude remote-control` dans ~/projet pour accepter RC et la
            # confiance au dossier, qui demandent un terminal ; d'ici là le service
            # échoue et réessaie. Sortant en HTTPS seulement.
            systemd.user.services.claude-rc = {
              Unit = {
                Description = "Claude Code Remote Control pour ~/projet";
                After = [ "network-online.target" ];
                ConditionPathExists = "%h/projet/.git";
                StartLimitIntervalSec = 0;
              };
              Service = {
                WorkingDirectory = "%h/projet";
                # PATH d'une session : claude, git, nix, docker. direnv charge le
                # devShell du projet, hérité par les sessions et leurs commandes.
                Environment = [
                  "PATH=/etc/profiles/per-user/aristide/bin:/run/current-system/sw/bin:/run/wrappers/bin"
                ];
                ExecStart = "${pkgs.direnv}/bin/direnv exec %h/projet claude remote-control --spawn worktree --permission-mode acceptEdits --remote-control-session-name-prefix ${name}";
                Restart = "always";
                RestartSec = 30;
              };
              Install.WantedBy = [ "default.target" ];
            };
            # Démarre le service dès que le dépôt est cloné, sans attendre un reboot.
            systemd.user.paths.claude-rc = {
              Unit.Description = "Attend le clone de ~/projet";
              Path.PathExists = "%h/projet/.git";
              Install.WantedBy = [ "default.target" ];
            };
          };
        };

        systemd.tmpfiles.rules = [
          "d /persist/ssh 0700 root root -"
          # Créé par NixOS avant le montage du volume /home, qui le masque ensuite.
          "d /home/aristide 0700 aristide users -"
          "d /nix/.rw-store/build 0755 root root -"
        ];
      };
  };
in
{
  imports = [ inputs.microvm.nixosModules.host ];

  microvm.vms = lib.mapAttrs mkDevVm vms;

  # Pas de copy-on-write btrfs sur les images disque des VMs : sans ça, chaque
  # écriture de la VM les fragmente. L'attribut n'agit que sur les fichiers créés
  # après lui, d'où sa pose avant le premier démarrage.
  systemd.tmpfiles.rules = [ "h ${stateDir} - - - - +C" ];

  # Bridge interne des VMs, géré par networkd ; NetworkManager l'ignore.
  systemd.network = {
    enable = true;
    wait-online.enable = false;
    netdevs."10-${bridge}".netdevConfig = {
      Kind = "bridge";
      Name = bridge;
    };
    networks."10-${bridge}" = {
      matchConfig.Name = bridge;
      address = [ "${subnet}.1/24" ];
      linkConfig.RequiredForOnline = "no";
    };
    networks."11-microvm-tap" = {
      matchConfig.Name = "vm-*";
      networkConfig.Bridge = bridge;
      linkConfig.RequiredForOnline = "no";
    };
  };
  networking.networkmanager.unmanaged = [
    "interface-name:${bridge}"
    "interface-name:vm-*"
  ];

  networking.nat = {
    enable = true;
    internalInterfaces = [ bridge ];
  };

  # Subnet router : le réseau des VMs est annoncé sur le tailnet, les apps y sont
  # joignables comme une préprod (http://dev1:8000 depuis le tailnet). La route doit
  # être approuvée une fois dans la console Tailscale. Seul le tailnet entre :
  # les VMs, elles, ne peuvent toujours pas ouvrir de connexion vers lui.
  services.tailscale.useRoutingFeatures = lib.mkForce "both";
  services.tailscale.extraSetFlags = [ "--advertise-routes=${subnet}.0/24" ];

  # Les VMs sortent vers Internet, pas vers le LAN, le tailnet ni les autres
  # plages privées. Les connexions entrantes (ssh depuis gary) restent permises.
  # Table mangle, pas filter : tailscaled insère en tête de filter/FORWARD sa
  # chaîne ts-forward, qui accepte tout ce qui sort par tailscale0 avant qu'on
  # soit consulté (fuite vérifiée : dev1 joignait zola). mangle/FORWARD passe avant.
  networking.firewall.extraCommands = ''
    iptables -w -t mangle -N devbox-fwd 2>/dev/null || iptables -w -t mangle -F devbox-fwd
    iptables -w -t mangle -D FORWARD -i ${bridge} -j devbox-fwd 2>/dev/null || true
    iptables -w -t mangle -I FORWARD -i ${bridge} -j devbox-fwd
    iptables -w -t mangle -A devbox-fwd -m conntrack --ctstate ESTABLISHED,RELATED -j RETURN
    for net in 10.0.0.0/8 172.16.0.0/12 192.168.0.0/16 100.64.0.0/10 169.254.0.0/16; do
      iptables -w -t mangle -A devbox-fwd -d "$net" -j DROP
    done
  '';
  networking.firewall.extraStopCommands = ''
    iptables -w -t mangle -D FORWARD -i ${bridge} -j devbox-fwd 2>/dev/null || true
    iptables -w -t mangle -F devbox-fwd 2>/dev/null || true
    iptables -w -t mangle -X devbox-fwd 2>/dev/null || true
  '';
}
