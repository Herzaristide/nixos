#!/usr/bin/env bash
# Apply saved Quickshell accent color to Hyprland borders on startup.
# Reads from ~/.config/quickshell/quickshell.conf (Qt QSettings INI format).

conf="$HOME/.config/quickshell/quickshell.conf"

if [ -f "$conf" ]; then
    # Find the [theme_v1] section and extract accentColorStr
    color=$(awk -F'=' '
        /^\[theme_v1\]/ { found=1; next }
        /^\[/           { found=0 }
        found && /^accentColorStr/ { gsub(/^[[:space:]]+|[[:space:]]+$/, "", $2); print $2; exit }
    ' "$conf")
fi

# Fall back to default indigo if nothing saved yet
color="${color:-#4a4a8e}"

# Convert #rrggbb → rgba(rrggbbff)
hex="${color#\#}"
hyprctl keyword "general:col.active_border" "rgba(${hex}ff)"
