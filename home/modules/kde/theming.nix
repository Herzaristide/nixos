{
  config,
  lib,
  pkgs,
  darkMode ? true,
  ...
}:

let
  # Thème GTK : adw-gtk3 (l'aspect libadwaita pour GTK3), en clair et en
  # sombre. Il reprend les couleurs nommées de libadwaita (window_bg_color,
  # accent_bg_color…), donc le fragment qu'anna réécrit pour Nautilus le
  # colore aussi : GTK3 et GTK4 ont la même palette. Slot-Dark-GTK (sombre
  # seulement, Breeze en clair) a été remplacé le 2026-11-22.
  gtkTheme = mode: if mode == "light" then "adw-gtk3" else "adw-gtk3-dark";

  # Bascule clair/sombre en direct : anna n'écrit que color-scheme
  # (dconf), que libadwaita et le portail suivent. GTK3 et Electron ≤ 44
  # ne regardent que gtk-theme : ce service le recopie à chaque changement.
  # Les couleurs du fragment, elles, ne sont relues qu'au lancement de l'app.
  gtkThemeSync = pkgs.writeShellApplication {
    name = "gtk-theme-sync";
    runtimeInputs = [ pkgs.dconf ];
    text = ''
      key=/org/gnome/desktop/interface
      apply() {
        case "$(dconf read "$key/color-scheme")" in
          *light* | *default*) theme="${gtkTheme "light"}" ;;
          *) theme="${gtkTheme "dark"}" ;;
        esac
        if [ "$(dconf read "$key/gtk-theme")" != "'$theme'" ]; then
          dconf write "$key/gtk-theme" "'$theme'"
        fi
      }
      apply
      dconf watch "$key/color-scheme" | while read -r _; do apply; done
    '';
  };

  fragment = "file://${config.home.homeDirectory}/.config/accent/fragments/gtk4-colors.css";
in
{
  gtk = {
    enable = true;
    theme = {
      name = gtkTheme (if darkMode then "dark" else "light");
      package = pkgs.adw-gtk3;
    };
    font = {
      name = "JetBrains Mono";
      package = pkgs.jetbrains-mono;
      size = 11;
    };
    # Pas de gtk-application-prefer-dark-theme : en clair il assombrirait
    # adw-gtk3 (gtk-dark.css), et libadwaita le refuse. Le mode passe par
    # le nom du thème (GTK3) et color-scheme (libadwaita, portail).
    gtk3.extraCss = ''
      @import url("${fragment}");
    '';
    gtk4 = {
      theme = null;
      # Pulls in the libadwaita color tokens fragment rewritten by anna
      # on every accent change. The rest of the GTK4 config stays declarative.
      extraCss = ''
        @import url("${fragment}");
      '';
    };
  };

  dconf.settings."org/gnome/desktop/interface".gtk-theme = gtkTheme (
    if darkMode then "dark" else "light"
  );

  systemd.user.services.gtk-theme-sync = {
    Unit = {
      Description = "Recopie color-scheme vers gtk-theme (adw-gtk3 clair/sombre)";
      PartOf = [ "graphical-session.target" ];
      After = [ "graphical-session.target" ];
    };
    Service = {
      ExecStart = lib.getExe gtkThemeSync;
      Restart = "on-failure";
    };
    Install.WantedBy = [ "graphical-session.target" ];
  };

  # Qt theming — Breeze (consistent with KDE apps like Okular)
  qt = {
    enable = true;
    platformTheme.name = "kde";
    style = {
      name = "breeze";
      package = pkgs.kdePackages.breeze;
    };
  };

  # XDG menu spec entry point. Without it, kbuildsycoca6 never scans
  # share/applications, KApplicationTrader returns nothing, and KDE apps' (Okular, Ark)
  # "Open with" dialog comes up empty. Distros that ship a full DE get this
  # file from plasma-workspace / gnome-menus / xfce4-session — none are
  # installed here, so drop the standard freedesktop.org boilerplate.
  xdg.configFile."menus/applications.menu".text = ''
    <?xml version="1.0" encoding="UTF-8"?>
    <!DOCTYPE Menu PUBLIC "-//freedesktop//DTD Menu 1.0//EN"
     "http://www.freedesktop.org/standards/menu-spec/1.0/menu.dtd">
    <Menu>
      <Name>Applications</Name>
      <Directory>Applications.directory</Directory>
      <DefaultAppDirs/>
      <DefaultDirectoryDirs/>
      <DefaultMergeDirs/>
      <Include>
        <All/>
      </Include>
      <Layout>
        <Merge type="menus"/>
        <Merge type="files"/>
      </Layout>
    </Menu>
  '';

  # Nix store paths change on every rebuild; the cached KService database keeps
  # pointing at gone-away .desktop files, leaving the KDE apps' "Open with" dialog
  # empty.  Drop the stale caches and rebuild so the dialog repopulates.
  home.activation.rebuildKsycoca = lib.hm.dag.entryAfter [ "installPackages" ] ''
    run rm -f "$HOME/.cache/ksycoca6_"*
    run ${pkgs.kdePackages.kservice}/bin/kbuildsycoca6 --noincremental
  '';
}
