{ config, pkgs, inputs, ... }:

{
  programs.yazi = {
    enable = true;

    flavors = {
      synthwave84 = inputs.synthwave84-yazi;
    };

    theme = {
      flavor = {
        dark = "synthwave84";
      };
    };
  };
}
