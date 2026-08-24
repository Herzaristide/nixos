# Swap compressé en RAM (pas de swap disque). Sert de filet anti-OOM : les
# pages froides sont compressées en RAM plutôt que paginées sur le SSD.
# Aucun impact sur btrfs/LUKS/impermanence (rien à chiffrer ni à persister).
# On ne touche pas à vm.swappiness (audio.nix le fixe à 10) : swappiness bas =
# zram n'agit que sous pression réelle, sans pagination agressive.
# L'hibernation étant coupée par security.protectKernelImage, pas besoin de
# swap disque dimensionné sur la RAM.
{
  zramSwap = {
    enable = true;
    memoryPercent = 50;
  };
}
