{
  config,
  pkgs,
  lib,
  ...
}:

let
  # Fabrique un lanceur PWA (fenêtre dédiée, sans barre d'onglets ni champ URL)
  # partageant le profil Chromium principal. Retourne { package; desktopEntry; } :
  # le package expose la commande `<id>-pwa`, l'entrée de bureau range l'app dans
  # le menu d'applications — elle se comporte alors comme une application native.
  mkPwa =
    {
      id,
      name,
      url,
      icon ? "chromium",
      categories ? [ "Network" ],
    }:
    {
      package = pkgs.writeShellScriptBin "${id}-pwa" ''
        exec chromium --app=${url} --user-data-dir="$HOME/.config/chromium" "$@"
      '';
      desktopEntry = {
        inherit name icon categories;
        comment = "${name} (PWA Chromium)";
        exec = "${id}-pwa";
        startupNotify = true;
      };
    };

  # Suite Google en « applications natives ». Ajoute/retire une ligne pour
  # (dés)installer une app ; `icon` et `categories` sont optionnels (voir mkPwa).
  # Note : les icônes sont génériques (Chromium) faute d'icônes Google dans le
  # thème ; renseigne `icon = "chemin/vers.png";` par app pour les personnaliser.
  googlePwas = lib.mapAttrs (id: cfg: mkPwa (cfg // { inherit id; })) {
    notebooklm = {
      name = "NotebookLM";
      url = "https://notebooklm.google.com";
    };
    keep = {
      name = "Google Keep";
      url = "https://keep.google.com";
    };
    gcalendar = {
      name = "Google Agenda";
      url = "https://calendar.google.com";
    };
    gmail = {
      name = "Gmail";
      url = "https://mail.google.com";
    };
    gdrive = {
      name = "Google Drive";
      url = "https://drive.google.com";
    };
    gdocs = {
      name = "Google Docs";
      url = "https://docs.google.com";
    };
    gphotos = {
      name = "Google Photos";
      url = "https://photos.google.com";
    };
    gmaps = {
      name = "Google Maps";
      url = "https://maps.google.com";
    };
  };
in
{
  programs.chromium = {
    enable = true;
    extensions = [
      { id = "fcoeoabgfenejglbffodgkkbkcdhcgfn"; }
      { id = "ddkjiahejlhfcafbddmgiahcphecmpfh"; }
      { id = "effdbpeggelllpfkjppbokhmmiinhlmg"; }
      # React Developer Tools
      { id = "fmkadmapgofadopljbjfkapdkoienihi"; }
    ];
  };

  # ManagedBookmarks: home-manager n'expose pas `extraOpts`, donc on écrit
  # directement le fichier de policy par-utilisateur.
  xdg.configFile."chromium/policies/managed/preferences.json".text = builtins.toJSON {
    TranslateEnabled = false;
    # Le profil Chromium est persisté : il a mémorisé ~/Downloads et ignore
    # XDG_DOWNLOAD_DIR une fois créé. Seule la policy force le changement.
    DownloadDirectory = "${config.home.homeDirectory}/f3tch";
    # 2 = aucun site ne peut afficher de notifications (bloque les pubs push).
    DefaultNotificationsSetting = 2;

    # Retour de connexion de Claude Desktop : claude.ai redirige vers une URL
    # `claude://` à la fin du flow OAuth. Sans cette policy, Chromium ouvre une
    # boîte de dialogue « Ouvrir Claude ? » à chaque fois et le retour se perd
    # si elle est ignorée. Limité aux origines d'Anthropic.
    AutoLaunchProtocolsFromOrigins = [
      {
        protocol = "claude";
        allowed_origins = [
          "https://claude.ai"
          "https://claude.com"
        ];
      }
    ];
  };

  xdg.configFile."chromium/policies/managed/bookmarks.json".text = builtins.toJSON {
    ManagedBookmarks = [
      {
        name = "GitHub";
        url = "https://github.com";
      }
      {
        name = "Claude";
        url = "https://claude.ai";
      }
      {
        name = "Figma";
        url = "https://www.figma.com";
      }
    ];
  };

  # PWA launcher scripts. Chromium suit le color-scheme système via xdg-desktop-portal.
  home.packages =
    with pkgs;
    [
      (writeShellScriptBin "hypr-gemini-launch" "gemini-pwa")
      (writeShellScriptBin "gemini-pwa" "chromium --app=https://gemini.google.com --user-data-dir=$HOME/.config/chromium")
      (writeShellScriptBin "bandlab-pwa" "chromium --app=https://www.bandlab.com --user-data-dir=$HOME/.config/chromium")
      (writeShellScriptBin "deezer-pwa" "chromium --app=https://www.deezer.com --user-data-dir=$HOME/.config/chromium")
    ]
    ++ map (p: p.package) (lib.attrValues googlePwas);

  # Entrées de bureau : les PWA définies à la main + la suite Google générée.
  # Un seul bloc `xdg.desktopEntries` pour éviter un conflit d'attribut Nix.
  xdg.desktopEntries = {
    # BandLab PWA (music production web app)
    bandlab-chrome = {
      name = "BandLab";
      comment = "Music production studio in your browser";
      exec = "bandlab-pwa";
      icon = "multimedia-audio-editor";
      categories = [
        "Audio"
        "AudioVideo"
      ];
      startupNotify = true;
    };

    # Deezer PWA
    deezer-chrome = {
      name = "Deezer";
      comment = "Deezer music streaming in a Chromium PWA";
      exec = "deezer-pwa";
      icon = "deezer";
      categories = [
        "Audio"
        "AudioVideo"
      ];
      startupNotify = true;
    };
  }
  // lib.mapAttrs' (id: p: lib.nameValuePair "${id}-chrome" p.desktopEntry) googlePwas;
}
