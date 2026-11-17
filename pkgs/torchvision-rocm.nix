# torchvision compilé avec ses opérateurs HIP, pour le ComfyUI de gary.
#
# La dérivation nixpkgs ne connaît que CUDA (`FORCE_CUDA` sous `cudaSupport`) :
# sous `rocmSupport`, torch est bien la variante ROCm mais torchvision ne
# compile que les noyaux CPU de ses opérateurs C++. `deform_conv2d`, dont se
# sert BiRefNet (détourage, nœud RemoveBackground du template TRELLIS.2 /
# Pixal3D), échoue alors sur GPU : « Could not run 'torchvision::deform_conv2d'
# with arguments from the 'CUDA' backend » (gary, 2026-11-16).
#
# setup.py gère ROCm nativement (hipify de ops/cuda → ops/hip, WITH_HIP) dès
# que torch.version.hip est posé et que torch.utils.cpp_extension trouve un
# ROCM_HOME ; FORCE_CUDA=1 parce qu'il n'y a pas de GPU dans le bac à sable.
# Cibles gfx1100 + gfx1102, comme comfy-kitchen-hip.nix.
#
# Construit localement (pas dans le cache) ; les paquets Python qui dépendent
# de torchvision sont reconstruits aussi, mais ce sont des paquets purs.
{
  lib,
  rocmPackages,
  symlinkJoin,
}:

python-final: python-prev: {
  torchvision = python-prev.torchvision.overridePythonAttrs (old: {
    env =
      let
        # cpp_extension appelle $ROCM_HOME/bin/hipcc et ajoute
        # $ROCM_HOME/include ; les en-têtes ATen/hip tirent hipblas, hipsparse,
        # hipsolver, rocblas… d'où la liste large.
        rocmHome = symlinkJoin {
          name = "rocm-home-torchvision";
          paths = lib.concatMap (p: [ p ] ++ lib.optional (p ? dev) p.dev) (
            with rocmPackages;
            [
              clr
              hipcc
              rocm-device-libs
              rocm-comgr
              rocm-runtime
              rocm-core
              rocprim
              hipcub
              rocthrust
              rocrand
              hiprand
              rocblas
              hipblas
              hipblas-common
              hipblaslt
              rocsparse
              hipsparse
              rocsolver
              hipsolver
              miopen
              roctracer
            ]
          );
        };
      in
      (old.env or { })
      // {
        FORCE_CUDA = "1";
        ROCM_HOME = "${rocmHome}";
        ROCM_PATH = "${rocmHome}";
        HIP_PATH = "${rocmHome}";
        PYTORCH_ROCM_ARCH = "gfx1100;gfx1102";
        # Sans ça, le clang de hipcc ne trouve pas les bitcodes (« cannot find
        # ROCm device library ») malgré ROCM_PATH.
        HIP_CLANG_PATH = "${rocmPackages.clr.hipClangPath}";
        HIP_DEVICE_LIB_PATH = "${rocmPackages.rocm-device-libs}/amdgcn/bitcode";
        HIPCC_COMPILE_FLAGS_APPEND = "--rocm-device-lib-path=${rocmPackages.rocm-device-libs}/amdgcn/bitcode";
      };

    # Les noyaux HIP doivent être là : sans ça, un setup.py qui retombe sur
    # le CPU passerait inaperçu.
    postInstall = (old.postInstall or "") + ''
      $READELF -d $out/${python-final.python.sitePackages}/torchvision/_C*.so | grep -q amdhip64
    '';
  });
}
