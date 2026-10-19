{ pkgs, ... }:

let
  # La session exporte GTK_THEME=Breeze-Dark (home/modules/hyprland/hyprland.nix).
  # libadwaita ne le supporte pas : avec lui, Nautilus retombe sur un gris
  # générique et ignore les couleurs qu'anna réécrit dans
  # ~/.config/accent/fragments/gtk4-colors.css (importé par gtk-4.0/gtk.css,
  # cf. home/modules/kde/theming.nix). Vérifié en lançant les deux variantes
  # côte à côte : sans GTK_THEME, fond et barres suivent la palette.
  #
  # On enveloppe le binaire plutôt que de surcharger le paquet (qui serait alors
  # recompilé à chaque mise à jour de nixpkgs). Nautilus est aussi démarré par
  # D-Bus (org.gnome.Nautilus, org.freedesktop.FileManager1 — « Afficher dans le
  # dossier » de Chromium) : ces deux .service pointent sur le chemin absolu du
  # binaire d'origine, on les réécrit vers l'enveloppe. Les .desktop appellent
  # `nautilus` par le PATH et n'ont pas besoin d'être touchés.
  nautilus = pkgs.symlinkJoin {
    inherit (pkgs.nautilus) name meta;
    paths = [ pkgs.nautilus ];
    nativeBuildInputs = [ pkgs.makeWrapper ];
    postBuild = ''
      rm $out/bin/nautilus
      makeWrapper ${pkgs.nautilus}/bin/nautilus $out/bin/nautilus --unset GTK_THEME

      for f in $out/share/dbus-1/services/*.service; do
        src=$(readlink -f "$f")
        rm "$f"
        substitute "$src" "$f" --replace-fail ${pkgs.nautilus}/bin/nautilus $out/bin/nautilus
      done
    '';
  };
in
{
  # Le gestionnaire de fichiers (Super+F, inode/directory dans home/head.nix).
  environment.systemPackages = [ nautilus ];

  # Corbeille, montages amovibles, MTP, partages réseau (sidebar « Network »).
  services.gvfs.enable = true;

  # Clic droit → « Ouvrir dans un terminal » (Alacritty).
  programs.nautilus-open-any-terminal = {
    enable = true;
    terminal = "alacritty";
  };
}
