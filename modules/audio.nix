{
  pkgs,
  lib,
  ...
}:

let
  # Sur NixOS les plugins ne sont pas dans /usr/lib : sans ces variables, un
  # hôte (REAPER…) ne trouve pas sfizz & co.
  pluginPath =
    format:
    "$HOME/.${format}:"
    + lib.makeSearchPath format [
      "/run/current-system/sw/lib"
      "/etc/profiles/per-user/$USER/lib"
    ];
in
{
  # musnix a été retiré : sans noyau temps réel (inutile ici — PipeWire + rtkit
  # tiennent déjà 3-6 ms de latence, largement sous le seuil de perception), il
  # ne restait que les quelques réglages ci-dessous, et il forçait au passage
  # `powerManagement.cpuFreqGovernor = "performance"` sans mkDefault, ce qui
  # écrasait silencieusement le gouverneur "powersave" de bernanos.

  # Les interruptions deviennent des threads ordonnançables : c'est ce qui
  # permet de prioriser celle de la carte son et d'éviter les xruns.
  boot.kernelParams = [ "threadirqs" ];

  # Séquenceur ALSA — indispensable au MIDI (clavier maître, FluidSynth).
  boot.kernelModules = [
    "snd-seq"
    "snd-rawmidi"
  ];

  # Évite que le noyau swappe les buffers audio sous pression mémoire.
  boot.kernel.sysctl."vm.swappiness" = 10;

  # Priorité temps réel pour les applications qui la demandent directement,
  # sans passer par rtkit (JACK natif, certains hôtes de plugins).
  security.pam.loginLimits = [
    {
      domain = "@audio";
      item = "memlock";
      type = "-";
      value = "unlimited";
    }
    {
      domain = "@audio";
      item = "rtprio";
      type = "-";
      value = "99";
    }
  ];

  environment.sessionVariables = {
    CLAP_PATH = lib.mkDefault (pluginPath "clap");
    LADSPA_PATH = lib.mkDefault (pluginPath "ladspa");
    LV2_PATH = lib.mkDefault (pluginPath "lv2");
    VST3_PATH = lib.mkDefault (pluginPath "vst3");
    VST_PATH = lib.mkDefault (pluginPath "vst");
  };

  # Accès aux timers haute résolution et au contrôle de latence DMA du CPU.
  services.udev.extraRules = ''
    KERNEL=="rtc0", GROUP="audio"
    KERNEL=="hpet", GROUP="audio"
    DEVPATH=="/devices/virtual/misc/cpu_dma_latency", OWNER="root", GROUP="audio", MODE="0660"
  '';

  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    jack.enable = true;
    # Annulation d'écho pour l'assistant vocal d'anna : `echo-cancel-source`
    # est le micro par défaut moins ce que jouent les haut-parleurs, pour que
    # « Karénine » soit entendu par-dessus la musique ou une vidéo (et qu'une
    # vidéo qui le dit ne réveille pas anna). Seule anna l'écoute (mot
    # d'éveil et dictée, `anna/src/audio.rs` de karenine).
    #
    # `monitor.mode` : la référence est le moniteur de la sortie par défaut, et
    # non un sink virtuel par lequel tout le son devrait passer. La lecture
    # n'est donc ni détournée ni retardée (REAPER, BandLab, l'accordeur ne
    # voient rien), et le micro par défaut reste le micro brut. Testé le
    # 16/10/2026 : son des haut-parleurs atténué de ~26 dB, score Karénine
    # 0.99 → 0.00 sur des clips joués par l'ordinateur.
    #
    # Sans « priority.session », le nœud ne devient jamais la source par
    # défaut ; ni réglage de gain ni suppression de bruit, pour garder le son
    # proche de celui sur lequel le modèle du mot a été entraîné.
    extraConfig.pipewire."99-echo-cancel" = {
      "context.modules" = [
        {
          name = "libpipewire-module-echo-cancel";
          args = {
            "library.name" = "aec/libspa-aec-webrtc";
            "monitor.mode" = true;
            "node.description" = "Echo Cancelled Source";
            "capture.props" = {
              "node.name" = "capture.echo-cancel";
              "node.passive" = true;
              "audio.channels" = 2;
              "audio.position" = [
                "FL"
                "FR"
              ];
            };
            "source.props" = {
              "node.name" = "echo-cancel-source";
              "node.description" = "Microphone (Echo Cancelled)";
              "audio.channels" = 2;
              "audio.position" = [
                "FL"
                "FR"
              ];
            };
            # En monitor.mode, le flux qui lit le moniteur de la sortie.
            "playback.props" = {
              "node.name" = "monitor.echo-cancel";
              "node.passive" = true;
            };
            "aec.args" = {
              "webrtc.gain_control" = false;
              "webrtc.extended_filter" = true;
              "webrtc.noise_suppression" = false;
            };
          };
        }
      ];
    };
    wireplumber.extraConfig = {
      # Un casque Bluetooth ne change de mode que quand on le lui demande
      # (Musique / Appel, menu Bluetooth de karenine). Avec la bascule
      # automatique, WirePlumber tient une entrée virtuelle `bluez_input.<MAC>`
      # et passe le casque en mode appel dès qu'un programme l'enregistre,
      # puis le rend en musique quand il s'arrête. Le mot d'éveil d'anna
      # écoute en continu (echo-cancel) : le casque basculait au hasard des
      # captures qui s'ouvrent et se ferment. Sans elle, le micro du casque
      # n'existe qu'en mode Appel, comme une entrée ordinaire.
      "51-bluetooth-no-autoswitch" = {
        "wireplumber.settings" = {
          "bluetooth.autoswitch-to-headset-profile" = false;
        };
      };
      # Allow Chrome/BandLab PWA to access microphone and audio.
      # "rwx" (read/write/execute), not "all" (= "rwxm"): chromium only needs
      # to enumerate nodes and open its own capture/playback streams, never to
      # set metadata on the graph (rename/relabel other clients' nodes, change
      # the system default sink/source). Dropping the "m" bit keeps the same
      # PWA capability while removing the one permission with system-wide
      # blast radius. Still matches every chromium process (all PWAs share the
      # same binary, so a per-app rule isn't possible), not just BandLab.
      "50-chrome-bandlab-access" = {
        "access.rules" = [
          {
            matches = [
              { "application.process.binary" = "chromium"; }
              { "application.process.binary" = "chromium-browser"; }
            ];
            actions = {
              "update-props" = {
                "default_permissions" = "rwx";
              };
            };
          }
        ];
      };
    };
  };

  # Backends d'enregistrement micro pour la dictée vocale de Claude Code
  # (rec/arecord), appelés au runtime par le binaire claude.
  environment.systemPackages = with pkgs; [
    sox
    alsa-utils
  ];
}
