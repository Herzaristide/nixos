{
  config,
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
              # Force stereo capture so the WebRTC AEC works even when the
              # physical source exposes more channels (e.g. Steinberg UR242
              # presents as analog-surround-40 / 4ch). Channels 1-2 (FL/FR)
              # are the actual mic preamp inputs on the UR242.
              "audio.channels" = 2;
              "audio.position" = [
                "FL"
                "FR"
              ];
            };
            "source.props" = {
              "node.name" = "echo-cancel-source";
              "node.description" = "Microphone (Echo Cancelled)";
              # Higher priority than hardware sources (default ~1000) so that
              # WirePlumber automatically selects this as the default capture
              # device. Without this, the raw UR242 4-channel source wins and
              # the voice assistant in QuickShell gets no usable mic signal.
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
      # Allow Chrome/BandLab PWA to access microphone and audio
      "50-chrome-bandlab-access" = {
        "access.rules" = [
          {
            matches = [
              { "application.process.binary" = "chromium"; }
              { "application.process.binary" = "chromium-browser"; }
            ];
            actions = {
              "update-props" = {
                "default_permissions" = "all";
              };
            };
          }
        ];
      };
    };
  };

  # Voice assistant (whisper STT + piper TTS)
  environment.systemPackages = with pkgs; [
    whisper-cpp
    piper-tts
    sox
    alsa-utils
  ];
}
