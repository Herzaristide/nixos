{ pkgs, lib, ... }:

{
  programs.fish = {
    enable = true;

    shellAliases = {
      ll = "ls -l";
      la = "ls -la";
      ".." = "cd ..";
      "..." = "cd ../..";
    };

    # Abbreviations Fish (se développent visuellement avant exécution)
    # Plus transparent et éditable que des alias
    shellAbbrs = {
      # TUI launchers
      y = "yazi";
      z = "zellij";
      c = "claude";
      ca = "claude agents";
      cr = "claude --continue";
      g = "glm";

      # Git
      gs = "git status";
      ga = "git add";
      gaa = "git add --all";
      gc = "git commit";
      gcm = "git commit -m";
      gca = "git commit --amend";
      gco = "git checkout";
      gcb = "git checkout -b";
      gb = "git branch";
      gbd = "git branch -d";
      gp = "git push";
      gpf = "git push --force-with-lease";
      gl = "git log --oneline";
      gll = "git log --oneline --graph --all";
      gd = "git diff";
      gds = "git diff --staged";
      gpl = "git pull";
      gf = "git fetch";
      gr = "git rebase";
      gm = "git merge";
      gst = "git stash";
      gstp = "git stash pop";

      # Docker
      d = "docker";
      dc = "docker-compose";
      dps = "docker ps";
      dpsa = "docker ps -a";
      di = "docker images";
      dlog = "docker logs -f";
      dex = "docker exec -it";
      dstop = "docker stop";
      drm = "docker rm";
      drmi = "docker rmi";
      dcp = "docker-compose up -d";
      dcl = "docker-compose logs -f";
      dcd = "docker-compose down";

      # Kubernetes (si utilisé)
      k = "kubectl";
      kgp = "kubectl get pods";
      kgs = "kubectl get services";
      kd = "kubectl describe";
      kl = "kubectl logs -f";

      # Nix
      nr = "nixos-rebuild";
      nrs = "sudo nixos-rebuild switch --flake github:Herzaristide/nixos#(hostname)";
      nfu = "nix flake update";
      nfc = "nix flake check";
    };

    interactiveShellInit = ''
      # Disable fish greeting message
      set -U fish_greeting ""

      # ── Mémorisation du dernier dossier (variable universelle) ─────────
      # `set -U` est persisté nativement par Fish (~/.config/fish/fish_variables),
      # partagé entre tous les shells et synchronisé en temps réel. Au démarrage
      # d'un shell interactif on se repositionne dans le dernier dossier visité,
      # MAIS uniquement si on démarre dans $HOME — ainsi un shell lancé dans un
      # dossier précis (ex: `alacritty --working-directory /tmp`) n'est pas écrasé.
      function __remember_pwd --on-variable PWD
          set -U last_pwd $PWD
      end
      if set -q last_pwd; and test -d $last_pwd; and test "$PWD" = "$HOME"
          cd $last_pwd
      end

      # ── Live accent-color reload ────────────────────────────────────────
      # Re-source `starship init fish` when ~/.config/accent/accent.hex changes,
      # so a color change in Quickshell propagates to the next prompt without
      # restarting the shell. Cost: one stat() per prompt.
      function __accent_reload --on-event fish_prompt
          set -l hex_file "$HOME/.config/accent/accent.hex"
          test -f "$hex_file"; or return
          set -l current_mtime (stat -c %Y "$hex_file" 2>/dev/null; or echo 0)
          if test "$current_mtime" != "$__accent_last_mtime"
              set -g __accent_last_mtime "$current_mtime"
              if type -q starship
                  starship init fish | source
              end
          end
      end

      # Run fastfetch on interactive shell start
      if status is-interactive
        nf
      end
    '';
  };
}
