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
#   base06  light foreground         base0E  purple
#   base07  bright foreground        base0F  coral / brown
{
  base00 = "1a1a2e"; # deep navy background
  base01 = "2a2a4e"; # darker hover / panel bg
  base02 = "3a3a6e"; # selection background
  base03 = "7777aa"; # muted labels / comments
  base04 = "aaaacc"; # dark foreground (secondary text)
  base05 = "e0e0ff"; # main foreground
  base06 = "f0f0ff"; # light foreground
  base07 = "ffffff"; # bright white
  base08 = "cc4444"; # red / danger
  base09 = "cc8844"; # orange / warning
  base0A = "cc9944"; # yellow
  base0B = "4a8e4a"; # green (RAM bar, in-tune)
  base0C = "4a8e8e"; # teal / cyan
  base0D = "4a4a8e"; # accent (window borders, active buttons)
  base0E = "8e4a8e"; # purple (GPU bar)
  base0F = "cc5544"; # coral
}
