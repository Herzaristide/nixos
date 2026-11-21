{ pkgs, ... }:

# L'Explorer de karenine (widgets/FileExplorer.qml) partout où le bureau
# montre ou fait choisir des fichiers. Tout passe par la FIFO du shell,
# /tmp/qs-panel.fifo (cf. shell.qml dans karenine) :
#
#   xdg-open d'un dossier      → karenine-explorer.desktop → karenine-open
#                                 (inode/directory, home/head.nix)
#   « Afficher dans le dossier » → org.freedesktop.FileManager1 (D-Bus)
#                                 → karenine-filemanager1 → karenine-open --reveal
#   « Ouvrir… / Enregistrer… »  → portail FileChooser → termfilechooser
#                                 (modules/head.nix) → karenine-pick
#
# Les fichiers, eux, gardent leur application (xdg-open, associations XDG) :
# seul ce qui montre un dossier ou fait choisir arrive ici.
let
  fifo = "/tmp/qs-panel.fifo";

  # Ouvre l'Explorer sur des dossiers, ou y montre des fichiers sélectionnés
  # dans le leur. Chemins ou URL file://. --reveal : un dossier aussi est
  # montré sélectionné dans son parent (ShowItems), au lieu d'y entrer. Si
  # personne ne lit la FIFO (Quickshell arrêté), l'écriture bloquerait : au
  # bout de 2 s on retombe sur Nautilus.
  karenineOpen = pkgs.writeShellApplication {
    name = "karenine-open";
    runtimeInputs = [
      pkgs.coreutils
      pkgs.gnused
    ];
    text = ''
      fifo=${fifo}
      reveal=0
      if [ "''${1-}" = --reveal ]; then
        reveal=1
        shift
      fi
      status=0
      for arg in "$@"; do
        p=$arg
        case $p in
          file://*)
            p=''${p#file://}
            # file://hôte/chemin : l'hôte tombe (localhost, ou le nom de la machine).
            case $p in /*) ;; *) p=/''${p#*/} ;; esac
            p=''${p%%#*}
            p=''${p%%\?*}
            # %XX → l'octet (les « + » restent des « + » dans un chemin).
            p=$(printf '%b' "$(printf '%s' "$p" | sed 's/\\/\\\\/g; s/%\([0-9A-Fa-f][0-9A-Fa-f]\)/\\x\1/g')")
            ;;
        esac
        case $p in
          *$'\n'*) echo "karenine-open: chemin avec un saut de ligne, ignoré" >&2; status=1; continue ;;
        esac
        if ! p=$(realpath -e -- "$p" 2>/dev/null); then
          echo "karenine-open: $arg n'existe pas" >&2
          status=1
          continue
        fi
        if [ -d "$p" ] && [ "$reveal" = 0 ]; then kind=dossier; else kind=fichier; fi
        # $1 et $2 sont ceux du sh -c, pas les nôtres : les guillemets simples sont voulus.
        # shellcheck disable=SC2016
        if ! timeout 2 sh -c 'printf "%s\n" "$1" > "$2"' -- "explorer:$kind:$p" "$fifo" 2>/dev/null; then
          command -v nautilus >/dev/null && nautilus --new-window "$p" &
        fi
      done
      exit "$status"
    '';
  };

  # Le script que xdg-desktop-portal-termfilechooser lance pour chaque
  # « Ouvrir… / Enregistrer… » (cf. xdg-desktop-portal-termfilechooser(5)) :
  #   $1 plusieurs fichiers (0/1)  $2 un dossier (0/1)  $3 enregistrer (0/1)
  #   $4 le dossier de départ, ou le fichier proposé (enregistrer)
  #   $5 le fichier où écrire les chemins choisis, un par ligne
  # (puis $6 le débogage et la commande de terminal, sans objet ici). Il
  # passe l'Explorer en mode choix (« explorer:choisir:<json> ») et attend
  # sa réponse sur une FIFO à lui ; rien du tout vaut annulation, et le
  # portail rend « annulé » à l'application.
  kareninePick = pkgs.writeShellApplication {
    name = "karenine-pick";
    runtimeInputs = [
      pkgs.coreutils
      pkgs.jq
    ];
    text = ''
      multiple=$1 directory=$2 save=$3 path=$4 out=$5
      # Le portail échappe les apostrophes du chemin comme pour un shell,
      # qu'il n'y a pas : on défait cet échappement.
      path=''${path//"'\'''"/"'"}

      mode=open
      [ "$directory" = 1 ] && mode=dir
      [ "$save" = 1 ] && mode=save
      many=false
      [ "$multiple" = 1 ] && many=true

      reply=$(mktemp -u "''${XDG_RUNTIME_DIR:-/tmp}/karenine-pick.XXXXXX")
      mkfifo -m 600 "$reply"
      trap 'rm -f "$reply"' EXIT

      req=$(jq -cn --arg mode "$mode" --argjson multiple "$many" \
        --arg path "$path" --arg reply "$reply" \
        '{mode: $mode, multiple: $multiple, path: $path, reply: $reply}')

      # shellcheck disable=SC2016
      if ! timeout 2 sh -c 'printf "%s\n" "$1" > "$2"' -- "explorer:choisir:$req" ${fifo} 2>/dev/null; then
        echo "karenine-pick: Quickshell ne lit pas ${fifo}" >&2
        exit 1
      fi

      # Une demi-heure pour choisir ; au-delà (ou karenine redémarré
      # entre-temps), c'est annulé.
      timeout 1800 cat "$reply" > "$out" || true
    '';
  };

  # org.freedesktop.FileManager1 : ce que Chromium, Zed, les notifications de
  # téléchargement… appellent pour « Afficher dans le dossier ». Démarré par
  # D-Bus à la première demande (cf. le .service plus bas), il ne fait que
  # passer les URI à karenine-open.
  fileManager1 =
    pkgs.writers.writePython3Bin "karenine-filemanager1"
      {
        libraries = [ pkgs.python3Packages.dbus-next ];
        # F722, F821 : les signatures D-Bus (« as », « s ») en annotations,
        # que flake8 lit comme du Python.
        flakeIgnore = [
          "E501"
          "F722"
          "F821"
        ];
      }
      ''
        import asyncio
        import signal
        import subprocess
        import sys

        from dbus_next.aio import MessageBus
        from dbus_next.constants import RequestNameReply
        from dbus_next.service import ServiceInterface, method

        OPEN = "${karenineOpen}/bin/karenine-open"


        def show(uris, reveal):
            if uris:
                subprocess.Popen([OPEN] + (["--reveal"] if reveal else []) + list(uris))


        class FileManager1(ServiceInterface):
            def __init__(self):
                super().__init__("org.freedesktop.FileManager1")

            @method()
            def ShowFolders(self, uris: "as", startup_id: "s"):
                show(uris, False)

            @method()
            def ShowItems(self, uris: "as", startup_id: "s"):
                show(uris, True)

            @method()
            def ShowItemProperties(self, uris: "as", startup_id: "s"):
                show(uris, True)


        async def main():
            # Les karenine-open lancés : récoltés tout seuls.
            signal.signal(signal.SIGCHLD, signal.SIG_IGN)
            bus = await MessageBus().connect()
            bus.export("/org/freedesktop/FileManager1", FileManager1())
            reply = await bus.request_name("org.freedesktop.FileManager1")
            if reply != RequestNameReply.PRIMARY_OWNER:
                print("org.freedesktop.FileManager1 a déjà un propriétaire", file=sys.stderr)
                sys.exit(1)
            await bus.wait_for_disconnect()


        asyncio.run(main())
      '';
in
{
  home.packages = [
    karenineOpen
    kareninePick
  ];

  # L'id karenine-explorer.desktop est celui que mimeapps.list donne à
  # inode/directory (home/head.nix), et que karenine (services/DefaultApps.qml)
  # écarte de son « Ouvrir dans » pour ne pas se proposer lui-même.
  xdg.desktopEntries.karenine-explorer = {
    name = "Explorer";
    genericName = "Gestionnaire de fichiers";
    exec = "karenine-open %U";
    icon = "system-file-manager";
    terminal = false;
    noDisplay = true;
    mimeType = [ "inode/directory" ];
    categories = [
      "System"
      "FileManager"
    ];
  };

  # Le portail FileChooser (routé vers termfilechooser dans modules/head.nix).
  # create_help_file=0 : sinon il crée, avant de nous appeler, le fichier
  # proposé à l'enregistrement, rempli d'instructions pour un gestionnaire
  # de fichiers en terminal.
  xdg.configFile."xdg-desktop-portal-termfilechooser/config".text = ''
    [filechooser]
    cmd=${kareninePick}/bin/karenine-pick
    default_dir=$HOME
    create_help_file=0
    open_mode=suggested
    save_mode=suggested
  '';

  # FileManager1, activé par D-Bus : le .service utilisateur passe devant ceux
  # du système ($XDG_DATA_HOME avant $XDG_DATA_DIRS), et Nautilus ne fournit
  # plus le sien (modules/nautilus.nix).
  xdg.dataFile."dbus-1/services/org.freedesktop.FileManager1.service".text = ''
    [D-BUS Service]
    Name=org.freedesktop.FileManager1
    Exec=${fileManager1}/bin/karenine-filemanager1
    SystemdService=karenine-filemanager1.service
  '';
  systemd.user.services.karenine-filemanager1 = {
    Unit = {
      Description = "« Afficher dans le dossier » dans l'Explorer de karenine (org.freedesktop.FileManager1)";
      PartOf = [ "graphical-session.target" ];
    };
    Service = {
      Type = "dbus";
      BusName = "org.freedesktop.FileManager1";
      ExecStart = "${fileManager1}/bin/karenine-filemanager1";
    };
  };
}
