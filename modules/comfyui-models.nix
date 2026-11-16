# Catalogue des poids ComfyUI de gary (consommé par modules/comfyui.nix).
#
# Un groupe = une famille de modèles avec tout ce qu'il faut pour la faire
# tourner (diffusion, encodeur de texte, VAE…). Les fichiers communs à
# plusieurs groupes (qwen_3_4b, umt5_xxl…) sont dédoublonnés à l'usage.
#
# Choix des variantes, pour une RX 7600 XT (16 Gio, RDNA3, ROCm) :
#   - bf16/fp16 quand le modèle tient en VRAM ;
#   - sinon fp8 « scaled » (stockage fp8, calcul en bf16 : RDNA3 n'a pas de
#     calcul fp8 natif, ComfyUI convertit couche par couche) ou int8_convrot
#     (GEMM int8 WMMA par le backend HIP de comfy-kitchen, pkgs/comfy-kitchen-hip.nix) ;
#   - jamais nvfp4 / mxfp8 / w4a4 : formats Blackwell, sans noyau sur gfx11.
#
# Chaque URL est figée sur une révision Hugging Face (/resolve/<commit>/) et
# son hash vient du sha256 LFS publié par l'API (pas de téléchargement pour
# l'obtenir). Régénérer : lister /api/models/<repo>/tree/<rev>?recursive=true
# et convertir `lfs.oid` (hex) en SRI.
#
# Exclus faute de tenir dans 16 Gio de VRAM + RAM raisonnable, ou de poids
# publics : FLUX.2 dev (35 Go + 18 Go d'encodeur), Qwen-Image 1/2512 (20 Go
# en fp8), MiniMax H3 vidéo/image, HiDream, LTX-2.3 (22B), Wan 14B bf16 ;
# FLUX.2 klein 9B (poids de diffusion absents du dépôt Comfy-Org) ;
# Hunyuan3D (abandonné : perfs insuffisantes). Non retenus faute d'apport
# par rapport à un modèle déjà présent : FLUX.1, Chroma, SD 3.5, Stable
# Audio Open 1.0, HunyuanVideo 720p/1080p.
{
  # Stable Diffusion 1.5 (fp16) — petit, rapide, énorme écosystème de LoRA/ControlNet (~2.1 Go)
  sd15 = [
    {
      name = "v1-5-pruned-emaonly-fp16.safetensors";
      installPaths = "checkpoints";
      url = "https://huggingface.co/Comfy-Org/stable-diffusion-1.5/resolve/9cfd069101959ca3828bf9c04a4419870832b74f/v1-5-pruned-emaonly-fp16.safetensors";
      hash = "sha256-6UdqE3KM112Cefbsi611OmahlXyjdaFGTcY7N9tuORY=";
    }
  ];

  # SDXL base 1.0 — référence 1024², LoRA/ControlNet abondants (~6.9 Go)
  sdxl = [
    {
      name = "sd_xl_base_1.0.safetensors";
      installPaths = "checkpoints";
      url = "https://huggingface.co/stabilityai/stable-diffusion-xl-base-1.0/resolve/462165984030d82259a11f4367a4eed129e94a7b/sd_xl_base_1.0.safetensors";
      hash = "sha256-MeNcgPxIKdFPkBU/THTNWckLd59q/gWnTNYSC4k/fls=";
    }
  ];

  # Z-Image Turbo (bf16, 8 pas) — photoréalisme, très bon rapport qualité/vitesse (~20.7 Go)
  zimage = [
    {
      name = "z_image_turbo_bf16.safetensors";
      installPaths = "diffusion_models";
      url = "https://huggingface.co/Comfy-Org/Z-Image-Turbo/resolve/6fc90a3b1b653e935a0d175e260736de25b84df5/split_files/diffusion_models/z_image_turbo_bf16.safetensors";
      hash = "sha256-JAdhMFC4Cf/f8YpKyZr4Pqa5VEPs69+A4GSnnIJVdKY=";
    }
    {
      name = "qwen_3_4b.safetensors";
      installPaths = "text_encoders";
      url = "https://huggingface.co/Comfy-Org/Z-Image-Turbo/resolve/6fc90a3b1b653e935a0d175e260736de25b84df5/split_files/text_encoders/qwen_3_4b.safetensors";
      hash = "sha256-bGcUmFc6wvelUBUCzM6NKwjqbKL2YcRY5wjzazbt/Fo=";
    }
    {
      name = "ae.safetensors";
      installPaths = "vae";
      url = "https://huggingface.co/Comfy-Org/Z-Image-Turbo/resolve/6fc90a3b1b653e935a0d175e260736de25b84df5/split_files/vae/ae.safetensors";
      hash = "sha256-r8jignLNFds5GbrNtpGM6cHtIulssSxNXtD7qCNSnjg=";
    }
  ];

  # FLUX.2 [klein] 4B distillé — génération + édition multi-référence (4 pas) (~16.1 Go)
  flux2klein = [
    {
      name = "flux-2-klein-4b.safetensors";
      installPaths = "diffusion_models";
      url = "https://huggingface.co/Comfy-Org/Flux-2-Klein-4B/resolve/5b3abca5c0dc1ecd4eaf3340868d09063fc1c965/split_files/diffusion_models/flux-2-klein-4b.safetensors";
      hash = "sha256-7D1Oczp3H2HAUvtIVsSLM2xV6vLGVIfCofrrm72no0M=";
    }
    {
      name = "qwen_3_4b.safetensors";
      installPaths = "text_encoders";
      url = "https://huggingface.co/Comfy-Org/Flux-2-Klein-4B/resolve/5b3abca5c0dc1ecd4eaf3340868d09063fc1c965/split_files/text_encoders/qwen_3_4b.safetensors";
      hash = "sha256-bGcUmFc6wvelUBUCzM6NKwjqbKL2YcRY5wjzazbt/Fo=";
    }
    {
      name = "flux2-vae.safetensors";
      installPaths = "vae";
      url = "https://huggingface.co/Comfy-Org/Flux-2-Klein-4B/resolve/5b3abca5c0dc1ecd4eaf3340868d09063fc1c965/split_files/vae/flux2-vae.safetensors";
      hash = "sha256-ho/ns0PMjzoZ28/K+8PV+IiAK+P4m9gbZbNiGgZs6PM=";
    }
  ];

  # Qwen-Image 2.1 (bf16) + LoRA Turbo — 2e des poids ouverts sur Artificial
  # Analysis (Elo 1047, nov. 2026, à égalité statistique avec le 1er), le mieux
  # classé qui tienne sur gary et se télécharge sans compte. Texte dans
  # l'image, consignes complexes, édition multi-images. Le modèle de base est
  # celui du classement (≈ 25 pas) ; la LoRA Turbo le ramène à quelques pas.
  # bf16 plutôt qu'int8 pour la diffusion : 14,2 Go, quasi entier en VRAM, sans
  # dépendre des noyaux int8 HIP ; l'encodeur (qwen3vl 8B) reste en int8, il ne
  # tourne qu'une fois par prompt. Licence Qwen Research : non commercial.
  # (~25.2 Go)
  qwenimage = [
    {
      name = "qwen_image_2.1_bf16.safetensors";
      installPaths = "diffusion_models";
      url = "https://huggingface.co/Comfy-Org/Qwen-Image-2.1/resolve/aacf31a6d48e707f352ecba714cee0680da3479b/diffusion_models/qwen_image_2.1_bf16.safetensors";
      hash = "sha256-ifQVjQZswzkGoZn8qFY092aJLdePSbZpjavxh6yGxLw=";
    }
    {
      name = "qwen_image_2.1_turbo_lora_avg_rank_178_bf16.safetensors";
      installPaths = "loras";
      url = "https://huggingface.co/Comfy-Org/Qwen-Image-2.1/resolve/aacf31a6d48e707f352ecba714cee0680da3479b/loras/qwen_image_2.1_turbo_lora_avg_rank_178_bf16.safetensors";
      hash = "sha256-II3UMlDh4BRnuhkFcq4ucQenhw7B/wJrxl95H6HoDpU=";
    }
    {
      name = "qwen3vl_8b_int8_convrot.safetensors";
      installPaths = "text_encoders";
      url = "https://huggingface.co/Comfy-Org/Qwen-Image-2.1/resolve/aacf31a6d48e707f352ecba714cee0680da3479b/text_encoders/qwen3vl_8b_int8_convrot.safetensors";
      hash = "sha256-i/0PbhKr8tLWl+zIiOXpCw1nQdZwjwV5n1OvpWBFLo8=";
    }
    {
      name = "qwen_image_2.1_vae_bf16.safetensors";
      installPaths = "vae";
      url = "https://huggingface.co/Comfy-Org/Qwen-Image-2.1/resolve/aacf31a6d48e707f352ecba714cee0680da3479b/vae/qwen_image_2.1_vae_bf16.safetensors";
      hash = "sha256-uyH3RzBR4aw2hRXdPy4VzUTXoRdI7ogj4d3KPkh2t8k=";
    }
  ];

  # Krea 2 Turbo (fp8) — esthétique « photo », styles (~18.6 Go)
  krea2 = [
    {
      name = "krea2_turbo_fp8_scaled.safetensors";
      installPaths = "diffusion_models";
      url = "https://huggingface.co/Comfy-Org/Krea-2/resolve/588feaf955b08b9ac4723eeb751752ab045dba71/diffusion_models/krea2_turbo_fp8_scaled.safetensors";
      hash = "sha256-603YxhLP0Q9k8lsFfm5rvLVzfJSnNyF35Fbb91eVAvE=";
    }
    {
      name = "qwen3vl_4b_fp8_scaled.safetensors";
      installPaths = "text_encoders";
      url = "https://huggingface.co/Comfy-Org/Krea-2/resolve/588feaf955b08b9ac4723eeb751752ab045dba71/text_encoders/qwen3vl_4b_fp8_scaled.safetensors";
      hash = "sha256-VL1RRN8LvCXdbMrfy4JrUhRFobBq5aQlcL3Sl0yocJQ=";
    }
    {
      name = "qwen_image_vae.safetensors";
      installPaths = "vae";
      url = "https://huggingface.co/Comfy-Org/Krea-2/resolve/588feaf955b08b9ac4723eeb751752ab045dba71/vae/qwen_image_vae.safetensors";
      hash = "sha256-pwWA8CE+Z5Z+6clfBbtADo+wgwfgF6kkvzRBIj4CPR8=";
    }
  ];

  # Wan 2.2 TI2V 5B (fp16) — texte/image → vidéo 720p, tient entier en VRAM (~18.1 Go)
  wan5b = [
    {
      name = "wan2.2_ti2v_5B_fp16.safetensors";
      installPaths = "diffusion_models";
      url = "https://huggingface.co/Comfy-Org/Wan-2.2/resolve/ee6f4a40737a995bf5818954cfce6d59443b0f04/split_files/diffusion_models/wan2.2_ti2v_5B_fp16.safetensors";
      hash = "sha256-RW+QEzi9nq297TgouBkQmpto6KUlylz40ASaafz+yh4=";
    }
    {
      name = "umt5_xxl_fp8_e4m3fn_scaled.safetensors";
      installPaths = "text_encoders";
      url = "https://huggingface.co/Comfy-Org/Wan-2.2/resolve/ee6f4a40737a995bf5818954cfce6d59443b0f04/split_files/text_encoders/umt5_xxl_fp8_e4m3fn_scaled.safetensors";
      hash = "sha256-wzVdMBkfHwZrJtk/ugF66YCdzmxifdpfambqplEgT2g=";
    }
    {
      name = "wan2.2_vae.safetensors";
      installPaths = "vae";
      url = "https://huggingface.co/Comfy-Org/Wan-2.2/resolve/ee6f4a40737a995bf5818954cfce6d59443b0f04/split_files/vae/wan2.2_vae.safetensors";
      hash = "sha256-5AMhvTa5cJmR2uJTDrSsMD3RaCdpgNPpvEtuK3X+0VY=";
    }
  ];

  # Wan 2.2 I2V 14B (fp8, high + low noise) + LoRA lightx2v 4 pas — image → vidéo, meilleure qualité, déchargement RAM (~38.0 Go)
  wan14b = [
    {
      name = "wan2.2_i2v_high_noise_14B_fp8_scaled.safetensors";
      installPaths = "diffusion_models";
      url = "https://huggingface.co/Comfy-Org/Wan-2.2/resolve/ee6f4a40737a995bf5818954cfce6d59443b0f04/split_files/diffusion_models/wan2.2_i2v_high_noise_14B_fp8_scaled.safetensors";
      hash = "sha256-YSLnnVXg8jVpjRHWV/OxlsUnPIMNoAsrATxaBI1eakI=";
    }
    {
      name = "wan2.2_i2v_low_noise_14B_fp8_scaled.safetensors";
      installPaths = "diffusion_models";
      url = "https://huggingface.co/Comfy-Org/Wan-2.2/resolve/ee6f4a40737a995bf5818954cfce6d59443b0f04/split_files/diffusion_models/wan2.2_i2v_low_noise_14B_fp8_scaled.safetensors";
      hash = "sha256-VHGkV7asQEICpfvmwRWVo9VkH8dmsA84dj9yMD//wh4=";
    }
    {
      name = "wan2.2_i2v_lightx2v_4steps_lora_v1_high_noise.safetensors";
      installPaths = "loras";
      url = "https://huggingface.co/Comfy-Org/Wan-2.2/resolve/ee6f4a40737a995bf5818954cfce6d59443b0f04/split_files/loras/wan2.2_i2v_lightx2v_4steps_lora_v1_high_noise.safetensors";
      hash = "sha256-0XbICNb8RhmZto4yHvy3UBsguMN5dSPtDfFPfR3v8R4=";
    }
    {
      name = "wan2.2_i2v_lightx2v_4steps_lora_v1_low_noise.safetensors";
      installPaths = "loras";
      url = "https://huggingface.co/Comfy-Org/Wan-2.2/resolve/ee6f4a40737a995bf5818954cfce6d59443b0f04/split_files/loras/wan2.2_i2v_lightx2v_4steps_lora_v1_low_noise.safetensors";
      hash = "sha256-Ak8h3glbyPrZgJ3tPp5JouFw3PJwddqBRbp9YNiqt/k=";
    }
    {
      name = "umt5_xxl_fp8_e4m3fn_scaled.safetensors";
      installPaths = "text_encoders";
      url = "https://huggingface.co/Comfy-Org/Wan-2.2/resolve/ee6f4a40737a995bf5818954cfce6d59443b0f04/split_files/text_encoders/umt5_xxl_fp8_e4m3fn_scaled.safetensors";
      hash = "sha256-wzVdMBkfHwZrJtk/ugF66YCdzmxifdpfambqplEgT2g=";
    }
    {
      name = "wan_2.1_vae.safetensors";
      installPaths = "vae";
      url = "https://huggingface.co/Comfy-Org/Wan-2.2/resolve/ee6f4a40737a995bf5818954cfce6d59443b0f04/split_files/vae/wan_2.1_vae.safetensors";
      hash = "sha256-L8OdMTWaSwpk9Vh22P9/qNeAlWriyxNGOwIj4VFIl2s=";
    }
  ];

  # HunyuanVideo 1.5 480p (fp8) — texte → vidéo (cfg-distillé) et image → vidéo (step-distillé) (~29.9 Go)
  hunyuanvideo = [
    {
      name = "hunyuanvideo1.5_480p_t2v_cfg_distilled_fp8_scaled.safetensors";
      installPaths = "diffusion_models";
      url = "https://huggingface.co/Comfy-Org/Hunyuan-Video-1.5/resolve/1405a2b738c29b890cf6d03fc038d8d3e92eeed7/split_files/diffusion_models/hunyuanvideo1.5_480p_t2v_cfg_distilled_fp8_scaled.safetensors";
      hash = "sha256-4dvs5rNtSjuvejceZVwSfbESMxlcXd5EzgwIgx+St98=";
    }
    {
      name = "hunyuanvideo1.5_480p_i2v_step_distilled_fp8_scaled.safetensors";
      installPaths = "diffusion_models";
      url = "https://huggingface.co/Comfy-Org/Hunyuan-Video-1.5/resolve/1405a2b738c29b890cf6d03fc038d8d3e92eeed7/split_files/diffusion_models/hunyuanvideo1.5_480p_i2v_step_distilled_fp8_scaled.safetensors";
      hash = "sha256-MCY2JjrQHiZZoYt46W6V9EQzuS3vfK4dqym1EF7rY7E=";
    }
    {
      name = "qwen_2.5_vl_7b_fp8_scaled.safetensors";
      installPaths = "text_encoders";
      url = "https://huggingface.co/Comfy-Org/Hunyuan-Video-1.5/resolve/1405a2b738c29b890cf6d03fc038d8d3e92eeed7/split_files/text_encoders/qwen_2.5_vl_7b_fp8_scaled.safetensors";
      hash = "sha256-y1Y22FKg6mqQdasb70lsDbeu8TwCNQVx44iuqVnFwLQ=";
    }
    {
      name = "byt5_small_glyphxl_fp16.safetensors";
      installPaths = "text_encoders";
      url = "https://huggingface.co/Comfy-Org/Hunyuan-Video-1.5/resolve/1405a2b738c29b890cf6d03fc038d8d3e92eeed7/split_files/text_encoders/byt5_small_glyphxl_fp16.safetensors";
      hash = "sha256-UWkQu0ybIlNwKQ5AWF0bDmyM01g2kPfuwvf7WTmQ+0g=";
    }
    {
      name = "hunyuanvideo15_vae_fp16.safetensors";
      installPaths = "vae";
      url = "https://huggingface.co/Comfy-Org/Hunyuan-Video-1.5/resolve/1405a2b738c29b890cf6d03fc038d8d3e92eeed7/split_files/vae/hunyuanvideo15_vae_fp16.safetensors";
      hash = "sha256-58MJGUnCfi1Vrm1d+Re5na3+u/MI5aUNCt4NFskCl64=";
    }
    {
      name = "sigclip_vision_patch14_384.safetensors";
      installPaths = "clip_vision";
      url = "https://huggingface.co/Comfy-Org/Hunyuan-Video-1.5/resolve/1405a2b738c29b890cf6d03fc038d8d3e92eeed7/split_files/clip_vision/sigclip_vision_patch14_384.safetensors";
      hash = "sha256-H+5QHeq6xy8O0XYQMH1xMePp0eg40DY6o8K5em4D+zM=";
    }
  ];

  # ACE-Step 1.5 Turbo (tout-en-un) — musique complète avec paroles (~10.0 Go)
  acestep = [
    {
      name = "ace_step_1.5_turbo_aio.safetensors";
      installPaths = "checkpoints";
      url = "https://huggingface.co/Comfy-Org/ACE-Step-1.5/resolve/371bb1680f8c88d8c1083f6ffb6330d3d55bff76/checkpoints/ace_step_1.5_turbo_aio.safetensors";
      hash = "sha256-Z7D0OqXFHIQL0CKOapNdj/QW7Ifl3y/AY32helYSUrw=";
    }
  ];

  # Stable Audio 3 (medium + small music + small sfx) — boucles, bruitages, ambiances (~15.0 Go)
  stableaudio = [
    {
      name = "stable_audio_3_medium.safetensors";
      installPaths = "checkpoints";
      url = "https://huggingface.co/Comfy-Org/stable-audio-3/resolve/75aad8836271cb5a5123fb58304fae5d3bb4b0f9/checkpoints/stable_audio_3_medium.safetensors";
      hash = "sha256-SNnGXikOe81RlOBjO/wkJKWe6Wg/XC1Ydi2Ze32M4LU=";
    }
    {
      name = "stable_audio_3_small_music.safetensors";
      installPaths = "checkpoints";
      url = "https://huggingface.co/Comfy-Org/stable-audio-3/resolve/75aad8836271cb5a5123fb58304fae5d3bb4b0f9/checkpoints/stable_audio_3_small_music.safetensors";
      hash = "sha256-2oWGaxGwHQaU2ZB4X2q715yAZN8bDm+K6lKTXg74S2Q=";
    }
    {
      name = "stable_audio_3_small_sfx.safetensors";
      installPaths = "checkpoints";
      url = "https://huggingface.co/Comfy-Org/stable-audio-3/resolve/75aad8836271cb5a5123fb58304fae5d3bb4b0f9/checkpoints/stable_audio_3_small_sfx.safetensors";
      hash = "sha256-7ZzxthcvGowpIalWDCEQn/MjlSRWPO2dzm3N70Hi9RU=";
    }
    {
      name = "t5gemma_b_b_ul2.safetensors";
      installPaths = "text_encoders";
      url = "https://huggingface.co/Comfy-Org/stable-audio-3/resolve/75aad8836271cb5a5123fb58304fae5d3bb4b0f9/text_encoders/t5gemma_b_b_ul2.safetensors";
      hash = "sha256-Hh66Jb6Icu2w08YzXGZY/WOI57FLYNpuRU5ATPzYFQ4=";
    }
  ];

  # YuE 2 3B (bf16) — chansons avec voix, à partir de paroles. Meilleur score
  # ouvert de WildSongBench (6,73 en une passe, contre 6,01 pour ACE-Step 1,5 ;
  # benchmark publié par l'équipe YuE elle-même, sept. 2026). ~11 Gio de VRAM
  # au pic, ~70 s pour 3,6 min sur RTX 4090. Poids CC BY-NC 4.0 : non commercial.
  # (~9.2 Go)
  yue = [
    {
      name = "yue2_3b_bf16.safetensors";
      installPaths = "checkpoints";
      url = "https://huggingface.co/Comfy-Org/YuE2/resolve/2f76ca75e6ee094169de899cc7fc99d6887e2196/checkpoints/yue2_3b_bf16.safetensors";
      hash = "sha256-M3Za2/mBPJpQMYIYdgsv2BmjGYYkYKBIhGB1gZYcb+4=";
    }
    {
      name = "sheetsage2_bf16.safetensors";
      installPaths = "audio_encoders";
      url = "https://huggingface.co/Comfy-Org/YuE2/resolve/2f76ca75e6ee094169de899cc7fc99d6887e2196/audio_encoders/sheetsage2_bf16.safetensors";
      hash = "sha256-X9lgzj3ygePzqInRdFhNiPliR3EUgM+WN3sS1+i2rcU=";
    }
  ];

  # MiniMax Music 3 (DiT fp16, encodeur int8) — musique avec voix (~14.3 Go)
  minimaxmusic = [
    {
      name = "minimax_music3_dit_fp16.safetensors";
      installPaths = "diffusion_models";
      url = "https://huggingface.co/Comfy-Org/MiniMax-Music-3/resolve/9e364ccd290a401561091fb441ed19cd7de92550/diffusion_models/minimax_music3_dit_fp16.safetensors";
      hash = "sha256-RUlKK2tprxFZAv8o6vVBGNGQZ6pU2gEADz4+/Oe6DjQ=";
    }
    {
      name = "minimax_music3_text_encoder_pruned_int8_convrot.safetensors";
      installPaths = "text_encoders";
      url = "https://huggingface.co/Comfy-Org/MiniMax-Music-3/resolve/9e364ccd290a401561091fb441ed19cd7de92550/text_encoders/minimax_music3_text_encoder_pruned_int8_convrot.safetensors";
      hash = "sha256-AQt0FtIzagjHEbwi7mWEnJYjBp3bfYm+wBGnVpnlIBQ=";
    }
    {
      name = "minimax_music3_dav.safetensors";
      installPaths = "vae";
      url = "https://huggingface.co/Comfy-Org/MiniMax-Music-3/resolve/9e364ccd290a401561091fb441ed19cd7de92550/vae/minimax_music3_dav.safetensors";
      hash = "sha256-KjIVW3ab4BRF/MKoZjuRD8nhdR4Y3Bw+xSgGRRLZ7ww=";
    }
  ];

  # Ming 3.0 TTS tiny (int8) — synthèse vocale (~9.1 Go)
  tts = [
    {
      name = "ming3_tts_tiny_int8_convrot.safetensors";
      installPaths = "checkpoints";
      url = "https://huggingface.co/Comfy-Org/Ming-3.0-TTS/resolve/fde007af929a8878ff457c8aa2a2b93274d5113c/checkpoints/ming3_tts_tiny_int8_convrot.safetensors";
      hash = "sha256-N9g6SNyyDZicSDE+k/Dwh2o8gdVwlmwkQkCc8wKgPlM=";
    }
  ];

  # Real-ESRGAN x4 (image) + SeedVR2 3B fp16 / 7B fp8 (image et vidéo) (~15.6 Go)
  upscale = [
    {
      name = "RealESRGAN_x4plus.safetensors";
      installPaths = "upscale_models";
      url = "https://huggingface.co/Comfy-Org/Real-ESRGAN/resolve/5fd49b7b278836f48af63ecd314d0f98ab336105/RealESRGAN_x4plus.safetensors";
      hash = "sha256-N/mpMcIV8ECqbVD3EfLLEV9xPEbfHQ1kaai9e/6aYLs=";
    }
    {
      name = "seedvr2_3b_fp16.safetensors";
      installPaths = "diffusion_models";
      url = "https://huggingface.co/Comfy-Org/SeedVR2/resolve/df48879708206a403d2a61acd55578c2e80fd233/diffusion_models/seedvr2_3b_fp16.safetensors";
      hash = "sha256-mGaf0sBt9eyoi69ozVxHh3XI5h/BEOWYxSs1AUXqJmA=";
    }
    {
      name = "seedvr2_7b_fp8_e4m3fn.safetensors";
      installPaths = "diffusion_models";
      url = "https://huggingface.co/Comfy-Org/SeedVR2/resolve/df48879708206a403d2a61acd55578c2e80fd233/diffusion_models/seedvr2_7b_fp8_e4m3fn.safetensors";
      hash = "sha256-UGXnfWR91VPZCQqB4g1t5ZDZMaYd9514XgCEM5Ju5Bg=";
    }
    {
      name = "seedvr2_ema_vae_fp16.safetensors";
      installPaths = "vae";
      url = "https://huggingface.co/Comfy-Org/SeedVR2/resolve/df48879708206a403d2a61acd55578c2e80fd233/vae/seedvr2_ema_vae_fp16.safetensors";
      hash = "sha256-IGeFSPQg2Y0m8RRC01KPi4yU5X7gRu+T27djPahhLKE=";
    }
  ];

  # RIFE 4.26 + FILM — interpolation d'images (fluidifier une vidéo) (~0.1 Go)
  interpolation = [
    {
      name = "rife_v4.26.safetensors";
      installPaths = "frame_interpolation";
      url = "https://huggingface.co/Comfy-Org/Frame-Interpolation/resolve/aa7009be4d1471ea0bac91d6fe4d7e4b637cbbfc/frame_interpolation/rife_v4.26.safetensors";
      hash = "sha256-FRh0WSyHd0Dl2xFSL0UU31ae6vsKD8smlvFuno0xfJQ=";
    }
    {
      name = "film_net_fp16.safetensors";
      installPaths = "frame_interpolation";
      url = "https://huggingface.co/Comfy-Org/Frame-Interpolation/resolve/aa7009be4d1471ea0bac91d6fe4d7e4b637cbbfc/frame_interpolation/film_net_fp16.safetensors";
      hash = "sha256-8iblE3Xcg51LQOXD1j2lYN0eocliNk7Hj1rfLQXbBcA=";
    }
  ];

  # BiRefNet (détourage), Depth Anything 3 (profondeur), SAM 3.1 (segmentation) (~3.5 Go)
  vision = [
    {
      name = "birefnet.safetensors";
      installPaths = "background_removal";
      url = "https://huggingface.co/Comfy-Org/BiRefNet/resolve/884af709e9b795d89dafbf97f29c8d6a2386f5c6/background_removal/birefnet.safetensors";
      hash = "sha256-mrN0Jr9N4FZ69rXSGxYVE1cUkTk2Lm6JkgIbjONWoVQ=";
    }
    {
      name = "depth_anything_3_mono_large.safetensors";
      installPaths = "geometry_estimation";
      url = "https://huggingface.co/Comfy-Org/Depth-Anything-3/resolve/8265be070134dc7459217308cdc03109bde199b0/geometry_estimation/depth_anything_3_mono_large.safetensors";
      hash = "sha256-m0Ttpb7bpbThJWhv23nR2zCcG5eFJ3V265MPiFsAj5Y=";
    }
    {
      name = "sam3.1_multiplex_fp16.safetensors";
      installPaths = "checkpoints";
      url = "https://huggingface.co/Comfy-Org/sam3.1/resolve/7bb8374780a725b4353ed31f3a9395c9742b5621/checkpoints/sam3.1_multiplex_fp16.safetensors";
      hash = "sha256-m6mcknA8LotPR94tNKU5u44YkjBJ4ji3gNcNvmNo6wM=";
    }
  ];

  # TRELLIS.2 natif ComfyUI (bf16) — image → mesh 3D texturé (~13.6 Go)
  trellis2 = [
    {
      name = "trellis_2_bf16.safetensors";
      installPaths = "diffusion_models";
      url = "https://huggingface.co/Comfy-Org/TRELLIS.2/resolve/430a9d09b2416687018c8fe8edced2ad4858a439/diffusion_models/trellis_2_bf16.safetensors";
      hash = "sha256-v46+KfLXNyLKihe3qmXvB2UOsm0EeZrmAEggWPlpIbU=";
    }
    {
      name = "dino_v3_vit_l.safetensors";
      installPaths = "clip_vision";
      url = "https://huggingface.co/Comfy-Org/TRELLIS.2/resolve/430a9d09b2416687018c8fe8edced2ad4858a439/clip_vision/dino_v3_vit_l.safetensors";
      hash = "sha256-XLeF5FjefEYFeQgkGK+B9cYjgMGBWZNEvcYImMY0aO4=";
    }
    {
      name = "trellis_2_shape_vae_bf16.safetensors";
      installPaths = "vae";
      url = "https://huggingface.co/Comfy-Org/TRELLIS.2/resolve/430a9d09b2416687018c8fe8edced2ad4858a439/vae/trellis_2_shape_vae_bf16.safetensors";
      hash = "sha256-3gy0lJp2xZ7lwJGplaabzIxR1a7ak58MZBpQ0qcjQfQ=";
    }
    {
      name = "trellis_2_texture_vae_bf16.safetensors";
      installPaths = "vae";
      url = "https://huggingface.co/Comfy-Org/TRELLIS.2/resolve/430a9d09b2416687018c8fe8edced2ad4858a439/vae/trellis_2_texture_vae_bf16.safetensors";
      hash = "sha256-cU5evwlKYQ4SqOO1F1wYpi839upCGKy2BzZERWtzqw4=";
    }
  ];

}
