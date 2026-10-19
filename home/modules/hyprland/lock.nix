{
  pkgs,
  config,
  inputs,
  ...
}:

let
  system = pkgs.stdenv.hostPlatform.system;
  quickshell = inputs.quickshell.packages.${system}.default;

  # Le lockscreen est une instance Quickshell distincte de la barre (lock.qml
  # vs shell.qml, tous deux fournis par karenine) : le shell peut planter ou
  # être rechargé sans déverrouiller la session.
  #
  # Chemin absolu du store — hypridle tourne comme service systemd user et
  # n'hérite pas forcément du PATH interactif.
  #
  # Garde-fou anti-doublon via flock, et surtout PAS via `pgrep -f` : un pgrep
  # sur la ligne de commande matcherait n'importe quel process mentionnant
  # lock.qml (un éditeur ouvert sur le fichier, un grep…), donc conclurait à
  # tort qu'un lock tourne déjà et sortirait SANS VERROUILLER. Un garde-fou qui
  # rate le verrouillage est pire que pas de garde-fou.
  #
  # Le verrou est tenu par le fd 9, hérité par le quickshell exec'é : il est
  # relâché par le noyau quand le lockscreen se termine, sans nettoyage.
  lockSession = pkgs.writeShellScriptBin "lock-session" ''
    exec 9> "''${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/lock-session.lock"
    if ! ${pkgs.util-linux}/bin/flock -n 9; then
      exit 0
    fi
    exec ${quickshell}/bin/quickshell -p ${config.xdg.configHome}/quickshell/lock.qml
  '';

  # Rallumage de l'écran au sortir de veille.
  #
  # hypridle exécute after_sleep_cmd dès qu'il reçoit PrepareForSleep=false,
  # donc AVANT que logind ait rendu /dev/dri/* à la session. Un `dpms on` à cet
  # instant répond « ok » mais ne produit aucun trafic DRM (vérifié dans
  # $XDG_RUNTIME_DIR/hypr/*/hyprland.log) : il ne fait que basculer le drapeau
  # interne de Hyprland. Juste derrière, la passe « Restoring after VT switch »
  # d'aquamarine constate « eDP-1 is disabled, releasing crtc 108 » et libère la
  # CRTC — l'écran garde encore l'ancien framebuffer (le lockscreen) quelques
  # secondes, puis passe au noir définitivement. Hyprland se croyant allumé,
  # tout `dpms on` ultérieur devient un no-op ; seul un TTY, qui fait son propre
  # modeset, répond encore. (Un retour de VT, lui, journalise « Skipping
  # connector eDP-1, has crtc 108 and is connected » et ne casse rien.)
  #
  # D'où : attendre le retour des devices, puis forcer un cycle off→on, seul
  # moyen de garantir un vrai commit DRM et la réassignation de la CRTC.
  # `hyprctl` sans chemin absolu, comme les autres commandes hypridle du
  # fichier : le service hérite du PATH de la session graphique.
  wakeDisplay = pkgs.writeShellScript "hypr-wake-display" ''
    ${pkgs.coreutils}/bin/sleep 2
    hyprctl dispatch 'hl.dsp.dpms("off")'
    ${pkgs.coreutils}/bin/sleep 1
    hyprctl dispatch 'hl.dsp.dpms("on")'
  '';
in
{
  # hypridle : verrouille après 30 min d'inactivité, DPMS peu après, et
  # verrouille avant la mise en veille. `loginctl lock-session` passe aussi par
  # ici (hypridle écoute le signal Lock de logind), donc lock_cmd est le seul
  # point d'entrée à changer pour remplacer l'écran de verrouillage.
  services.hypridle = {
    enable = true;
    settings = {
      general = {
        lock_cmd = "${lockSession}/bin/lock-session";
        before_sleep_cmd = "loginctl lock-session";
        # Pas un simple `dpms on` : voir le commentaire de wakeDisplay ci-dessus.
        after_sleep_cmd = "${wakeDisplay}";
      };

      listener = [
        {
          timeout = 1800;
          on-timeout = "loginctl lock-session";
        }
        {
          timeout = 1860;
          on-timeout = ''hyprctl dispatch 'hl.dsp.dpms("off")' '';
          on-resume = ''hyprctl dispatch 'hl.dsp.dpms("on")' '';
        }
      ];
    };
  };

  # Commande de verrouillage manuelle, et filet de secours : `lock-session` est
  # sur le PATH pour pouvoir tester le lockscreen à la main (garder un TTY
  # ouvert — voir l'avertissement en tête de karenine/lock.qml).
  home.packages = [
    lockSession

    # Filet de secours pendant la transition depuis hyprlock : le binaire reste
    # disponible (plus aucune config ni branchement sur hypridle) pour pouvoir
    # verrouiller à la main si le lockscreen Quickshell pose problème.
    # À retirer une fois le nouveau lock validé.
    pkgs.hyprlock
  ];
}
