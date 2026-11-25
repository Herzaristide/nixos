{ pkgs, ... }:

{
  programs.claude-code = {
    enable = true;
    package = pkgs.claude-code;
    enableMcpIntegration = true;

    # ~/.claude/CLAUDE.md, mémoire globale lue au début de chaque session.
    # Sans cette règle, Claude rangeait rendus et modèles générés dans le
    # scratchpad de session (/tmp/claude-<uid>/…), perdu au nettoyage de /tmp
    # (tri à la main du 2026-11-22 : ~2 200 fichiers sur bernanos et gary).
    context = ''
      # Fichiers générés

      Tout fichier généré destiné à être regardé ou réutilisé (y compris les
      tests et essais) est enregistré dans le dossier de données du home,
      **jamais dans le scratchpad de session** (`/tmp/claude-*/…`), qui est
      effacé :

      - Images, rendus, captures, vidéos, GIF : `~/lens/<projet>/`
      - Modèles 3D (`.glb`, `.gltf`, `.ply`, `.obj`, `.stl`, `.fbx`, `.usdz`,
        `.blend`, splats…) : `~/mesh/<projet>/`
      - Audio (musique, voix, sons, stems : `.wav`, `.flac`, `.mp3`, `.ogg`…) :
        `~/tune/<projet>/`

      `<projet>` est le nom du dépôt ou du sujet en cours ; un sous-dossier par
      série d'essais si elle produit beaucoup de fichiers. Ces dossiers existent
      et sont persistés sur tous les hôtes (bernanos, gary…) : on enregistre sur
      la machine où l'on travaille, y compris sur gary.

      Les sorties de ComfyUI (gary, API HTTP sur le port 8188) se récupèrent
      par `GET /view` directement dans ces dossiers. Sur gary, ComfyUI écrit
      aussi dans `/var/lib/comfyui-output`, lisible par aristide.

      Le scratchpad ne sert qu'aux fichiers vraiment jetables : scripts
      ponctuels, logs, fichiers intermédiaires qu'on ne regardera plus.
    '';

    lspServers = {
      rust = {
        command = "${pkgs.rust-analyzer}/bin/rust-analyzer";
        extensionToLanguage = {
          ".rs" = "rust";
        };
      };
      python = {
        command = "${pkgs.pyright}/bin/pyright-langserver";
        args = [ "--stdio" ];
        extensionToLanguage = {
          ".py" = "python";
          ".pyi" = "python";
        };
      };
      nix = {
        command = "${pkgs.nixd}/bin/nixd";
        extensionToLanguage = {
          ".nix" = "nix";
        };
      };
    };

    settings = {
      theme = "dark-ansi";
      language = "French";
      model = "claude-opus-5-5";
      spinnerTipsEnabled = false;
      remoteControlAtStartup = true;
      voiceEnabled = true;
      voice = {
        enabled = true;
        mode = "hold";
      };
      hooks.PreToolUse = [
        {
          matcher = "Bash";
          hooks = [
            {
              type = "command";
              command = "rtk hook claude";
            }
          ];
        }
      ];

      permissions = {
        allow = [
          "Bash(echo *)"
          "Bash(ls *)"
          "Bash(ls)"
          "Bash(cat *)"
          "Bash(pwd)"
          "Bash(whoami)"
          "Bash(hostname)"
          "Bash(uname *)"
          "Bash(df *)"
          "Bash(du *)"
          "Bash(free *)"
          "Bash(stat *)"
          "Bash(file *)"
          "Bash(which *)"
          "Bash(type *)"
          "Bash(find *)"
          "Bash(head *)"
          "Bash(tail *)"
          "Bash(wc *)"
          "Bash(sort *)"
          "Bash(uniq *)"
          "Bash(grep *)"
          "Bash(rg *)"
          "Bash(tree *)"
          "Bash(realpath *)"
          "Bash(readlink *)"
          "Bash(basename *)"
          "Bash(dirname *)"
          "Bash(pactl *)"
          "Bash(pw-cli *)"
          "Bash(pw-dump *)"
          "Bash(wpctl *)"
          "Bash(nix eval *)"
          "Bash(nix flake check *)"
          "Bash(nix flake show *)"
          "Bash(nix-instantiate *)"
          "Bash(nix-hash *)"
          "Bash(nix-store --query *)"
          "Bash(systemctl --user status *)"
          "Bash(systemctl status *)"
          "Bash(systemctl --user list-*)"
          "Bash(systemctl list-*)"
          "Bash(journalctl --user *)"
          "Bash(journalctl -u *)"
          "Bash(ip *)"
          "Bash(ss *)"
          "Bash(lsblk*)"
          "Bash(lsusb*)"
          "Bash(lspci*)"
          "Bash(rocm-smi*)"
          "Bash(rocminfo*)"
          "Bash(nvidia-smi*)"
        ];
        # Secrets : jamais lus, même par un `cat` autorisé plus haut (une
        # injection de prompt les ferait sinon remonter dans le contexte).
        # Read/Edit couvrent les outils intégrés (Read, Grep, Glob…) ; les
        # motifs Bash ne sont qu'un ralentisseur — une commande indirecte
        # (`cd ~ && cat .ssh/x`, variables) les contourne.
        deny = [
          "Read(~/.ssh/**)"
          "Edit(~/.ssh/**)"
          "Read(~/.gnupg/**)"
          "Read(~/.config/gh/**)"
          "Read(~/.config/glab-cli/**)"
          "Read(~/.local/share/keyrings/**)"
          "Read(~/.claude/.credentials.json)"
          "Read(~/.config/Claude/**)"
          "Read(~/.config/chromium/**)"
          "Read(~/.netrc)"
          "Read(~/.docker/config.json)"
          "Read(~/.kube/**)"
          "Read(//etc/passwd-aristide)"
          "Read(**/.env)"
          "Read(**/.env.*)"
          "Bash(*/.ssh/*)"
          "Bash(*/.ssh)"
          "Bash(*.gnupg*)"
          "Bash(*/.config/gh/*)"
          "Bash(*/.config/glab-cli*)"
          "Bash(*/keyrings*)"
          "Bash(*.credentials.json*)"
          "Bash(*/.config/Claude/*)"
          "Bash(*/.config/chromium/*)"
          "Bash(*.netrc*)"
          "Bash(*passwd-aristide*)"
          "Bash(secret-tool *)"
          "Bash(gh auth token*)"
          "Bash(glab auth status*)"
          "Bash(find * -delete*)"
          "Bash(find * -exec *)"
          "Bash(find * -execdir *)"
          "Bash(find * -ok *)"
          "Bash(find * -okdir *)"
          "Bash(find * -fprint*)"
          "Bash(find * -fls *)"
        ];
      };
    };

    # Sandbox (bubblewrap) des commandes Bash de Claude, sur tous les hôtes :
    #   - écriture limitée au dossier du projet ;
    #   - lecture interdite sur les secrets (denyRead, + les règles Read() en
    #     deny ci-dessus, fusionnées par Claude Code) ;
    #   - réseau via le proxy de Claude Code : domaine inconnu → demande ;
    #   - /run/user entier masqué : ssh-agent (siddhartha), trousseau GNOME et
    #     D-Bus y vivent. Sans le filtre seccomp optionnel, les sockets Unix ne
    #     sont pas bloqués sous Linux, mais un socket masqué par bwrap refuse la
    #     connexion (vérifié : `ssh-add -l` → « Connection refused »). Le
    #     répertoire entier plutôt que /run/user/<uid> : l'uid d'aristide n'est
    #     pas fixé dans la config, et ça masque aussi les autres comptes.
    # Commandes exclues : elles tournent hors sandbox mais restent soumises aux
    # permissions (demande, sauf si autorisées dans `allow`).
    #   - nix / nixos-rebuild : démon Nix, ~/.cache/nix ;
    #   - docker : son socket rootless, dans /run/user ;
    #   - gh, git push/pull/fetch : le token (~/.config/gh, ou le trousseau via
    #     D-Bus) est hors de portée du sandbox ;
    #   - pactl, wpctl, pw-*, systemctl/journalctl --user : sockets PipeWire et
    #     bus utilisateur, dans /run/user.
    settings.sandbox = {
      enabled = true;
      # Pas de repli silencieux sans sandbox si bwrap/socat manquent.
      failIfUnavailable = true;
      autoAllowBashIfSandboxed = true;
      excludedCommands = [
        "nix *"
        "nixos-rebuild *"
        "docker *"
        "docker compose *"
        "gh *"
        "git push *"
        "git push"
        "git pull *"
        "git pull"
        "git fetch *"
        "git fetch"
        "pactl *"
        "wpctl *"
        "pw-cli *"
        "pw-dump *"
        "systemctl --user *"
        "journalctl --user *"
      ];
      filesystem.denyRead = [
        "~/.ssh"
        "~/.gnupg"
        "~/.config/gh"
        "~/.config/glab-cli"
        "~/.local/share/keyrings"
        "~/.claude/.credentials.json"
        "~/.config/Claude"
        "~/.config/chromium"
        "~/.netrc"
        "~/.docker/config.json"
        "~/.kube"
        "/etc/passwd-aristide"
        "/run/user"
      ];
      network.allowedDomains = [
        "github.com"
        "api.github.com"
        "*.githubusercontent.com"
        "cache.nixos.org"
        "registry.npmjs.org"
        "pypi.org"
        "files.pythonhosted.org"
        "crates.io"
        "*.crates.io"
      ];
    };
  };

  # Dépendances Linux du sandbox.
  home.packages = [
    pkgs.bubblewrap
    pkgs.socat
  ];
}
