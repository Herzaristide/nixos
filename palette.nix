# Single source of truth for the system color palette.
# Used by Stylix (GTK, Qt, Hyprland, Wezterm, …) and referenced
# by quickshell.nix to seed Theme.qml's default accent at build time.
#
# base16 roles:
#   base00  deep background          base08  red / danger
#   base01  lighter background       base09  orange / warning
#   base02  selection background     base0A  yellow
#   base03  muted / comments         base0B  green
#   base04  dark foreground          base0C  teal / cyan
#   base05  foreground               base0D  blue / accent  ← THE accent
#   base06  light foreground         base0E  blue variant
#   base07  bright foreground        base0F  coral / brown
{
  base00 = "0d0d0d"; # true black (matches binary wallpaper background)
  base01 = "1a1a1a"; # dark panel / hover background
  base02 = "2a2a2a"; # selection background
  base03 = "5a6080"; # muted labels / comments (cool blue-grey)
  base04 = "8a90b0"; # dark foreground (secondary text)
  base05 = "e0e0ff"; # main foreground (matches Quickshell text #e0e0ff)
  base06 = "f0f0ff"; # light foreground (matches Quickshell #f0f0ff)
  base07 = "ffffff"; # bright white (matches Quickshell icon #FFFFFF)
  base08 = "cc4444"; # red / danger
  base09 = "cc8844"; # orange / warning
  base0A = "ccaa44"; # yellow
  base0B = "44aa88"; # green (teal-green, RAM bar, in-tune)
  base0C = "7ebae4"; # teal / cyan (NixOS logo light blue)
  base0D = "5277c3"; # blue / accent (NixOS primary blue — seeds Quickshell accent)
  base0E = "4488cc"; # blue variant (GPU bar)
  base0F = "cc5566"; # coral
}
