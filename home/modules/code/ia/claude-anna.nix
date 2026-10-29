{
  lib,
  pkgs,
  ...
}:

# Les modèles de la voix d'anna (karenine, anna/src/claude/) : ce qui écoute
# (Parakeet) et ce qui parle (Piper). Liés depuis le store, ils survivent à
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
  parakeetRev = "8f23f0c03c8761650bdb5b40aaf3e40d2c15f1ce";
  parakeet = [
    {
      file = "nemo128.onnx";
      hash = "sha256-qf3hSG6/zAjzKNda1GEMZ4Nf6ljHO6V+Mgmm9s8Bnp8=";
    }
    {
      file = "encoder-model.int8.onnx";
      hash = "sha256-YTnS+n4bCGCXsnfHFJcl7bq4nMfHrmSyPHQb5AVa/wk=";
    }
    {
      file = "decoder_joint-model.int8.onnx";
      hash = "sha256-7qdIPuPRowN12u3I7YPjlgyRsJiBISeg2Z0ciXdmenA=";
    }
    {
      file = "vocab.txt";
      hash = "sha256-1YVEZ56kvGrFY9H1Ret9R0vWz6Rn8KbiwdwcfTfjw10=";
    }
  ];
in
{
  # Le modèle de transcription de la voix (anna/src/claude/parakeet.rs, Super+V) :
  # Parakeet TDT 0.6B v3 de NVIDIA (CC-BY-4.0), export ONNX int8 d'onnx-asr.
  # Il tourne sur le processeur (~0,3 s pour une phrase sur bernanos, environ
  # 6 fois plus vite que whisper « small »), sans carte graphique, et reconnaît
  # seul la langue parmi 25 langues européennes.
  home.file = lib.listToAttrs (
    map (f: {
      name = ".local/share/anna/parakeet/${f.file}";
      value.source = pkgs.fetchurl {
        url = "https://huggingface.co/istupakov/parakeet-tdt-0.6b-v3-onnx/resolve/${parakeetRev}/${f.file}";
        inherit (f) hash;
      };
    }) parakeet
  )
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
