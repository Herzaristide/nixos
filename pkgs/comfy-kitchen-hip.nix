# comfy-kitchen compilé avec son backend HIP (kernels WMMA RDNA3 : GEMM int8 /
# w4a8, conversions fp8, RoPE, sage attention), pour le ComfyUI de gary.
#
# nixpkgs le construit avec `--no-cuda` et sans ROCm : seul le backend
# « eager » (PyTorch pur) reste, et les poids int8_convrot / w4a8 retombent
# sur des matmuls génériques. Ici `COMFY_KITCHEN_BUILD_HIP=1` force le backend
# HIP, que setup.py configure par CMake (langage HIP) + nanobind.
#
# Cibles : gfx1100 ET gfx1102. Sous HSA_OVERRIDE_GFX_VERSION=11.0.0 (posé par
# modules/comfyui.nix), le runtime annonce la RX 7600 XT comme gfx1100 et
# charge les objets de code gfx1100 ; gfx1102 sert si l'override saute un jour.
# Les deux sont dans le groupe `wmma_gfx11` de backends/hip/architectures.json.
#
# Construit localement (pas dans le cache), mais c'est un petit paquet :
# quelques minutes de hipcc, et seul l'environnement Python de ComfyUI en
# dépend.
{
  lib,
  rocmPackages,
  symlinkJoin,
}:

python-final: python-prev: {
  comfy-kitchen = python-prev.comfy-kitchen.overridePythonAttrs (old: {
    env =
      let
        # setup.py cherche le compilateur dans $ROCM_HOME/lib/llvm/bin/clang++
        # (disposition d'un ROCm « /opt/rocm ») ; CMake veut un clang, pas
        # hipcc, comme compilateur HIP. Arborescence assemblée à la main :
        # nixpkgs n'a plus de méta-paquet ROCm (`rocmPath` supprimé).
        rocmHome = symlinkJoin {
          name = "rocm-home-comfy-kitchen";
          paths = lib.concatMap (p: [ p ] ++ lib.optional (p ? dev) p.dev) (
            with rocmPackages;
            [
              clr
              hipcc
              rocm-device-libs
              rocm-comgr
              rocm-runtime
              rocm-core
            ]
          );
          postBuild = ''
            mkdir -p $out/lib/llvm/bin
            ln -s ${rocmPackages.clr.hipClangPath}/clang++ $out/lib/llvm/bin/clang++
            ln -s ${rocmPackages.clr.hipClangPath}/clang $out/lib/llvm/bin/clang
          '';
        };
      in
      (old.env or { })
      // {
        COMFY_KITCHEN_BUILD_HIP = "1";
        COMFY_HIP_ARCHS = "gfx1100;gfx1102";
        ROCM_HOME = "${rocmHome}";
        ROCM_PATH = "${rocmHome}";
        HIP_PATH = "${rocmHome}";
      };

    # Le backend HIP doit se charger : sans ça, un échec d'import passerait
    # inaperçu (comfy-kitchen retombe silencieusement sur « eager »).
    postInstall = (old.postInstall or "") + ''
      ls $out/${python-final.python.sitePackages}/comfy_kitchen/backends/hip/_C*.so
    '';
  });
}
