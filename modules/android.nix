{
  lib,
  pkgs,
  ...
}:

# Environnement de développement Android déclaratif (androidenv).
#
# Fournit :
#   - le SDK complet (sdkmanager, avdmanager, adb, build-tools, platform-tools,
#     emulator, NDK, cmake) installé via composeAndroidPackages ;
#   - un émulateur prêt à lancer par device « dernière génération » (Pixel),
#     persistant entre deux lancements.
#
# Prérequis KVM : chaque host charge déjà son module kvm (kvm-intel / kvm-amd) ;
# ce module ajoute simplement l'utilisateur au groupe `kvm` (sinon l'émulateur
# x86_64 tourne sans accélération CPU et devient inutilisable).

let
  # SDK partagé pour le développement (IDE, gradle, adb, …).
  androidComposition = pkgs.androidenv.composeAndroidPackages {
    cmdLineToolsVersion = "latest";
    platformToolsVersion = "latest";
    buildToolsVersions = [ "latest" ];
    # Chaque version tire son image système complète (~4 Go). N'en garder
    # qu'une : l'API 34 coûtait 4,5 Go pour une cible qu'on ne vise plus.
    platformVersions = [ "35" ];
    includeEmulator = true;
    emulatorVersion = "latest";
    includeSystemImages = true;
    systemImageTypes = [ "google_apis" ];
    abiVersions = [ "x86_64" ];
    includeNDK = true;
    includeCmake = true;
  };

  androidSdk = androidComposition.androidsdk;
  sdkRoot = "${androidSdk}/libexec/android-sdk";

  devices = {
    pixel-8 = {
      device = "pixel_8";
      platform = "35";
    };
    pixel-8-pro = {
      device = "pixel_8_pro";
      platform = "35";
    };
    pixel-9-pro = {
      device = "pixel_9_pro";
      platform = "35";
    };
    pixel-tablet = {
      device = "pixel_tablet";
      platform = "35";
    };
  };

  # Options écrites dans config.ini à la création de l'AVD.
  # NB : on n'utilise PAS androidenv.emulateApp — il force en interne une vieille
  # version des cmdline-tools (8.0) dont avdmanager ignore les Pixel récents.
  # On pilote directement le SDK « latest » (avdmanager/emulator).
  configOptions = {
    "hw.ramSize" = "4096";
    "disk.dataPartition.size" = "8G";
    # Caméras avant/arrière mappées sur la webcam de l'hôte.
    "hw.camera.back" = "webcam0";
    "hw.camera.front" = "webcam0";
  };

  mkEmulator =
    name:
    { device, platform }:
    let
      sysImage = "system-images;android-${platform};google_apis;x86_64";
      writeConfig = lib.concatStrings (
        lib.mapAttrsToList (k: v: ''echo "${k} = ${v}" >> "$avd/config.ini"'') configOptions
      );
    in
    pkgs.writeShellScriptBin "android-emu-${name}" ''
      set -euo pipefail
      export QT_QPA_PLATFORM=xcb
      export ANDROID_HOME="${sdkRoot}"
      export ANDROID_SDK_ROOT="${sdkRoot}"
      export ANDROID_USER_HOME="$HOME/.local/share/android/avd-home"
      export ANDROID_AVD_HOME="$ANDROID_USER_HOME/avd"
      mkdir -p "$ANDROID_AVD_HOME"
      avd="$ANDROID_AVD_HOME/${name}.avd"

      # Crée l'AVD persistant au premier lancement (profil ${device}, API ${platform}).
      if ! ${androidSdk}/bin/avdmanager list avd | grep -q "Name: ${name}$"; then
        echo "Création de l'AVD ${name} (${device}, API ${platform})…" >&2
        yes "" | ${androidSdk}/bin/avdmanager create avd --force \
          -n ${name} -k "${sysImage}" --device ${device} -p "$avd"
        ${writeConfig}
      fi

      # Supprime un lock d'instance orphelin laissé par un émulateur tué
      # brutalement (sinon : « Running multiple emulators with the same AVD »),
      # mais uniquement si aucune instance de cet AVD ne tourne réellement.
      if [ -f "$avd/multiinstance.lock" ] && \
         ! pgrep -f "qemu-system-x86_64.*-avd ${name}" >/dev/null; then
        rm -f "$avd/multiinstance.lock"
      fi

      # Webcam de l'hôte forcée au lancement (webcam0 = 1re caméra ;
      # `... -webcam-list` pour les lister).
      #
      # -no-snapshot : Quickboot (snapshot RAM « default_boot ») est désactivé.
      # Sur btrfs l'émulateur désactive QuickbootFileBacked et son save/restore
      # du device goldfish_pipe est corrompu (« Error -5 while loading VM state »,
      # boot cassé). On cold-boot à chaque lancement — l'userdata reste persistant,
      # seul l'état RAM n'est ni sauvé ni rechargé.
      # -gpu host : force le rendu matériel sur le GPU de l'hôte (Vulkan/RADV).
      # Sans ça, `-gpu auto` blockliste le driver AMD (« Your GPU drivers may have
      # a bug ») et retombe en software (swangle + lavapipe) — lent et inutile vu
      # qu'on a une vraie carte. `-gpu host` passe outre la blocklist.
      exec "${sdkRoot}/emulator/emulator" -avd ${name} \
        -gpu host \
        -camera-back webcam0 -camera-front webcam0 \
        -no-snapshot -no-boot-anim "$@"
    '';

  emulatorPackages = lib.mapAttrsToList mkEmulator devices;
in
{
  # Le SDK Android est unfree et exige l'acceptation explicite de la licence.
  nixpkgs.config.android_sdk.accept_license = true;

  # kvm : accélération CPU de l'émulateur (sinon l'émulateur x86_64 est inutilisable).
  # L'accès aux devices USB (adb) est géré automatiquement par les règles uaccess
  # de systemd pour la session active — plus besoin du groupe adbusers.
  users.users.aristide.extraGroups = [ "kvm" ];

  environment.systemPackages = [
    androidSdk
  ]
  ++ emulatorPackages
  ++ (with pkgs; [
    android-tools # adb / fastboot en ligne de commande
    scrcpy # miroir/contrôle d'un device physique
  ]);

  # Les outils (gradle, IDE) trouvent le SDK/NDK via ces variables.
  environment.sessionVariables = {
    ANDROID_HOME = sdkRoot;
    ANDROID_SDK_ROOT = sdkRoot;
  };
}
