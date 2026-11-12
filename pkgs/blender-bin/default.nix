# Blender : binaires officiels de blender.org, pas la compilation nixpkgs.
#
# Pourquoi : le tarball officiel embarque Cycles avec CUDA, OptiX et HIP déjà
# compilés (`5.x/scripts/addons_core/cycles/lib/kernel_sm_86.cubin.zst` pour
# la RTX 3070 Mobile de bernanos, plus les PTX OptiX que le pilote compile au
# premier rendu puis met en cache). Le `blender.override { cudaSupport = true; }`
# de nixpkgs n'est servi par aucun cache (unfree) et recompilait des heures à
# chaque `nix flake update` ; ici, un bump d'unstable ne refait que le
# patchelf + le wrapper (quelques secondes). Le binaire suit toujours la glibc
# du système, donc pas d'« EGL Error » à la Mesa (cf. CLAUDE.md, bernanos).
#
# Mise à jour à la main, comme claude-desktop :
#   curl -s https://download.blender.org/release/ | grep -oE 'Blender[0-9.]+/' | sort -uV | tail -1
#   nix store prefetch-file --json https://download.blender.org/release/Blender<maj.min>/blender-<version>-linux-x64.tar.xz | jq -r .hash
#
# Construction reprise de github:edolstra/nix-warez (dir=blender), qui s'est
# arrêté à 5.0.1 : le binaire embarque presque toutes ses bibliothèques dans
# lib/, on ne lui fournit que l'interpréteur ELF et, par LD_LIBRARY_PATH, les
# bibliothèques système (fenêtrage, GL/Vulkan, son) + /run/opengl-driver/lib
# pour le pilote (libcuda, libnvoptix).
#
# `nvidiaOffload` : lance toujours Blender sur le GPU NVIDIA d'un portable
# PRIME offload (mêmes variables que le wrapper `nvidia-offload` de nixpkgs).
{
  lib,
  stdenv,
  fetchurl,
  makeWrapper,
  wayland,
  libdecor,
  libx11,
  libxi,
  libxxf86vm,
  libxfixes,
  libxrender,
  libsm,
  libice,
  libxkbcommon,
  libGLU,
  libglvnd,
  numactl,
  SDL2,
  libdrm,
  ocl-icd,
  openal,
  alsa-lib,
  libpulseaudio,
  vulkan-loader,
  zlib,
  nvidiaOffload ? false,
}:

let
  version = "5.3.0";
  majorMinor = lib.versions.majorMinor version;

  libs = [
    wayland
    libdecor
    libx11
    libxi
    libxxf86vm
    libxfixes
    libxrender
    libsm
    libice
    libxkbcommon
    libGLU
    libglvnd
    numactl
    SDL2
    libdrm
    ocl-icd
    stdenv.cc.cc.lib
    openal
    alsa-lib
    libpulseaudio
    vulkan-loader
    zlib
  ];
in
stdenv.mkDerivation {
  pname = "blender-bin";
  inherit version;

  src = fetchurl {
    url = "https://download.blender.org/release/Blender${majorMinor}/blender-${version}-linux-x64.tar.xz";
    hash = "sha256-2suCZBl6P3/aYAEoWlpQb8l+6UOIEmHCw71jyILyLgU=";
  };

  nativeBuildInputs = [ makeWrapper ];

  # Binaires précompilés : ni strip ni patchelf automatique (le second
  # casserait les .so embarqués de lib/ et du Python de Blender).
  dontStrip = true;
  dontPatchELF = true;
  dontConfigure = true;
  dontBuild = true;

  installPhase = ''
    runHook preInstall

    mkdir -p $out/libexec $out/bin $out/share/applications $out/share/icons/hicolor/scalable/apps $out/share/icons/hicolor/symbolic/apps
    cp -a . $out/libexec/blender

    patchelf --set-interpreter "$(cat $NIX_CC/nix-support/dynamic-linker)" \
      $out/libexec/blender/blender
    patchelf --set-interpreter "$(cat $NIX_CC/nix-support/dynamic-linker)" \
      $out/libexec/blender/${majorMinor}/python/bin/python3*

    makeWrapper $out/libexec/blender/blender $out/bin/blender \
      --prefix LD_LIBRARY_PATH : /run/opengl-driver/lib:${lib.makeLibraryPath libs} ${lib.optionalString nvidiaOffload ''
        \
          --set __NV_PRIME_RENDER_OFFLOAD 1 \
          --set __NV_PRIME_RENDER_OFFLOAD_PROVIDER NVIDIA-G0 \
          --set __GLX_VENDOR_LIBRARY_NAME nvidia \
          --set __VK_LAYER_NV_optimus NVIDIA_only''}

    # Le .desktop officiel lance `blender %F` via le PATH : il passe par le wrapper.
    cp blender.desktop $out/share/applications/blender.desktop
    cp blender.svg $out/share/icons/hicolor/scalable/apps/blender.svg
    cp blender-symbolic.svg $out/share/icons/hicolor/symbolic/apps/blender-symbolic.svg

    runHook postInstall
  '';

  meta = {
    description = "3D creation suite (official blender.org binaries, CUDA/OptiX/HIP included)";
    homepage = "https://www.blender.org";
    license = lib.licenses.gpl3Plus;
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
    platforms = [ "x86_64-linux" ];
    mainProgram = "blender";
  };
}
