{ pkgs, ... }:

pkgs.rustPlatform.buildRustPackage {
  pname = "accent-daemon";
  version = "0.1.0";

  src = ./.;

  cargoLock.lockFile = ./Cargo.lock;

  # Runtime tools called as subprocesses by appctl.rs.
  # Wrapped into the PATH of both binaries at build time.
  nativeBuildInputs = [ pkgs.makeWrapper ];

  runtimeDeps = with pkgs; [
    hyprland # hyprctl
    dbus # dbus-send
    gtk3 # gtk-update-icon-cache
  ];

  postInstall = ''
    for bin in paletted palette; do
      wrapProgram $out/bin/$bin \
        --prefix PATH : ${
          pkgs.lib.makeBinPath (
            with pkgs;
            [
              hyprland
              dbus
              gtk3
            ]
          )
        }
    done
  '';

  meta = {
    description = "Accent-color and palette daemon for NixOS/Hyprland";
    mainProgram = "paletted";
  };
}
