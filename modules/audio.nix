{
  pkgs,
  inputs,
  ...
}:

{
  imports = [
    inputs.musnix.nixosModules.musnix
  ];

  musnix = {
    enable = true;
    alsaSeq.enable = true;
    kernel.realtime = false;
    soundcardPciId = "";
  };

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

  # Voice assistant (whisper STT + piper TTS)
  environment.systemPackages = with pkgs; [
    sox
    whisper-cpp
    piper-tts
    alsa-utils
    aubio
  ];
}
