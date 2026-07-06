---
title: Audio
group: Système
summary: musnix + PipeWire (ALSA/JACK/Pulse), echo-cancel et outils d'assistant vocal.
links: [system-modules, home-manager]
---

# Audio (musnix + PipeWire)

Configuré dans `modules/audio.nix` (voir [Modules système](#system-modules)),
avec l'input `musnix` du [flake](#flake).

## musnix

- `alsaSeq.enable = true` (MIDI).
- `kernel.realtime = false` — noyau RT désactivé par défaut ; à activer pour une
  latence ultra-basse.

## PipeWire

- Support **ALSA + Pulse + JACK** (pour les applications audio pro).
- Module d'**annulation d'écho** chargé (webrtc-aec) : expose les nœuds virtuels
  `echo-cancel-source` / `echo-cancel-sink`. Ajouté à l'origine pour corriger la
  boucle de rétroaction de l'assistant vocal (le TTS piper était retranscrit par
  whisper).
- Règle WirePlumber : chromium reçoit `default_permissions = "all"` pour que la
  PWA BandLab puisse enregistrer l'audio.

## Assistant vocal

Outils préinstallés : `whisper-cpp`, `piper-tts`, `sox`, `aubio`.
