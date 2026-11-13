# Serveur ComfyUI (génération d'images) sur le GPU ROCm de gary, piloté par
# Claude Code via son API HTTP (Tailscale) : POST /prompt, GET /history/<id>,
# GET /view. Plus de Krita (retiré 2026-11-13) : les images se régénèrent
# plutôt qu'elles ne se retouchent.
#
# Tout vient de nixpkgs (paquet `comfyui` + module `services.comfyui`), en
# cache : l'ancien montage maison (venv uv figé sur la release du plugin Krita
# AI Diffusion, nœuds personnalisés, download_models.py) a été supprimé. torch
# est la variante ROCm parce que gary pose `nixpkgs.config.rocmSupport`
# (hosts/gary/configuration.nix).
#
# État dans /var/lib/comfyui (modèles, images, base sqlite), que l'impermanence
# ne touche pas. Les modèles se déposent à la main dans models/<type>/, ou se
# déclarent ici via `services.comfyui.models` (url + hash + installPaths).
#
# Pas de démarrage au boot, et jamais en même temps que hunyuan3d (`conflicts`,
# réciproque) : à eux deux ils dépassent les 16 Gio de la RX 7600 XT. On le
# lance à la main : `sudo systemctl start comfyui`, puis `stop` après usage.
# Rien n'est ouvert sur le LAN : le service écoute sur 0.0.0.0 mais le port
# n'est ouvert que sur tailscale0.
{ lib, ... }:

let
  port = 8188;
in
{
  services.comfyui = {
    enable = true;
    inherit port;
    listen = [ "0.0.0.0" ];
  };

  systemd.services.comfyui = {
    # Le module démarre le service au boot ; ici, à la main seulement.
    wantedBy = lib.mkForce [ ];
    conflicts = [ "hunyuan3d.service" ];

    environment = {
      # Mêmes réglages ROCm que modules/hunyuan3d.nix (voir ses commentaires) :
      # la RX 7600 XT (gfx1102) vue comme gfx1100, l'iGPU écarté, l'attention
      # efficace activée sur RDNA3, les solveurs MIOpen « Winograd Fury »
      # coupés (ils plantent les convolutions fp16 des VAE sur la gfx1102).
      HSA_OVERRIDE_GFX_VERSION = "11.0.0";
      HIP_VISIBLE_DEVICES = "0";
      TORCH_ROCM_AOTRITON_ENABLE_EXPERIMENTAL = "1";
      MIOPEN_DEBUG_AMD_WINOGRAD_FURY_RXS_F2X3 = "0";
      MIOPEN_DEBUG_AMD_WINOGRAD_FURY_RXS_F3X2 = "0";
    };

    # Le module met PrivateUsers = true : les groupes video/render, qui
    # donnent accès à /dev/kfd et /dev/dri, y seraient vus comme « nogroup ».
    serviceConfig.PrivateUsers = lib.mkForce false;
  };

  networking.firewall.interfaces.tailscale0.allowedTCPPorts = [ port ];

  users.users.comfyui.extraGroups = [
    "video"
    "render"
  ];
}
