{
  config,
  pkgs,
  lib,
  ...
}:

let
  # Pokémon Infinite Fusion n'est pas dans nixpkgs : c'est un fangame RPG Maker
  # XP dont le Game.exe est un build Windows 64 bits de mkxp-z (moteur absent de
  # nixpkgs lui aussi). Il n'existe pas de build Linux natif : la « version
  # Linux » documentée par le README amont, c'est Wine (leur launch-wine.sh).
  # On fait pareil, en mode WoW64 pur — l'exécutable est PE32+, aucune couche
  # 32 bits n'est nécessaire.
  #
  # `releases` est la branche des joueurs (celle des tutoriels officiels) ;
  # `main` n'a plus bougé depuis janvier 2025.
  #
  # Le jeu n'est pas mis dans le store : il pèse plusieurs Go, se met à jour
  # souvent, et télécharge lui-même ses sprites personnalisés dans son dossier
  # (Graphics/CustomBattlers, ignoré par git en amont). Le dépôt officiel est
  # cloné au premier lancement dans ~/.local/share/infinite-fusion/game, le
  # préfixe Wine (où vivent les sauvegardes, sous AppData/Roaming) dans
  # ~/.local/share/infinite-fusion/prefix — le tout persisté par
  # modules/impermanence.nix.
  repo = "https://github.com/infinitefusion/infinitefusion-e18";
  branch = "releases";

  launcher = pkgs.writeShellApplication {
    name = "infinite-fusion";
    runtimeInputs = [
      pkgs.git
      pkgs.wineWow64Packages.stable
    ];
    text = ''
      data="''${XDG_DATA_HOME:-$HOME/.local/share}/infinite-fusion"
      game="$data/game"
      export WINEPREFIX="$data/prefix"
      export WINEDEBUG="''${WINEDEBUG:--all}"

      # Premier lancement depuis le menu : le clone prend plusieurs minutes,
      # on le fait dans un terminal pour que la progression soit visible.
      if [ ! -e "$game/Game.exe" ] && [ ! -t 1 ]; then
        exec ${lib.getExe config.programs.alacritty.package} \
          --title "Pokémon Infinite Fusion — installation" -e "$0" "$@"
      fi

      if [ ! -e "$game/Game.exe" ]; then
        echo "Téléchargement de Pokémon Infinite Fusion (plusieurs Go)…"
        rm -rf "$game"
        mkdir -p "$data"
        git clone --depth 1 --branch ${branch} ${repo} "$game"
      elif [ "''${1:-}" = "--update" ]; then
        # Historique superficiel : on récupère le dernier commit et on s'y
        # aligne. reset --hard ne touche pas aux fichiers non suivis, donc les
        # sprites téléchargés par le jeu restent ; les sauvegardes, elles,
        # sont dans le préfixe Wine.
        git -C "$game" fetch --depth 1 origin ${branch}
        git -C "$game" reset --hard FETCH_HEAD
        shift
      fi

      # InfiniteFusion-performance.exe est le lanceur alternatif fourni en amont pour les
      # machines où le chargement est lent.
      exe="Game.exe"
      if [ "''${1:-}" = "--performance" ]; then
        exe="InfiniteFusion-performance.exe"
      fi

      cd "$game"
      exec wine "$exe"
    '';
  };
in
{
  home.packages = [ launcher ];

  xdg.desktopEntries.infinite-fusion = {
    name = "Pokémon Infinite Fusion";
    genericName = "Fangame Pokémon";
    exec = lib.getExe launcher;
    icon = "applications-games";
    terminal = false;
    categories = [
      "Game"
      "RolePlaying"
    ];
    actions.update = {
      name = "Mettre à jour";
      exec = "${lib.getExe config.programs.alacritty.package} -e ${lib.getExe launcher} --update";
    };
  };
}
