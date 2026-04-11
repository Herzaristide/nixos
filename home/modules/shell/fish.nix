{ pkgs, lib, ... }:

{
  programs.fish = {
    enable = true;

    shellAliases = {
      ll = "ls -l";
      la = "ls -la";
      ".." = "cd ..";
      "..." = "cd ../..";
      sf = "superfile";
    };

    # Abbreviations Fish (se développent visuellement avant exécution)
    # Plus transparent et éditable que des alias
    shellAbbrs = {
      # Git
      g = "git";
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
      nb = "nixos-rebuild";
      nbs = "sudo nixos-rebuild switch --flake .#(hostname)";
      nfu = "nix flake update";
      nfc = "nix flake check";
    };

    interactiveShellInit = ''
      # Disable fish greeting message
      set -U fish_greeting ""

      # Run fastfetch on interactive shell start
      if status is-interactive
        nf
      end
    '';
  };
}
