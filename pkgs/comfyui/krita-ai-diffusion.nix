# Release de l'extension Krita AI Diffusion (Acly/krita-ai-diffusion), et ce
# qu'elle exige de son serveur ComfyUI (ai_diffusion/backend/resources.py de
# cette release) : la révision de ComfyUI et celles des nœuds personnalisés.
# Lu par modules/krita.nix (l'extension, sur bernanos) et modules/comfyui.nix
# (le serveur, sur gary) : client et serveur sont toujours de la même release.
#
# 1.54.0-pre plutôt que 1.53.0 (dernière stable) : nixpkgs fournit Krita 6, et
# la 1.53 refuse de se charger hors de Krita 5.x (ai_diffusion/__init__.py).
#
# Mettre à jour : nouvelle `version` + `hash` (zip décompressé), puis reprendre
# `comfy_version` et `required_custom_nodes` / `optional_custom_nodes` de
# resources.py, et les dépendances Python dans pyproject.toml (à côté).
{
  version = "1.54.0-pre";
  url = "https://github.com/Acly/krita-ai-diffusion/releases/download/v1.54.0-pre/krita_ai_diffusion-1.54.0-pre.zip";
  hash = "sha256-0okMfg1XOyopbWmTzGESN0jVCCNP0hR5B3bomYsAj3Q=";

  comfyui = {
    owner = "comfyanonymous";
    repo = "ComfyUI";
    rev = "e9027f2b30f37bb3052714eb08fcf479542f4fc0";
    hash = "sha256-iXRJsZVjZ70VfNCGcUhp+PlYUF8IXItmqlPpDReF5Uk=";
  };

  # `folder` : nom du dossier sous custom_nodes/, celui que l'extension attend.
  customNodes = [
    {
      folder = "comfyui_controlnet_aux";
      owner = "Fannovel16";
      repo = "comfyui_controlnet_aux";
      rev = "e8b689a513c3e6b63edc44066560ca5919c0576e";
      hash = "sha256-tMmERf4y7sfuEGao7JHC7FLjBgPuViCtHxr8f9NnHzo=";
    }
    {
      folder = "ComfyUI_IPAdapter_plus";
      owner = "cubiq";
      repo = "ComfyUI_IPAdapter_plus";
      rev = "b188a6cb39b512a9c6da7235b880af42c78ccd0d";
      hash = "sha256-PeJ+V0I+soHXwZhrXpJ2lQnB0GloKQImUQt28OLVIm8=";
    }
    {
      folder = "comfyui-tooling-nodes";
      owner = "Acly";
      repo = "comfyui-tooling-nodes";
      rev = "b3ae4aa2d98f6ac4284ddbe261e3559c94bd652b";
      hash = "sha256-4kcay93sZdu7802gLtN3p0c0DHsjQzQiD/y4DoSSSp8=";
    }
    {
      folder = "comfyui-inpaint-nodes";
      owner = "Acly";
      repo = "comfyui-inpaint-nodes";
      rev = "bd6d8fd5104d539187dfb172d07352215c09fcaa";
      hash = "sha256-g6E1ix1zJDAER8Ti1NyevM+yiqM+Jj2F4UpeWpHP60g=";
    }
    # Facultatif pour l'extension : les modèles quantifiés (Flux en GGUF).
    {
      folder = "ComfyUI-GGUF";
      owner = "city96";
      repo = "ComfyUI-GGUF";
      rev = "01f8845bf30d89fff293c7bd50187bc59d9d53ea";
      hash = "sha256-KOhmFyLjCz0nQnH68ScMg35IQvJe1WTSeKoydZ144mI=";
    }
  ];
}
