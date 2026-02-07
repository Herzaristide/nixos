{ config, pkgs, inputs, lib, ... }:

let
  wallpaper = ../src/wallpaper.jpg;

  # Build-time derivation: run matugen on the wallpaper and produce a base16 JSON scheme
  # Matugen JSON structure: .colors.<color_name>.dark (not .colors.dark.<color_name>)
  matugen-scheme = pkgs.runCommand "matugen-base16-scheme" {
    nativeBuildInputs = [ pkgs.matugen pkgs.jq ];
  } ''
    # Generate Material You palette from the wallpaper
    matugen image ${wallpaper} --json hex > raw.json

    # Map Material You dark colors to base16 JSON
    ${pkgs.jq}/bin/jq '
      .colors as $c |
      def strip: ltrimstr("#");
      {
        scheme: "Material You (matugen)",
        author: "matugen",
        base00: ($c.surface.dark | strip),
        base01: ($c.surface_container_low.dark | strip),
        base02: ($c.surface_container.dark | strip),
        base03: ($c.outline_variant.dark | strip),
        base04: ($c.outline.dark | strip),
        base05: ($c.on_surface.dark | strip),
        base06: ($c.on_surface_variant.dark | strip),
        base07: ($c.surface_bright.dark | strip),
        base08: ($c.error.dark | strip),
        base09: ($c.tertiary.dark | strip),
        base0A: ($c.secondary.dark | strip),
        base0B: ($c.primary.dark | strip),
        base0C: ($c.on_tertiary_container.dark | strip),
        base0D: ($c.on_primary_container.dark | strip),
        base0E: ($c.on_secondary_container.dark | strip),
        base0F: ($c.error_container.dark | strip)
      }
    ' raw.json > $out
  '';

  # Import from derivation: read the JSON at eval time to get an attribute set
  scheme = builtins.fromJSON (builtins.readFile matugen-scheme);

in
{
  imports = [
    inputs.stylix.nixosModules.stylix
  ];

  stylix = {
    enable = true;
    image = wallpaper;
    base16Scheme = scheme;
    polarity = "dark";
  };
}
