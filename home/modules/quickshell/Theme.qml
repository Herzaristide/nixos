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
