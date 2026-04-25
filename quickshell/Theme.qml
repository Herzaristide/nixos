pragma Singleton
import QtQuick
import QtCore
import Quickshell.Io

QtObject {
    id: themeRoot

    // ── Persistence ───────────────────────────────────────────────────────
    property Settings themeSettings: Settings {
        category: "theme_v1"
        property string accentColorStr: "@PALETTE_ACCENT@"
        property bool darkMode: true
    }

    // ── Dark / Light mode toggle ──────────────────────────────────────────
    readonly property bool darkMode: themeSettings.darkMode

    // Background surfaces  (dark: aligned with binary-black wallpaper palette.nix)
    //   base00 = 0d0d0d  • base01 = 1a1a1a  • base02 = 2a2a2a
    readonly property color bgDeep:     darkMode ? "#0d0d0d" : "#f2f2fa"
    readonly property color bgElevated: darkMode ? "#1a1a1a" : "#e2e2f0"
    readonly property color bgInput:    darkMode ? "#141414" : "#f8f8ff"

    // Dividers & overlays
    readonly property color dividerColor: darkMode ? Qt.rgba(1, 1, 1, 0.10) : Qt.rgba(0, 0, 0, 0.12)
    readonly property color hoverOverlay: darkMode ? Qt.rgba(1, 1, 1, 0.05) : Qt.rgba(0, 0, 0, 0.05)

    // Text hierarchy  (dark: base05/base04/base03 from palette.nix)
    //   base05 = e0e0ff  • base04 = 8a90b0  • base03 = 5a6080
    readonly property color textPrimary:   darkMode ? "#e0e0ff" : "#1a1a3e"
    readonly property color textSecondary: darkMode ? "#8a90b0" : "#555577"
    readonly property color textDim:       darkMode ? "#5a6080" : "#888899"
    readonly property color textInactive:  darkMode ? "#3e4060" : "#888888"
    readonly property color textSubtle:    darkMode ? "#2e3050" : "#999999"
    readonly property color textBody:      darkMode ? "#c8ccf0" : "#2a2a3e"

    // Icons & interactive elements
    readonly property color iconColor:         darkMode ? "#FFFFFF"   : "#222244"
    readonly property color placeholderColor:  darkMode ? "#30FFFFFF" : "#50000000"
    readonly property color selectedTextColor: darkMode ? "#000000"   : "#FFFFFF"

    // Canvas notation staff (r,g,b string for use in rgba() calls)
    readonly property string canvasLineRGB: darkMode ? "255,255,255" : "0,0,0"

    // ── Theme side-effects (GTK color-scheme + wallpaper) ─────────────────
    property Process gtkProcess: Process {
        property string pendingScheme: ""
        command: ["gsettings", "set", "org.gnome.desktop.interface",
                  "color-scheme", pendingScheme]
    }

    property Process wallpaperProcess: Process {
        property string pendingVariant: "dark"
        command: ["sh", "-c",
                  "awww img \"$HOME/.config/wallpaper-" + pendingVariant
                  + "\" --transition-type wipe --transition-fps 60"]
    }

    function toggleTheme() {
        themeSettings.darkMode = !themeSettings.darkMode
        gtkProcess.pendingScheme = themeSettings.darkMode ? "prefer-dark" : "prefer-light"
        gtkProcess.running = true
        wallpaperProcess.pendingVariant = themeSettings.darkMode ? "dark" : "light"
        wallpaperProcess.running = true
    }

    // ── Accent color ──────────────────────────────────────────────────────
    readonly property color accentColor: themeSettings.accentColorStr

    // Darker variant — used for hover backgrounds and separators
    readonly property color accentDark: Qt.darker(accentColor, 1.8)

    // Muted variant — used for section labels (desaturated, lighter)
    readonly property color accentMuted: Qt.hsla(
        accentColor.hslHue,
        accentColor.hslSaturation * 0.75,
        Math.min(0.75, accentColor.hslLightness * 1.35),
        1.0
    )

    // ── Preset palette ────────────────────────────────────────────────────
    readonly property var presets: [
        "#5277c3",  // NixOS blue (default)
        "#7ebae4",  // NixOS light blue
        "#44aa88",  // teal-green
        "#cc5544",  // coral
        "#ccaa44",  // amber
        "#7755cc"   // purple
    ]

    // ── Accent propagation (live) ─────────────────────────────────────────
    // Delegates to ~/.nix-profile/bin/accent-sync, which updates Hyprland borders,
    // starship, fastfetch, micro and wezterm in one shot.
    property Process accentSync: Process {
        property string pendingColor: ""
        command: ["accent-sync", pendingColor]
    }

    // ── Setter ────────────────────────────────────────────────────────────
    function setAccentColor(str) {
        themeSettings.accentColorStr = str
        accentSync.pendingColor = str
        accentSync.running = true
    }
}
