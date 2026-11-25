{ config, ... }:

# zoxide : les dossiers visités, par fréquence et récence. `z <nom>` y va ;
# karenine (services/Places.qml) lit la même base pour ses propositions.
{
  programs.zoxide = {
    enable = true;
    enableFishIntegration = true;
  };

  # Jamais retenus (remplace l'exclusion par défaut, le dossier personnel).
  home.sessionVariables._ZO_EXCLUDE_DIRS = builtins.concatStringsSep ":" [
    config.home.homeDirectory
    "/tmp"
    "/tmp/*"
    "/run/*"
    "/nix/store/*"
  ];
}
