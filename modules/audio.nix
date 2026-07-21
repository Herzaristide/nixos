{
  pkgs,
  lib,
  ...
}:

let
  # Sur NixOS les plugins ne sont pas dans /usr/lib : sans ces variables, un
  # hôte (REAPER, Ardour) ne trouve pas sfizz & co.
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
  # écrasait silencieusement le gouverneur "powersave" de zola.

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
    # Echo cancellation: removes loopback of speaker output into the mic
    # (fixes the voice-assistant feedback loop where piper TTS was being
    # transcribed back by whisper). Creates virtual `echo-cancel-source` /
    # `echo-cancel-sink` nodes; WirePlumber routes default mic through them.
    extraConfig.pipewire."99-echo-cancel" = {
      "context.modules" = [
        {
          name = "libpipewire-module-echo-cancel";
          args = {
            "library.name" = "aec/libspa-aec-webrtc";
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
              "priority.session" = 1500;
              "audio.channels" = 2;
              "audio.position" = [
                "FL"
                "FR"
              ];
            };
            "playback.props" = {
              "node.name" = "playback.echo-cancel";
              "node.passive" = true;
            };
            "sink.props" = {
              "node.name" = "echo-cancel-sink";
              "node.description" = "Speakers (Echo Cancel Loopback)";
            };
            "aec.args" = {
              "webrtc.gain_control" = true;
              "webrtc.extended_filter" = true;
              "webrtc.noise_suppression" = true;
            };
          };
        }
      ];
    };
    wireplumber.extraConfig = {
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
