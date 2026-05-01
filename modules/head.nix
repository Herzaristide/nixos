{
  config,
  pkgs,
  inputs,
  ...
}:

{
  imports = [
    ./audio.nix
  ];

  # Disable the experimental Fontations (Rust/Skrifa) font rendering backend.
  # NixOS 26.05 enables FC_FONTATIONS=1 by default, but this causes white/blank
  # glyph squares in GTK popup windows (file dialogs, git popups, etc.).
  # Force the stable FreeType backend instead.
  environment.variables.FC_FONTATIONS = "0";

  # dconf: required for GTK app settings and GNOME applications
  programs.dconf.enable = true;

  # udisks2: detect and mount external drives (Dolphin/KIO handles VFS natively)
  services.udisks2.enable = true;

  # Power profiles daemon removed: conflicts with auto-cpufreq (see battery-optimization.nix)
  # services.power-profiles-daemon.enable = true;

  # UPower: battery monitoring service (used by quickshell and other desktop components)
  services.upower.enable = true;

  # XDG Portal (for file picker, screen sharing in Hyprland)
  # xdg-desktop-portal-kde exposes color-scheme (dark mode) to Chrome/Gemini, etc.
  # via kdeglobals — no GNOME/GTK infrastructure required.
  # xdph alone doesn't implement the appearance protocol.
  xdg.portal = {
    enable = true;
    extraPortals = [
      pkgs.xdg-desktop-portal-hyprland
      pkgs.kdePackages.xdg-desktop-portal-kde
    ];
    config.common = {
      default = "hyprland;kde";
      # xdph does not implement org.freedesktop.portal.Settings; route explicitly to kde
      # so Chromium and Qt apps read color-scheme from kdeglobals.
      "org.freedesktop.portal.Settings" = "kde";
    };
  };

  # X11 (for XWayland) and Hyprland
  services.xserver.enable = true;

  # Greetd with autologin directly to Hyprland (no greeter needed)
  # Use start-hyprland, not Hyprland: the wrapper sets XDG vars, portals, screen sharing
  services.greetd = {
    enable = true;
    settings = {
      initial_session = {
        command = "${config.programs.hyprland.package}/bin/start-hyprland";
        user = "aristide";
      };
      default_session = {
        command = "${config.programs.hyprland.package}/bin/start-hyprland";
        user = "aristide";
      };
    };
  };

  programs.hyprland.enable = true;
  services.xserver.xkb = {
    layout = "fr";
    variant = "";
  };

  # Audio
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
              { "application.process.binary" = "google-chrome-stable"; }
              { "application.process.binary" = "google-chrome"; }
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

  # Printing
  services.printing.enable = true;

  # Fonts — single font family: JetBrains Mono
  fonts = {
    enableDefaultPackages = false;
    fontconfig = {
      enable = true;
      defaultFonts = {
        serif = [ "JetBrains Mono" ];
        sansSerif = [ "JetBrains Mono" ];
        monospace = [ "JetBrains Mono" ];
        emoji = [ "JetBrains Mono" ];
      };
    };
    packages = with pkgs; [
      jetbrains-mono
      monocraft
    ];
  };

  # Chromium: extensions, dark mode, favorites — all in NixOS config
  programs.chromium = {
    enable = true;
    extensions = [
      "fcoeoabgfenejglbffodgkkbkcdhcgfn"
      "ddkjiahejlhfcafbddmgiahcphecmpfh"
      "effdbpeggelllpfkjppbokhmmiinhlmg"
    ];
    extraOpts = {
      ManagedBookmarks = [
        {
          name = "GitHub";
          url = "https://github.com";
        }
        {
          name = "Claude";
          url = "https://claude.ai";
        }
        {
          name = "Figma";
          url = "https://www.figma.com";
        }
      ];
    };
  };
  environment.systemPackages = with pkgs; [
    chromium
    brightnessctl
    grimblast
    libnotify
    # Voice assistant (whisper STT + piper TTS)
    whisper-cpp
    piper-tts
    sox
    alsa-utils
  ];
}
