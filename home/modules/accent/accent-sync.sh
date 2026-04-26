#!/usr/bin/env bash
# accent-sync — propagate the runtime accent color to all theme-aware tools.
#
# Usage: accent-sync "#rrggbb" [--no-hyprctl]
#
# Reads templates from ~/.config/accent/templates/ and writes:
#   ~/.config/accent/accent.hex                  (state for fish hook + boot init)
#   ~/.config/accent/hyprland.conf               (sourced by Hyprland)
#   ~/.config/accent/starship.toml               (pointed to by STARSHIP_CONFIG)
#   ~/.config/accent/fastfetch-full.jsonc        (used by `nf`)
#   ~/.config/accent/fastfetch-logo.jsonc        (used by `nf`)
#   ~/.config/micro/colorschemes/accent.micro
#   ~/.config/wezterm/wezterm.lua                 (full config with accent baked in; auto-reloaded)
#
# Live-reload:
#   - Hyprland: hyprctl keyword (unless --no-hyprctl)
#   - WezTerm: auto (watches config dir for changes, reads accent.hex on reload)
#   - Fish/starship: next prompt (fish hook re-sources starship)
#   - Fastfetch / micro: next launch
set -euo pipefail

# Path to the NixOS ASCII logo, baked in at build time by accent.nix.
FASTFETCH_LOGO="${FASTFETCH_LOGO:-@FASTFETCH_LOGO@}"

ACCENT_DIR="$HOME/.config/accent"
TEMPLATE_DIR="$ACCENT_DIR/templates"
mkdir -p "$ACCENT_DIR" \
         "$HOME/.config/micro/colorschemes" \
         "$HOME/.config/wezterm" \
         "$HOME/.config/vesktop/settings"

# Cleanup any temporary files on exit (covers both success and error paths).
_TMPFILES=()
trap 'rm -f "${_TMPFILES[@]}"' EXIT

NO_HYPRCTL=0
COLOR=""
for arg in "$@"; do
  case "$arg" in
    --no-hyprctl) NO_HYPRCTL=1 ;;
    -*) echo "accent-sync: unknown flag $arg" >&2; exit 2 ;;
    *)  COLOR="$arg" ;;
  esac
done

if [ -z "$COLOR" ]; then
  echo "usage: accent-sync \"#rrggbb\" [--no-hyprctl]" >&2
  exit 2
fi

HEX="${COLOR#\#}"
HEX="$(printf '%s' "$HEX" | tr '[:upper:]' '[:lower:]')"
if ! printf '%s' "$HEX" | grep -qE '^[0-9a-f]{6}$'; then
  echo "accent-sync: invalid hex color '$COLOR'" >&2
  exit 1
fi

R=$((16#${HEX:0:2}))
G=$((16#${HEX:2:2}))
B=$((16#${HEX:4:2}))

# ── accent_dark = Qt.darker(c, 1.8) ≈ each component / 1.8 ────────────────
RD=$(awk -v v="$R" 'BEGIN { printf "%d", int(v/1.8 + 0.5) }')
GD=$(awk -v v="$G" 'BEGIN { printf "%d", int(v/1.8 + 0.5) }')
BD=$(awk -v v="$B" 'BEGIN { printf "%d", int(v/1.8 + 0.5) }')
HEX_DARK=$(printf '#%02x%02x%02x' "$RD" "$GD" "$BD")

# ── accent_muted = HSL(H, S*0.75, min(0.75, L*1.35)) ──────────────────────
read -r RM GM BM <<<"$(awk -v r="$R" -v g="$G" -v b="$B" '
function hue2rgb(p, q, t) {
    if (t < 0) t += 1
    if (t > 1) t -= 1
    if (t < 1.0/6.0) return p + (q - p) * 6 * t
    if (t < 0.5)     return q
    if (t < 2.0/3.0) return p + (q - p) * (2.0/3.0 - t) * 6
    return p
}
BEGIN {
    rr = r/255; gg = g/255; bb = b/255
    mx = (rr > gg) ? ((rr > bb) ? rr : bb) : ((gg > bb) ? gg : bb)
    mn = (rr < gg) ? ((rr < bb) ? rr : bb) : ((gg < bb) ? gg : bb)
    d  = mx - mn
    l  = (mx + mn) / 2
    if (d == 0) { h = 0; s = 0 }
    else {
        s = (l > 0.5) ? d / (2 - mx - mn) : d / (mx + mn)
        if (mx == rr)       h = (gg - bb) / d + ((gg < bb) ? 6 : 0)
        else if (mx == gg)  h = (bb - rr) / d + 2
        else                h = (rr - gg) / d + 4
        h *= 60
    }
    # transforms
    s *= 0.75
    new_l = l * 1.35
    if (new_l > 0.75) new_l = 0.75
    l = new_l
    # HSL → RGB
    if (s == 0) { rr = gg = bb = l }
    else {
        q = (l < 0.5) ? l * (1 + s) : l + s - l * s
        p = 2 * l - q
        hh = h / 360
        rr = hue2rgb(p, q, hh + 1.0/3.0)
        gg = hue2rgb(p, q, hh)
        bb = hue2rgb(p, q, hh - 1.0/3.0)
    }
    printf "%d %d %d", int(rr*255 + 0.5), int(gg*255 + 0.5), int(bb*255 + 0.5)
}')"
HEX_MUTED=$(printf '#%02x%02x%02x' "$RM" "$GM" "$BM")

ACCENT_ANSI="38;2;${R};${G};${B}"

# ── Render template helper ────────────────────────────────────────────────
render() {
  local src="$1" dst="$2"
  if [ ! -f "$src" ]; then
    echo "accent-sync: missing template $src" >&2
    return 1
  fi
  # Use a temp file then mv for atomic update (avoids partial reads on reload)
  local tmp
  tmp="$(mktemp "${dst}.XXXXXX")"
  _TMPFILES+=("$tmp")
  sed \
    -e "s|@ACCENT@|#${HEX}|g" \
    -e "s|@ACCENT_DARK@|${HEX_DARK}|g" \
    -e "s|@ACCENT_MUTED@|${HEX_MUTED}|g" \
    -e "s|@ACCENT_ANSI@|${ACCENT_ANSI}|g" \
    -e "s|@HEX@|${HEX}|g" \
    -e "s|@LOGO_PATH@|${FASTFETCH_LOGO}|g" \
    "$src" > "$tmp"
  mv -f "$tmp" "$dst"
}

# Persist the canonical state first (used by fish hook + boot init)
echo "#${HEX}" > "$ACCENT_DIR/accent.hex"

# Render every output
render "$TEMPLATE_DIR/hyprland.conf.tmpl"        "$ACCENT_DIR/hyprland.conf"
render "$TEMPLATE_DIR/starship.toml.tmpl"        "$ACCENT_DIR/starship.toml"
render "$TEMPLATE_DIR/fastfetch-full.jsonc.tmpl" "$ACCENT_DIR/fastfetch-full.jsonc"
render "$TEMPLATE_DIR/fastfetch-logo.jsonc.tmpl" "$ACCENT_DIR/fastfetch-logo.jsonc"
render "$TEMPLATE_DIR/micro.tmpl"                "$HOME/.config/micro/colorschemes/accent.micro"
render "$TEMPLATE_DIR/wezterm-accent.lua.tmpl"   "$HOME/.config/wezterm/wezterm.lua"
render "$TEMPLATE_DIR/vesktop-quickcss.css.tmpl"   "$HOME/.config/vesktop/settings/quickCss.css"

# ── Live-reload Hyprland ──────────────────────────────────────────────────
if [ "$NO_HYPRCTL" -eq 0 ] && command -v hyprctl >/dev/null 2>&1; then
  hyprctl keyword general:col.active_border "rgba(${HEX}ff)" >/dev/null 2>&1 || true
fi

# ── Live-reload WezTerm ───────────────────────────────────────────────────
# Writing ~/.config/wezterm/accent.lua triggers WezTerm's built-in file watcher.
# WezTerm reloads its entire Lua config, which calls read_accent() → accent.hex.
# No signal needed.

# ── Live-reload VSCode color customizations ───────────────────────────────
# settings.json is normally a nix-store symlink (read-only). We replace it
# with a writable regular file by using `mv` on the temp file, which unlinks
# the symlink and plants the new file at that path. VSCode watches its
# settings.json and hot-reloads changes within seconds.
VSCODE_SETTINGS="$HOME/.config/Code/User/settings.json"
if [ -e "$VSCODE_SETTINGS" ] || [ -L "$VSCODE_SETTINGS" ]; then
  # Alpha variants encoded as 8-digit #RRGGBBAA hex (supported by VSCode)
  A10="${HEX}1a"   # 10 % opacity — subtle highlight
  A20="${HEX}33"   # 20 % opacity — selection background
  A40="${HEX}66"   # 40 % opacity — scrollbar active

  tmp_colors="$(mktemp)"
  _TMPFILES+=("$tmp_colors")
  # Build the colorCustomizations patch as a JSON object
  jq -n \
    --arg a  "#${HEX}" \
    --arg d  "${HEX_DARK}" \
    --arg m  "${HEX_MUTED}" \
    --arg a10 "#${A10}" \
    --arg a20 "#${A20}" \
    --arg a40 "#${A40}" \
    '{
      "workbench.colorCustomizations": {
        "focusBorder":                          $a,
        "activityBar.activeBorder":             $a,
        "activityBar.activeBackground":         $a10,
        "button.background":                    $d,
        "button.hoverBackground":               $a,
        "badge.background":                     $a,
        "badge.foreground":                     "#ffffff",
        "activityBarBadge.background":          $a,
        "activityBarBadge.foreground":          "#ffffff",
        "progressBar.background":               $a,
        "editorCursor.foreground":              $a,
        "tab.activeBorderTop":                  $a,
        "panelTitle.activeBorder":              $a,
        "list.activeSelectionBackground":       $a20,
        "list.focusHighlightForeground":        $a,
        "scrollbarSlider.activeBackground":     $a40,
        "inputOption.activeBorder":             $a,
        "breadcrumb.activeSelectionForeground": $m,
        "editor.findMatchBorder":               $a,
        "sash.hoverBorder":                     $a,
        "notificationLink.foreground":          $a,
        "notificationsInfoIcon.foreground":     $a,
        "notificationCenter.border":            $a,
        "notificationCenterHeader.background":  $d,
        "notificationCenterHeader.foreground":  "#ffffff",
        "notifications.border":                 $a,
        "notificationToast.border":             $a,
        "extensionButton.prominentBackground":  $d,
        "extensionButton.prominentHoverBackground": $a,
        "terminal.ansiBlue":                    $a,
        "terminal.ansiBrightBlue":              $m,
        "terminal.tab.activeBorder":            $a,
        "terminalCursor.foreground":            $a,
        "terminal.findMatchBorder":             $a,
        "terminal.findMatchHighlightBorder":    $m
      }
    }' > "$tmp_colors"

  # Merge the patch into the existing settings (the nix store copy is readable
  # even as a symlink). `mv` atomically replaces the symlink with a real file.
  tmp_out="$(mktemp)"
  _TMPFILES+=("$tmp_out")
  if jq -s '.[0] * .[1]' "$VSCODE_SETTINGS" "$tmp_colors" > "$tmp_out" 2>/dev/null; then
    mv -f "$tmp_out" "$VSCODE_SETTINGS"
  fi
fi

exit 0
