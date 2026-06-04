{
  pkgs,
  lib,
  ...
}:

let
  prismInstance = "26.1.2";
  mcVersion = "26.1.2";
  lwjglVersion = "3.4.1";
  fabricLoaderVersion = "0.19.2";

  instancePath = ".local/share/PrismLauncher/instances/${prismInstance}";
  mcPath = "${instancePath}/minecraft";

  mods = {
    "fabric-api.jar" = pkgs.fetchurl {
      url = "https://cdn.modrinth.com/data/P7dR8mSH/versions/E1mjhYMF/fabric-api-0.150.0%2B26.1.2.jar";
      sha512 = "238c793b720ed21d2d5b564eca88c714cf2188f7b0fb1fd30864660f80901e2b4dad273994b6f77de3c0aa365f930ed8aaccffac49b36c6456b153b52d5d21dc";
    };
    "sodium.jar" = pkgs.fetchurl {
      url = "https://cdn.modrinth.com/data/AANobbMI/versions/eRJU33Hp/sodium-fabric-0.8.12%2Bmc26.1.2.jar";
      sha512 = "402bb945d1f893a72c152c137e08f8a0c045d725a4d6ca2af7bcfe929c4d80338da509094cfe3a8cd162346b78c5069dc3cf1d57bf94a1bce557f6425da7e76f";
    };
    "iris.jar" = pkgs.fetchurl {
      url = "https://cdn.modrinth.com/data/YL57xq9U/versions/MwcLS51S/iris-fabric-1.10.9%2Bmc26.1.1.jar";
      sha512 = "01714943b36e7b78618bf133a20da489197322e20ebc2d9858f15bb57ac198fdab23dac6c917d6239ad3fe2e7c47f53fb387d475805eb7269fbfc16e30664155";
    };
  };

  resourcePacks = {
    "Faithful64x.zip" = pkgs.fetchurl {
      url = "https://cdn.modrinth.com/data/r4GILswZ/versions/yjAqtxxY/Faithful%2064x%20-%20Release%2013.zip";
      sha512 = "715ddf5e7ba089c08704bcd7fd281d6be0ae37dea7b7b105ef3c9d0b65eae34ac073f16b8718b83e0a9c40e9d38f66a4d2acf3e34238e8f8beea5af3119dd2f4";
    };
  };

  shaderPacks = {
    "ComplementaryReimagined.zip" = pkgs.fetchurl {
      url = "https://cdn.modrinth.com/data/HVnmMxH1/versions/yCCduG44/ComplementaryReimagined_r5.8.1.zip";
      sha512 = "6bd95215755d25812556ce790d976221f7d677d63112e3e4d3e70b08a62ed41348fa3792dd31bbe720d1e46fe2d525cadb4f66e6358118e1f4aa8e0d11f25c39";
    };
  };

  mmcPack = builtins.toJSON {
    formatVersion = 1;
    components = [
      {
        uid = "org.lwjgl3";
        version = lwjglVersion;
        cachedName = "LWJGL 3";
        cachedVersion = lwjglVersion;
        cachedVolatile = true;
        dependencyOnly = true;
      }
      {
        uid = "net.minecraft";
        version = mcVersion;
        cachedName = "Minecraft";
        cachedVersion = mcVersion;
        cachedRequires = [
          {
            suggests = lwjglVersion;
            uid = "org.lwjgl3";
          }
        ];
        important = true;
      }
      {
        uid = "net.fabricmc.intermediary";
        version = mcVersion;
        cachedName = "Intermediary Mappings";
        cachedVersion = mcVersion;
        cachedRequires = [
          {
            equals = mcVersion;
            uid = "net.minecraft";
          }
        ];
        cachedVolatile = true;
        dependencyOnly = true;
      }
      {
        uid = "net.fabricmc.fabric-loader";
        version = fabricLoaderVersion;
        cachedName = "Fabric Loader";
        cachedVersion = fabricLoaderVersion;
        cachedRequires = [ { uid = "net.fabricmc.intermediary"; } ];
      }
    ];
  };

  instanceCfgSeed = ''
    [General]
    ConfigVersion=1.3
    InstanceType=OneSix
    name=${prismInstance}
    iconKey=default
    JoinServerOnLaunch=false
    LaunchMaximized=false
    MaxMemAlloc=4096
    MinMemAlloc=512
    AutomaticJava=true
    LowMemWarning=true
  '';

  # Resource pack target name (doit matcher la clé dans resourcePacks ci-dessous).
  faithfulFileName = "Faithful64x.zip";

  # Iris : sélection du shader pack + activation.
  irisPropertiesSeed = ''
    shaderPack=ComplementaryReimagined.zip
    enableShaders=true
  '';

  mkSymlinks =
    dir: attrs: lib.mapAttrs' (n: v: lib.nameValuePair "${dir}/${n}" { source = v; }) attrs;
in
{
  home.packages = [ pkgs.prismlauncher ];

  # Assets immuables → symlinks vers /nix/store.
  home.file = lib.mkMerge [
    (mkSymlinks "${mcPath}/mods" mods)
    (mkSymlinks "${mcPath}/resourcepacks" resourcePacks)
    (mkSymlinks "${mcPath}/shaderpacks" shaderPacks)
    {
      "${mcPath}/allowed_symlinks.txt".text = ''
        # Autorise les chemins pointant dans le Nix store.
        /nix/store/
      '';
    }
  ];

  # Fichiers mutables (PrismLauncher / Minecraft écrivent dedans) :
  # - mmc-pack.json : on l'écrase pour garantir la présence de Fabric.
  # - instance.cfg, options.txt, iris.properties : seed uniquement si absents.
  home.activation.seedMinecraftInstance = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    instDir="$HOME/${instancePath}"
    mcDir="$HOME/${mcPath}"

    mkdir -p "$mcDir/config"

    cat > "$instDir/mmc-pack.json" <<'MMCPACK'
    ${mmcPack}
    MMCPACK

    if [ ! -f "$instDir/instance.cfg" ]; then
      cat > "$instDir/instance.cfg" <<'INSTCFG'
    ${instanceCfgSeed}
    INSTCFG
    fi

    # Ensure Faithful is enabled in options.txt resourcePacks (idempotent).
    # Why: l'instance vanilla a déjà créé options.txt avant notre seed, donc
    # un simple "seed if missing" ne suffit pas — il faut patcher la ligne à
    # chaque activation. On préserve les autres packs s'ils existent.
    ${pkgs.python3}/bin/python3 ${pkgs.writeText "patch-options.py" ''
      import re, sys, pathlib
      path = pathlib.Path(sys.argv[1])
      target = sys.argv[2]
      quoted = f'"file/{target}"'
      if not path.exists():
          path.write_text(f'resourcePacks:["vanilla",{quoted}]\nincompatibleResourcePacks:[]\n')
          sys.exit(0)
      lines = path.read_text().splitlines()
      patched = False
      for i, line in enumerate(lines):
          if line.startswith('resourcePacks:'):
              m = re.match(r'resourcePacks:\[(.*)\]$', line)
              if m:
                  packs = re.findall(r'"[^"]*"', m.group(1))
                  if quoted not in packs:
                      packs.append(quoted)
                      lines[i] = f'resourcePacks:[{",".join(packs)}]'
                      patched = True
              break
      else:
          lines.append(f'resourcePacks:["vanilla",{quoted}]')
          patched = True
      if patched:
          path.write_text('\n'.join(lines) + '\n')
    ''} "$mcDir/options.txt" "${faithfulFileName}"

    if [ ! -f "$mcDir/config/iris.properties" ]; then
      cat > "$mcDir/config/iris.properties" <<'IRISCFG'
    ${irisPropertiesSeed}
    IRISCFG
    fi
  '';
}
