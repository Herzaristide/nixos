---
title: Audio
group: Système
summary: PipeWire (ALSA/JACK/Pulse), réglages basse latence, echo-cancel et outils d'assistant vocal.
links: [system-modules, home-manager]
---

# Audio (PipeWire)

Configuré dans `modules/audio.nix` (voir [Modules système](#system-modules)).

## Réglages basse latence

musnix a été retiré le 2026-07-19. Le noyau temps réel n'est pas envisageable
sur bernanos (le pilote NVIDIA propriétaire refuse de compiler contre
`CONFIG_PREEMPT_RT`) et n'est pas nécessaire ici : PipeWire + rtkit tiennent
3-6 ms sur un buffer de 128-256 frames, sous le seuil de perception. musnix
forçait de surcroît `cpuFreqGovernor = "performance"` sans `mkDefault`, ce qui
écrasait le `powersave` de bernanos.

Ce qu'il apportait réellement est désormais écrit directement dans le module :

- `threadirqs` — les interruptions deviennent ordonnançables, donc l'IRQ de la
  carte son peut être priorisée.
- `snd-seq` / `snd-rawmidi` — séquenceur ALSA, indispensable au MIDI.
- `vm.swappiness = 10` — évite le swap des buffers audio.
- Limites PAM `@audio` (`rtprio 99`, `memlock unlimited`) pour les applications
  qui demandent le temps réel sans passer par rtkit.
- Règles udev sur `rtc0`, `hpet`, `cpu_dma_latency`.
- Chemins de recherche des plugins (`LV2_PATH`, `VST3_PATH`, `CLAP_PATH`…) —
  sans eux un hôte ne trouve pas les plugins installés par Nix.

En cas de craquements, augmenter la taille du buffer avant de penser au noyau RT.

## PipeWire

- Support **ALSA + Pulse + JACK** (pour les applications audio pro).
- Module d'**annulation d'écho** (webrtc-aec, `monitor.mode`) : expose
  `echo-cancel-source`, le micro par défaut moins ce que joue la sortie par
  défaut (lue sur son moniteur). Seule anna l'écoute (mot d'activation
  « Karénine » et dictée) : la lecture n'est ni détournée ni retardée, le micro
  par défaut reste brut, sans gain automatique ni suppression de bruit. Testé
  le 16/10/2026 : ~26 dB d'atténuation, score du mot 0,99 → 0,00 sur des clips
  joués par les haut-parleurs.
- Règle WirePlumber : chromium reçoit `default_permissions = "all"` pour que la
  PWA BandLab puisse enregistrer l'audio.

## Assistant vocal

Outils préinstallés : `whisper-cpp`, `sox`, `aubio`. Les réponses du pilote sont lues par anna elle-même (voix Piper sous `~/.local/share/anna/piper/`, liées par `home/modules/code/ia/claude-anna.nix`), sans le paquet `piper-tts`.
