#!/usr/bin/env bash
# accent-sync — propagate the runtime accent color to all theme-aware tools.
#
# Usage: accent-sync "#rrggbb" [--no-hyprctl]
#
# Reads templates from ~/.config/accent/templates/ and writes:
#   ~/.config/accent/accent.hex            (state for fish hook + boot init)
#   ~/.config/accent/hyprland.conf         (sourced by Hyprland)
#   ~/.config/accent/starship.toml         (pointed to by STARSHIP_CONFIG)
#   ~/.config/accent/fastfetch-full.jsonc  (used by `nf`)
#   ~/.config/accent/fastfetch-logo.jsonc  (used by `nf`)
#   ~/.config/micro/colorschemes/accent.micro
#   ~/.config/accent/kitty-accent.conf  (included from ~/.config/kitty/kitty.conf)
#
# Live-reload:
#   - Hyprland: hyprctl keyword (unless --no-hyprctl)
#   - Kitty: SIGUSR1 to every running instance (re-reads kitty.conf + includes)
#   - Fish/starship: next prompt (fish hook re-sources starship)
#   - Fastfetch / micro: next launch (inherit kitty's color4/color12)
set -euo pipefail

# Path to the NixOS ASCII logo, baked in at build time by accent.nix.
FASTFETCH_LOGO="${FASTFETCH_LOGO:-@FASTFETCH_LOGO@}"

ACCENT_DIR="$HOME/.config/accent"
TEMPLATE_DIR="$ACCENT_DIR/templates"
mkdir -p "$ACCENT_DIR" \
         "$HOME/.config/micro/colorschemes" \
         "$HOME/.config/kitty"

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
render "$TEMPLATE_DIR/kitty-accent.conf.tmpl"    "$ACCENT_DIR/kitty-accent.conf"

# ── Live-reload Hyprland ──────────────────────────────────────────────────
if [ "$NO_HYPRCTL" -eq 0 ] && command -v hyprctl >/dev/null 2>&1; then
  hyprctl keyword general:col.active_border "rgba(${HEX}ff)" >/dev/null 2>&1 || true
fi

# ── Live-reload Kitty (set colors directly via remote control sockets) ────
# Each kitty instance listens on unix:/tmp/kitty-<pid>. We push the new
# palette to every running instance; --all applies to every window/tab,
# --configured makes it the default for new windows too.
for sock in /tmp/kitty-*; do
  [ -S "$sock" ] || continue
  kitten @ --to "unix:$sock" set-colors --all --configured \
    "$ACCENT_DIR/kitty-accent.conf" 2>/dev/null || true
done

exit 0
