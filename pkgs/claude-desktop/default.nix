# Claude Desktop — repackaging du .deb officiel d'Anthropic.
#
# Anthropic publie l'app Linux (beta depuis le 30/06/2026) uniquement via son
# dépôt apt ; il n'y a pas de paquet dans nixpkgs (PR #537215 toujours ouverte).
# On dépaquette donc le .deb amd64 et on autoPatchelf l'Electron embarqué.
#
# Mise à jour :
#   curl -s https://downloads.claude.ai/claude-desktop/apt/stable/dists/stable/main/binary-amd64/Packages.gz \
#     | gzip -dc \
#     | awk '/^Version:/{v=$2} /^SHA256:/{print v, $2}' | sort -V | tail -1
#   nix hash convert --hash-algo sha256 --to sri <sha256>
{
  lib,
  stdenv,
  fetchurl,
  dpkg,
  autoPatchelfHook,
  makeWrapper,
  wrapGAppsHook3,
  alsa-lib,
  at-spi2-atk,
  at-spi2-core,
  cairo,
  cups,
  dbus,
  expat,
  glib,
  gtk3,
  libdrm,
  libgbm,
  libglvnd,
  libnotify,
  libsecret,
  libxkbcommon,
  libcap_ng,
  libseccomp,
  nspr,
  nss,
  pango,
  pipewire,
  systemd,
  util-linux,
  libX11,
  libxcomposite,
  libxdamage,
  libxext,
  libxfixes,
  libxrandr,
  libxcb,
  libxtst,
  xdg-utils,
  # Cowork exécute les sessions d'agent dans une micro-VM : le helper embarqué
  # (virtiofsd + smol-bin.x64.img) a besoin de qemu et d'un firmware UEFI.
  # Mettre à false retire ~1 Go de closure et ne casse que Cowork.
  withCowork ? true,
  qemu_kvm,
  OVMF,
}:

let
  version = "6.28899.6";

  runtimeDeps = [
    xdg-utils # xdg-open pour les liens externes
    glib # gio, utilisé pour la corbeille
  ]
  ++ lib.optionals withCowork [
    qemu_kvm
    OVMF
  ];
in
stdenv.mkDerivation {
  pname = "claude-desktop";
  inherit version;

  src = fetchurl {
    url = "https://downloads.claude.ai/claude-desktop/apt/stable/pool/main/c/claude-desktop/claude-desktop_${version}_amd64.deb";
    hash = "sha256-fjgWAdhlcBSWQ9Uum4nCZXWrEvp4iqQf/dTMpbBjjPg=";
  };

  nativeBuildInputs = [
    dpkg
    autoPatchelfHook
    makeWrapper
    wrapGAppsHook3
  ];

  buildInputs = [
    alsa-lib
    at-spi2-atk
    at-spi2-core
    cairo
    cups
    dbus
    expat
    glib
    gtk3
    libdrm
    libgbm
    libglvnd
    libnotify
    libsecret
    libxkbcommon
    libcap_ng
    libseccomp
    nspr
    nss
    pango
    pipewire # module natif @ant/claude-native (6.x)
    systemd # libudev
    util-linux # libuuid
    libX11
    libxcomposite
    libxdamage
    libxext
    libxfixes
    libxrandr
    libxcb
    libxtst
    stdenv.cc.cc.lib
  ];

  # Sans les permissions : le bit setuid de chrome-sandbox est refusé dans le
  # bac à sable de build (et le binaire est supprimé à l'installation).
  unpackCmd = "dpkg-deb --fsys-tarfile $curSrc | tar -x --no-same-owner --no-same-permissions";
  sourceRoot = ".";

  # Le wrapper est posé à la main en preFixup pour fusionner les arguments
  # GApps (schémas GSettings, modules GIO) avec les nôtres.
  dontWrapGApps = true;

  installPhase = ''
    runHook preInstall

    mkdir -p $out/lib $out/share
    cp -r usr/lib/claude-desktop $out/lib/
    cp -r usr/share/applications usr/share/icons $out/share/

    # Le bac à sable SUID de Chromium ne peut pas être setuid dans le store ;
    # Electron retombe sur le bac à sable par espaces de noms, actif par
    # défaut sur NixOS. Laisser le binaire en place ferait échouer le
    # lancement avec « SUID sandbox helper ... is not configured correctly ».
    rm -f $out/lib/claude-desktop/chrome-sandbox

    substituteInPlace $out/share/applications/com.anthropic.Claude.desktop \
      --replace-fail "Exec=claude-desktop" "Exec=$out/bin/claude-desktop"

    runHook postInstall
  '';

  preFixup = ''
    # `hint=auto` choisit Wayland ou X11 selon la session : pas de test shell,
    # et c'est indispensable ici car wrapGAppsHook3 produit un wrapper *binaire*
    # (makeBinaryWrapper), qui n'expanse aucune variable. Une substitution
    # conditionnelle du shell y arriverait littéralement, et Chromium prendrait
    # cet argument, non préfixé par `-`, pour l'URL à ouvrir — ce qui avalait le
    # deep link `claude://` du retour de connexion.
    #
    # Clair/sombre : Electron ≥ 45 (6.x) lit le color-scheme du portail et suit
    # anna en direct. La 2.x (Electron 44) ne regardait que le thème GTK, que
    # GTK_THEME=Breeze-Dark (absent, retiré de la session le 2026-11-22)
    # faisait retomber sur Adwaita clair.
    makeWrapper $out/lib/claude-desktop/claude-desktop $out/bin/claude-desktop \
      "''${gappsWrapperArgs[@]}" \
      --prefix PATH : "${lib.makeBinPath runtimeDeps}" \
      --prefix LD_LIBRARY_PATH : "${lib.makeLibraryPath [ libglvnd ]}" \
      --add-flags "--ozone-platform-hint=auto --enable-features=WaylandWindowDecorations"
  '';

  passthru.updateScript = null;

  meta = {
    description = "Application de bureau officielle pour Claude.ai";
    homepage = "https://claude.ai";
    license = lib.licenses.unfree;
    platforms = [ "x86_64-linux" ];
    mainProgram = "claude-desktop";
    sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
  };
}
