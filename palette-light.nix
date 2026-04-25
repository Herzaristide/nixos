# Light-mode variant of palette.nix.
# base16 convention: base00 is the default background (lightest in light mode),
# base07 is the brightest foreground (darkest in light mode).
# Semantic colors (base08-base0F) are darkened vs the dark palette for
# adequate contrast on a near-white background.
#
# base16 roles:
#   base00  default background        base08  red / danger
#   base01  lighter background        base09  orange / warning
#   base02  selection background      base0A  yellow
#   base03  muted / comments          base0B  green
#   base04  secondary foreground      base0C  teal / cyan
#   base05  main foreground           base0D  blue / accent
#   base06  dark secondary text       base0E  purple
#   base07  darkest (near-black)      base0F  coral / brown
{
  base00 = "f5f5ff"; # near-white with blue tint (default background)
  base01 = "eaeaff"; # panel / elevated background
  base02 = "d8d8f5"; # selection / hover background
  base03 = "8888aa"; # muted labels / comments
  base04 = "5a5a80"; # secondary foreground text
  base05 = "1a1a3e"; # main foreground (matches Quickshell textPrimary light)
  base06 = "0d0d28"; # dark secondary headings
  base07 = "060610"; # near-black (brightest base16 slot = darkest in light mode)
  base08 = "cc2222"; # red / danger
  base09 = "b85c00"; # orange / warning
  base0A = "8a7000"; # yellow (darkened for contrast on light background)
  base0B = "2a8855"; # green
  base0C = "1a77bb"; # teal / cyan
  base0D = "3355aa"; # blue / accent (darker variant of 5277c3 for light bg contrast)
  base0E = "5533aa"; # purple
  base0F = "bb2244"; # coral
}
