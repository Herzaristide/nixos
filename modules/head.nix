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

  # udisks2 + gvfs: detect and mount external drives (required for Nautilus "Other Locations")
  services.udisks2.enable = true;
  services.gvfs.enable = true;

  # Power profiles daemon removed: conflicts with auto-cpufreq (see battery-optimization.nix)
  # services.power-profiles-daemon.enable = true;

  # UPower: battery monitoring service (used by quickshell and other desktop components)
  services.upower.enable = true;

  # XDG Portal (for file picker, screen sharing in Hyprland)
  # xdg-desktop-portal-gtk exposes color-scheme (dark mode) to Chrome/Gemini, etc.
  # xdph alone doesn't implement the appearance protocol
  xdg.portal = {
    enable = true;
    extraPortals = [
      pkgs.xdg-desktop-portal-hyprland
      pkgs.xdg-desktop-portal-gtk
    ];
    config.common.default = "hyprland;gtk";
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

  # Fonts for Waybar, Rofi, Hyprlock, kurukurubar, etc.
  fonts = {
    enableDefaultPackages = true;
    fontconfig = {
      enable = true;
      defaultFonts = {
        serif = [
          "DejaVu Serif"
          "Liberation Serif"
          "Noto Serif"
        ];
        sansSerif = [
          "DejaVu Sans"
          "Liberation Sans"
          "Noto Sans"
          "Ubuntu"
          "Cantarell"
        ];
        monospace = [
          "DejaVu Sans Mono"
          "Liberation Mono"
          "Noto Sans Mono"
          "Ubuntu Mono"
        ];
        emoji = [ "Noto Color Emoji" ];
      };
    };
    packages = with pkgs; [
      jetbrains-mono # JetBrains Mono (used in terminal and bottom bar)
      nerd-fonts.monoid
      nerd-fonts.caskaydia-mono # For kurukurubar
      material-symbols # For kurukurubar Material Icons
      # System UI fonts (required for GTK apps like Nautilus, file dialogs, system popups)
      dejavu_fonts # DejaVu Sans/Serif/Mono
      liberation_ttf # Liberation Sans/Serif/Mono (metrics-compatible with Arial/Times/Courier)
      noto-fonts # Google Noto Sans/Serif
      noto-fonts-color-emoji # Emoji support
      ubuntu-classic # Ubuntu Sans/Mono (widely used in Linux apps)
      cantarell-fonts # Default GNOME font (required for GTK system dialogs)
      font-awesome # Icon font (for various applications)
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
