{
  config,
  lib,
  ...
}:

let
  home = config.home.homeDirectory;

  # L'arborescence du home, identique sur les quatre hôtes. Sur zola et gary,
  # les dossiers de premier niveau sont aussi listés dans
  # modules/impermanence.nix — sans quoi ils seraient recréés vides à chaque
  # boot. kafka et exupery (WSL) n'ont pas d'impermanence : l'activation
  # ci-dessous est alors la seule chose qui les crée.
  tree = [
    "ciph3r"
    "cl0ud"
    "f3tch"
    "sc0re"
    "sh3lf"
    "v4ult"
    # Les trois dossiers XDG qui ont un sens ici vivent sous v4ult plutôt qu'à
    # la racine du home : v4ult est déjà persisté en entier, donc rien à
    # ajouter à impermanence.
    "v4ult/img"
    "v4ult/snd"
    "v4ult/vid"
  ];
in
{
  # Dossiers XDG. Le module est headless (importé par home/home.nix hors du
  # bloc `head`) pour que WSL et kafka aient le même home que zola et gary :
  # sans ça, XDG_DOWNLOAD_DIR y vaut ~/Downloads et les chemins divergent
  # d'un hôte à l'autre.
  xdg.userDirs = {
    enable = true;

    download = "${home}/f3tch";
    documents = "${home}/v4ult";
    # ~/v4ult/gpoc et consorts : c'est là que vivent les dépôts, pas ~/Projects.
    projects = "${home}/v4ult";
    pictures = "${home}/v4ult/img";
    music = "${home}/v4ult/snd";
    videos = "${home}/v4ult/vid";

    # Pas d'équivalent dans cette arborescence. On pointe sur $HOME plutôt que
    # de mettre `null` : `null` retire l'entrée de user-dirs.dirs, et GLib
    # retombe alors sur son propre défaut (~/Desktop), ce qui laisse revenir
    # exactement le dossier qu'on veut éviter. Un fichier déposé « sur le
    # bureau » atterrit donc à la racine du home — visible, donc corrigeable.
    desktop = home;
    publicShare = home;
    templates = home;

    # Redondant en stateVersion 25.11, où le défaut est encore `true`, mais il
    # bascule à `false` en 26.05 : l'écrire évite que les variables
    # disparaissent silencieusement au prochain bump. Les outils qui ne lisent
    # pas user-dirs.dirs (scripts, yt-dlp) dépendent de cet export.
    setSessionVariables = true;

    # Ne créerait que les dossiers XDG ci-dessus ; ciph3r, sc0re, cl0ud et
    # sh3lf n'en sont pas. Une seule liste (`tree`) décrit l'arborescence.
    createDirectories = false;
  };

  # `linkGeneration` (et pas `writeBoundary`) : on crée les dossiers une fois
  # les liens posés, pour ne pas transformer en dossier un chemin où
  # home-manager voulait mettre un symlink. `run` respecte le mode dry-run.
  home.activation.createHomeTree = lib.hm.dag.entryAfter [ "linkGeneration" ] (
    lib.concatMapStringsSep "\n" (d: ''run mkdir -p $VERBOSE_ARG "${home}/${d}"'') tree
  );
}
