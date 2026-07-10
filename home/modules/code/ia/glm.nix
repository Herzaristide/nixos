{ pkgs, config, ... }:

let
  # Endpoint compatible Anthropic de Z.ai (GLM). Claude Code parle nativement au
  # protocole Anthropic ; il suffit de rediriger la base URL + le token vers
  # Z.ai et de mapper les modèles Claude sur les modèles GLM.
  #
  # La clé API n'est PAS stockée dans la config (dépôt Git public). Le wrapper
  # la lit depuis $GLM_API_KEY, sinon depuis un fichier hors dépôt :
  #   mkdir -p ~/.config/glm && echo 'ta-clé' > ~/.config/glm/api-key && chmod 600 ~/.config/glm/api-key
  glm = pkgs.writeShellScriptBin "glm" ''
    set -euo pipefail

    key_file="''${GLM_API_KEY_FILE:-$HOME/.config/glm/api-key}"
    if [ -n "''${GLM_API_KEY:-}" ]; then
      token="$GLM_API_KEY"
    elif [ -f "$key_file" ]; then
      token="$(${pkgs.coreutils}/bin/tr -d '[:space:]' < "$key_file")"
    else
      echo "claude-glm : aucune clé API GLM trouvée." >&2
      echo "  → place ta clé dans $key_file (chmod 600) ou exporte GLM_API_KEY." >&2
      exit 1
    fi

    # Évite qu'une clé Anthropic présente dans l'environnement ne prenne le pas.
    unset ANTHROPIC_API_KEY

    export ANTHROPIC_BASE_URL="https://api.z.ai/api/anthropic"
    export ANTHROPIC_AUTH_TOKEN="$token"
    export ANTHROPIC_MODEL="glm-5.2"
    export ANTHROPIC_SMALL_FAST_MODEL="glm-4.5-air"

    exec ${config.programs.claude-code.package}/bin/claude "$@"
  '';
in
{
  home.packages = [ glm ];
}
