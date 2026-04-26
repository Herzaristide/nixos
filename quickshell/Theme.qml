pragma Singleton
import QtQuick
import QtCore
import Quickshell.Io

QtObject {
    id: themeRoot

    // ── Persistence ───────────────────────────────────────────────────────
    // Only UI layout preferences live in QSettings.
    // The accent color is NOT stored here — accent.hex on disk is authoritative.
    property Settings themeSettings: Settings {
        category: "theme_v1"
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

    // ── Accent color — source of truth: ~/.config/accent/accent.hex ───────
    //
    // _accentStr is seeded with the palette default at build time (@PALETTE_ACCENT@),
    // then immediately overwritten by _accentFile once the file loads.
    // Any subsequent change — from the color picker, the terminal, or a rebuild —
    // writes accent.hex, which FileView detects and propagates here automatically.
    //
    // Flow: setAccentColor(str)
    //   → _accentStr = str  (instant visual feedback)
    //   → accent-sync writes str to accent.hex          (+ reloads kitty/Hyprland/VSCode/…)
    //   → _accentFile.fileChanged() fires
    //   → reload() → onLoaded → _readAccentFile()       (confirms / no-op)
    property string _accentStr: "@PALETTE_ACCENT@"
    readonly property color accentColor: _accentStr

    property FileView _accentFile: FileView {
        path: StandardPaths.writableLocation(StandardPaths.HomeLocation) + "/.config/accent/accent.hex"
        watchChanges: true
        // Silence "file not found" on first install — accentSeed creates the file
        // during home-manager activation; watchChanges catches it when it appears.
        printErrors: false
        onLoaded:      themeRoot._readAccentFile()
        onFileChanged: reload()
    }

    function _readAccentFile() {
        var c = _accentFile.text().trim()
        // Basic sanity check: must be a 7-char "#rrggbb" string
        if (c.length === 7 && c[0] === "#") themeRoot._accentStr = c
    }

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
        "#ccaa44"   // amber
    ]

    // ── Accent propagation ────────────────────────────────────────────────
    // accent-sync writes accent.hex first, then reloads kitty, Hyprland,
    // VSCode, starship and fastfetch.  The FileView watch above picks up
    // the accent.hex change and updates _accentStr automatically.
    property Process accentSync: Process {
        property string pendingColor: ""
        command: ["accent-sync", pendingColor]
    }

    // ── Setter ────────────────────────────────────────────────────────────
    function setAccentColor(str) {
        _accentStr = str        // instant visual feedback, no waiting for file I/O
        accentSync.pendingColor = str
        accentSync.running = true
    }
}

