{
  config,
  pkgs,
  lib,
  ...
}:

{
  # The starship binary + fish integration; the actual config (~/.config/accent/starship.toml)
  # is generated at runtime by paletted to keep the accent color dynamic.
  # STARSHIP_CONFIG is set in home/modules/accent/accent.nix.
  programs.starship = {
    enable = true;
    enableFishIntegration = true;
    # No `settings` block on purpose: a non-empty value would write ~/.config/starship.toml
    # and conflict with STARSHIP_CONFIG pointing to ~/.config/accent/starship.toml.
  };
}
