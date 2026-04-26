# Unified source of truth for both dark and light color palettes.
# Usage in Nix modules:
#   palette = if config.darkMode then (import ./home/palette.nix).dark
#                                 else (import ./home/palette.nix).light;
#
# base16 roles (both modes):
#   base00  default background        base08  red / danger
#   base01  elevated background       base09  orange / warning
#   base02  selection background      base0A  yellow
#   base03  muted / comments          base0B  green
#   base04  secondary foreground      base0C  teal / cyan
#   base05  main foreground           base0D  blue / accent  ← THE accent
#   base06  bright foreground         base0E  blue variant
#   base07  brightest                 base0F  coral / brown
#
# In light mode base00 is the lightest (near-white) and base07 the darkest
# (near-black), which is the standard base16 light-mode inversion.
{
  dark = {
    base00 = "0d0d0d"; # true black (matches binary wallpaper background)
    base01 = "1a1a1a"; # dark panel / hover background
    base02 = "2a2a2a"; # selection background
    base03 = "5a6080"; # muted labels / comments (cool blue-grey)
    base04 = "8a90b0"; # secondary text
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
  };

  light = {
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
    base0E = "2266bb"; # blue variant
    base0F = "bb2244"; # coral
  };
}
