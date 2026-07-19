{
  pkgs,
  inputs,
  primaryMonitor ? "HDMI-A-1",
  ...
}:

let
  system = pkgs.stdenv.hostPlatform.system;

  karenine = inputs.karenine.packages.${system}.default;

  nixSnowflake = "${pkgs.nixos-icons}/share/icons/hicolor/scalable/apps/nix-snowflake-white.svg";

  # Layout final = paquet karenine + superpositions machine.
  configured = pkgs.runCommand "karenine-configured" { } ''
    cp -r ${karenine} "$out"
    chmod -R u+w "$out"

    # Écran de la barre (le paquet code "DP-1" en dur pour l'usage standalone).
    substituteInPlace "$out/shell.qml" \
      --replace-warn 'primaryScreen: "DP-1"' 'primaryScreen: "${primaryMonitor}"'

    # Idem pour le lockscreen : WlSessionLock monte une surface par moniteur,
    # et seul l'écran primaire reçoit le bandeau musique/stats.
    substituteInPlace "$out/lock.qml" \
      --replace-warn 'primaryScreen: "DP-1"' 'primaryScreen: "${primaryMonitor}"'

    # Icône NixOS épinglée depuis nixpkgs.
    cp ${nixSnowflake} "$out/assets/nixos.svg"
  '';
in
{
  home.packages = with pkgs; [
    inputs.quickshell.packages.${system}.default
    cava
    pulseaudio
  ];

  xdg.configFile."quickshell".source = configured;
}
