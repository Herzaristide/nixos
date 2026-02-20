{ config, pkgs, inputs, ... }:

{
  imports = [
    inputs.musnix.nixosModules.musnix
  ];

  musnix = {
    enable = true;
    alsaSeq.enable = true;
    kernel.realtime = false;
    soundcardPciId = "";
  };
}
