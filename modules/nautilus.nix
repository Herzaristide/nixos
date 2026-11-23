{ pkgs, ... }:

let
  # Thème : le fragment libadwaita d'anna (~/.config/accent/fragments/
  # gtk4-colors.css, importé par gtk-4.0/gtk.css, cf.
  # home/modules/kde/theming.nix). La session n'exporte plus GTK_THEME depuis
  # le 2026-11-22, donc plus besoin de `--unset GTK_THEME` ici.
  #
  # On copie le paquet plutôt que de le surcharger (il serait alors recompilé
  # à chaque mise à jour de nixpkgs). Nautilus est démarré par
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
      makeWrapper ${pkgs.nautilus}/bin/nautilus $out/bin/nautilus

      # « Afficher dans le dossier » va à l'Explorer de karenine
      # (home/modules/karenine-explorer.nix) : Nautilus ne réclame plus
      # org.freedesktop.FileManager1 par activation D-Bus.
      rm $out/share/dbus-1/services/org.freedesktop.FileManager1.service

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

  # Clic droit → « Ouvrir dans un terminal » (kitty).
  programs.nautilus-open-any-terminal = {
    enable = true;
    terminal = "kitty";
  };
}
