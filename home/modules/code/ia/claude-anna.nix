{
  lib,
  pkgs,
  ...
}:

# Les modèles de la voix d'anna (karenine, anna/src/claude/) : ce qui écoute
# (whisper) et ce qui parle (Piper). Liés depuis le store, ils survivent à
# l'impermanence sans figurer dans sa liste.
#
# Les sessions Claude Code, elles, ne sont plus suivies par anna : plus de
# hook `anna hook` dans la configuration de Claude Code.
let
  # Les voix qui lisent les réponses du pilote (anna/src/claude/speech.rs) :
  # Piper, modèles « medium » français (~60-75 Mo chacun), au choix dans les
  # réglages de karenine. upmc a deux locuteurs (jessica, pierre). Une voix =
  # le modèle .onnx + sa config .onnx.json.
  voices = [
    {
      file = "fr_FR-siwis-medium.onnx";
      dir = "siwis/medium";
      hash = "sha256-ZB0asJfaK4ESjAdoEO2wUrOF3syL4zgYFIAqZKc7r5k=";
    }
    {
      file = "fr_FR-siwis-medium.onnx.json";
      dir = "siwis/medium";
      hash = "sha256-OUeZFsLbGStayXZNrd0MdE2D4COtiQxpdsBjOuTfiVk=";
    }
    {
      file = "fr_FR-upmc-medium.onnx";
      dir = "upmc/medium";
      hash = "sha256-mrs4AMGZFIiXqe1k4QDSJPPeg1efEABEF0rRlBjxeG8=";
    }
    {
      file = "fr_FR-upmc-medium.onnx.json";
      dir = "upmc/medium";
      hash = "sha256-6GNuwV39XXLbN6AstTIKIPK40znyoOQzfaZMWKM6WGg=";
    }
    {
      file = "fr_FR-tom-medium.onnx";
      dir = "tom/medium";
      hash = "sha256-v2UHTM3u7qqDLnXtscClE8Acmpcr3whf+KbnHqI0/UE=";
    }
    {
      file = "fr_FR-tom-medium.onnx.json";
      dir = "tom/medium";
      hash = "sha256-L3+IWtWgqtgC48wk5PVyOf69yxQrSHbeXSOAlGdDYcw=";
    }
  ];
in
{
  # Le modèle de transcription de la voix (anna/src/claude/voice.rs, Super+V) :
  # whisper.cpp « small », multilingue — le meilleur compromis précision /
  # vitesse en français sur processeur (~3,5 s pour une phrase).
  home.file = {
    ".local/share/anna/whisper/ggml-small.bin".source = pkgs.fetchurl {
      url = "https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-small.bin";
      sha256 = "0ywqxbziyp2bv72riyjpw4brk9v46d4cfbjfwqvvjrrq0srakqqv";
    };
  }
  // lib.listToAttrs (
    map (v: {
      name = ".local/share/anna/piper/${v.file}";
      value.source = pkgs.fetchurl {
        url = "https://huggingface.co/rhasspy/piper-voices/resolve/main/fr/fr_FR/${v.dir}/${v.file}";
        inherit (v) hash;
      };
    }) voices
  );
}
