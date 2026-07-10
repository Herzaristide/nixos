{ pkgs, ... }:

# ghorg — clone/pull an entire user/org in one command, segmented per forge:
#   ghub <user-or-org>   → tous les repos GitHub dans ~/ghub  (SSH)
#   glab <user-or-org>   → tous les repos GitLab dans ~/glab  (HTTPS)
# Pas de sous-dossier <user> : GHORG_OUTPUT_DIR fixe le nom du dossier final,
# donc les repos sont posés directement dans ~/ghub / ~/glab.
# Re-running is idempotent (clone les manquants, pull les existants). Pas de
# prune automatique : ajouter --prune ponctuellement pour nettoyer le local.
#
# The API token is a secret and is NOT baked into the flake. Provide it at
# runtime via the GHORG_GITHUB_TOKEN / GHORG_GITLAB_TOKEN env var, `--token`,
# or reuse an existing `gh auth token`.
{
  home.packages = [ pkgs.ghorg ];

  # Réglages COMMUNS aux deux forges ; la forge, le protocole et la destination
  # sont fixés par les fonctions ghub/glab ci-dessous.
  xdg.configFile."ghorg/conf.yaml".text = ''
    GHORG_CLONE_TYPE: user
    GHORG_BRANCH: main
    GHORG_SKIP_ARCHIVED: true
    GHORG_SKIP_FORKS: false
    GHORG_CONCURRENCY: 25
  '';

  programs.fish.functions = {
    ghub = {
      description = "Sync tous les repos GitHub dans ~/ghub (SSH)";
      body = "env GHORG_SCM_TYPE=github GHORG_CLONE_PROTOCOL=ssh GHORG_ABSOLUTE_PATH_TO_CLONE_TO=/home/aristide GHORG_OUTPUT_DIR=ghub ghorg clone $argv";
    };
    glab = {
      description = "Sync tous les repos GitLab dans ~/glab (HTTPS)";
      body = "env GHORG_SCM_TYPE=gitlab GHORG_CLONE_PROTOCOL=https GHORG_ABSOLUTE_PATH_TO_CLONE_TO=/home/aristide GHORG_OUTPUT_DIR=glab ghorg clone $argv";
    };
  };
}
