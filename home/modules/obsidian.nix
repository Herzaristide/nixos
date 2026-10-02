{
  pkgs,
  config,
  lib,
  darkMode ? true,
  ...
}:

let
  # Le vault vit à ~/v4ult : dossier de premier niveau, persisté en entier par
  # modules/impermanence.nix (les notes ne sont pas régénérables). L'ancien
  # ~/v4ult — documents, dépôts et médias — est devenu ~/d3pot.
  vault = "${config.home.homeDirectory}/v4ult";

  # Obsidian tire un identifiant de vault aléatoire (16 chiffres hex) et s'en
  # sert comme clé dans obsidian.json et dans les URI `obsidian://open?vault=`.
  # Le figer ici garde ces liens valables d'un hôte à l'autre.
  vaultId = "0f4d1e9b7c3a5628";

  # `ts` est la date de dernière ouverture, utilisée pour le tri de la liste
  # des vaults. Une valeur fixe suffit : l'app la réécrit dès le premier
  # lancement, ce fichier n'étant seedé que s'il est absent.
  obsidianJson = pkgs.writeText "obsidian.json" (
    builtins.toJSON {
      vaults.${vaultId} = {
        path = vault;
        ts = 1790035200000;
        open = true;
      };
    }
  );

  # Obsidian ignore dconf, GTK et le portail org.freedesktop.appearance : son
  # thème ne vit que dans <vault>/.obsidian/appearance.json, et sans cette clé
  # il démarre en clair quel que soit `darkMode`. Les identifiants sont ceux
  # de l'app : obsidian = sombre, moonstone = clair (il existe aussi `system`,
  # écarté — il dépend de la détection Electron du portail, là où `darkMode`
  # est déjà la source de vérité qui pilote dconf, GTK, Qt et anna).
  theme = if darkMode then "obsidian" else "moonstone";

  # Le vrai point d'entrée déclaratif. obsidian.json n'en est pas un : l'app le
  # réécrit à chaque fermeture et en retire le vault si on a quitté le sélecteur
  # sans choisir (constaté le 2026-09-22, seed écrit à 23:20 et disparu à
  # 23:21). Le remplacer par un lien du store ne marcherait pas non plus —
  # l'app doit pouvoir y écrire. L'URI `obsidian://open?path=`, elle, est
  # honorée à chaque lancement et réenregistre le vault au besoin.
  vaultOpener = pkgs.writeShellApplication {
    name = "obsidian-vault";
    runtimeInputs = [ pkgs.obsidian ];
    text = ''
      # Sans argument (menu, raccourci, ligne de commande) on impose le vault.
      # Avec un argument, c'est xdg-open qui relaie un lien obsidian:// — on le
      # passe tel quel, sinon on écraserait la cible du lien.
      if [ "$#" -eq 0 ]; then
        exec obsidian "obsidian://open?path=${vault}"
      fi
      exec obsidian "$@"
    '';
  };
in
{
  # Wayland natif sans surcharge d'options : contrairement au wrapper binaire
  # de claude-desktop, celui d'obsidian est un script bash, donc son
  # `${NIXOS_OZONE_WL:+--ozone-platform=wayland …}` s'expanse réellement — et
  # NIXOS_OZONE_WL=1 est posé pour toute la session par modules/head.nix.
  home.packages = [
    pkgs.obsidian
    vaultOpener
  ];

  # Surcharge l'entrée du paquet pour passer par le wrapper. StartupWMClass est
  # recopié tel quel : sans lui, Hyprland n'associe pas la fenêtre au lanceur.
  xdg.desktopEntries.obsidian = {
    name = "Obsidian";
    genericName = "Base de connaissances";
    exec = "${lib.getExe vaultOpener} %u";
    icon = "obsidian";
    terminal = false;
    categories = [ "Office" ];
    mimeType = [ "x-scheme-handler/obsidian" ];
    startupNotify = true;
    settings.StartupWMClass = "md.obsidian.Obsidian";
  };

  # La clé `theme` suit la déclaration Nix et est donc réimposée à chaque
  # activation, comme icons_theme.txt côté anna : une bascule faite dans
  # l'interface d'Obsidian ne survit pas au prochain rebuild. La fusion jq
  # préserve le reste du fichier — taille de police, thème communautaire,
  # snippets CSS actifs.
  home.activation.obsidianAppearance = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
    appearance="${vault}/.obsidian/appearance.json"
    run mkdir -p $VERBOSE_ARG "${vault}/.obsidian"
    if [ ! -s "$appearance" ]; then
      echo '{}' > "$appearance"
    fi
    tmp=$(mktemp)
    if ${pkgs.jq}/bin/jq '.theme = "${theme}"' "$appearance" > "$tmp"; then
      mv "$tmp" "$appearance"
    else
      rm -f "$tmp"
    fi
  '';

  # Raccourci au premier lancement, pour que le sélecteur de vault ne s'affiche
  # pas du tout. Jamais écrasé ensuite : l'app y stocke aussi la géométrie des
  # fenêtres et la liste des autres vaults. Ce n'est qu'une commodité — c'est
  # le wrapper ci-dessus qui garantit l'ouverture du bon vault.
  home.activation.obsidianVaultSeed = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
    json="${config.xdg.configHome}/obsidian/obsidian.json"
    run mkdir -p $VERBOSE_ARG "${config.xdg.configHome}/obsidian" "${vault}"
    if [ ! -e "$json" ]; then
      run install -m 0644 ${obsidianJson} "$json"
    fi
  '';
}
