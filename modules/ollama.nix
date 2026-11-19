{
  config,
  lib,
  pkgs,
  ...
}:

# ollama — bernanos, gary, kafka. Le serveur écoute sur 127.0.0.1:11434, sauf
# sur gary, exposé au tailnet comme ComfyUI : `host = "0.0.0.0"` et le port
# ouvert sur tailscale0 seulement (hosts/gary/configuration.nix). Rien sur le LAN.
#
# Le paquet dépend du GPU de chaque machine, choisi dans hosts/<host> :
#   - bernanos : ollama-cuda (RTX 3070 Mobile, sm_86) — compile en local,
#     ~30 min, aucun cache CUDA ;
#   - gary     : ollama-rocm (RX 7600 XT, gfx1102 présentée en gfx1100) ;
#   - kafka    : ollama sur CPU (NVS 310 / nouveau, pas de calcul GPU).
#
# Les modèles vivent dans /var/lib/ollama (StateDirectory du service) : sous
# `/`, que l'impermanence ne touche pas — rien à déclarer pour qu'ils survivent.
#
# Modèles déclarés par hôte (`services.ollama.loadModels`, hosts/<host>) :
# `ollama-model-loader.service` les tire du registre après chaque démarrage
# d'ollama — contrairement à ComfyUI, ils ne passent pas par le store et les
# tags ne sont pas épinglés (un tag republié en amont peut changer).
# `syncModels` supprime tout modèle installé hors de la liste, y compris un
# `ollama pull` fait à la main : la liste fait foi (gary, bernanos). kafka n'a
# pas de liste : rien n'y est tiré ni effacé automatiquement.
{
  services.ollama = {
    enable = true;
    host = lib.mkDefault "127.0.0.1"; # gary : 0.0.0.0, ouvert sur tailscale0
    package = lib.mkDefault pkgs.ollama;
    # Seulement là où une liste est déclarée : avec une liste vide (kafka),
    # syncModels effacerait tous les modèles, même tirés à la main.
    syncModels = config.services.ollama.loadModels != [ ];
  };
}
