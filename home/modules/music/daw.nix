{ pkgs, lib, ... }:

# REAPER — DAW : écoute réaliste des arrangements (instruments de
# ./instruments.nix), enregistrement du violon (UR242), mixage, export.
# Piloté par Claude via le serveur MCP `reaper` (home/modules/code/ia/mcp.nix).
let
  pyEnv = import ./python-env.nix pkgs;

  # Le Python embarqué de REAPER charge la libpython de nixpkgs, sans les
  # site-packages de l'environnement : on les lui donne par PYTHONPATH pour
  # que le serveur reapy (lancé dans REAPER) puisse importer reapy.
  # LD_LIBRARY_PATH : la libjack de PipeWire, comme `pw-jack` (le mode JACK de
  # REAPER passe par PipeWire ; modules/audio.nix n'active plus `jack.enable`).
  reaper = pkgs.symlinkJoin {
    name = "reaper-${pkgs.reaper.version}";
    paths = [ pkgs.reaper ];
    nativeBuildInputs = [ pkgs.makeWrapper ];
    postBuild = ''
      wrapProgram $out/bin/reaper \
        --prefix PYTHONPATH : ${pyEnv}/${pkgs.python3.sitePackages} \
        --prefix LD_LIBRARY_PATH : ${pkgs.pipewire.jack}/lib
    '';
  };

  # Configuration unique (et à refaire si la version de Python change) :
  # active Python pour les ReaScripts, renseigne le chemin de libpython, ajoute
  # l'interface web (port 2307) et l'action qui démarre le serveur reapy.
  # Le tout dans ~/.config/REAPER (persisté, modules/impermanence.nix).
  # REAPER doit être fermé : il réécrit reaper.ini en quittant.
  reaper-setup-reapy = pkgs.writeShellScriptBin "reaper-setup-reapy" ''
    set -eu
    dir="$HOME/.config/REAPER"
    if [ ! -f "$dir/reaper.ini" ]; then
      echo "Lancer REAPER une première fois (puis le fermer) pour créer $dir/reaper.ini." >&2
      exit 1
    fi
    if ${lib.getExe' pkgs.procps "pgrep"} -f '/opt/REAPER/reaper' >/dev/null; then
      echo "Fermer REAPER d'abord : il réécrit reaper.ini en quittant." >&2
      exit 1
    fi
    ${pyEnv}/bin/python -c 'import reapy, sys; reapy.configure_reaper(sys.argv[1])' "$dir"
    echo "reapy configuré. Relancer REAPER : le serveur MCP « reaper » pourra s'y connecter."
  '';
in
{
  home.packages = [
    reaper
    reaper-setup-reapy
    # Effets (LV2/VST3/CLAP, trouvés via les *_PATH de modules/audio.nix)
    pkgs.lsp-plugins # EQ, compresseur, convolution (IR de caisse pour le violon électrique)
    pkgs.dragonfly-reverb # réverbs de salle et de hall, pour les cordes
  ];
}
