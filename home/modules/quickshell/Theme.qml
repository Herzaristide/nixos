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
        "#4a4a8e",  // indigo (default)
        "#00FF88",  // terminal green
        "#4a8e8e",  // teal
        "#cc5544",  // coral
        "#cc9944",  // amber
        "#4a80cc"   // sky blue
    ]

    // ── Hyprland border sync (live) ───────────────────────────────────────
    property Process hyprSync: Process {
        property string pendingColor: ""
        // rgba(rrggbbaa) — Hyprland's format, full opacity
        command: ["hyprctl", "keyword", "general:col.active_border",
                  "rgba(" + pendingColor.replace("#", "") + "ff)"]
    }

    // ── Setter ────────────────────────────────────────────────────────────
    function setAccentColor(str) {
        themeSettings.accentColorStr = str
        hyprSync.pendingColor = str
        hyprSync.running = true
    }
}
