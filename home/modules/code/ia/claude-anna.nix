{
  anna,
  lib,
  pkgs,
  ...
}:

# Les sessions Claude Code, suivies en direct par anna (karenine, anna/src/claude/).
#
# Chaque processus `claude` signale ses étapes à `anna hook`, qui les transmet
# au daemon. La barre de karenine en tire un point par session (travaille /
# t'attend / au repos), et une bulle quand une session réclame l'utilisateur
# ou qu'un long tour se termine.
#
# PostToolUse sert à voir une attente levée (la permission accordée, l'outil
# a tourné) ; il passe après chaque outil, d'où un hook qui ne fait qu'une
# écriture sur la socket.
#
# PermissionRequest est le seul qui attend : il tient la demande pendant que
# la bulle propose Autoriser / Toujours / Refuser / Terminal. Sans réponse
# (barre absente, fenêtre de la session au premier plan, 5 min écoulées), il
# ne dit rien et Claude Code pose sa question dans le terminal, comme sans
# hook. Son délai doit donc dépasser les 300 s pendant lesquelles anna garde
# une demande (claude/permission.rs, ANSWER_WITHIN).
let
  # `|| true` : pour Claude Code, un hook qui sort en 2 bloque la demande ou
  # l'outil. `anna hook` sort toujours en 0, mais un anna plus ancien, sans la
  # sous-commande, sortirait justement en 2 — le garde-fou couvre ce cas.
  hook = timeout: {
    hooks = [
      {
        type = "command";
        command = "${lib.getExe anna} hook || true";
        inherit timeout;
      }
    ];
  };

  quick = [
    "SessionStart"
    "UserPromptSubmit"
    "PostToolUse"
    "Notification"
    "Stop"
    "SessionEnd"
  ];
in
{
  programs.claude-code.settings.hooks = lib.genAttrs quick (_: [ (hook 5) ]) // {
    PermissionRequest = [ (hook 330) ];
  };

  # Le modèle de transcription de la voix (anna/src/claude/voice.rs, Super+V) :
  # whisper.cpp « small », multilingue — le meilleur compromis précision /
  # vitesse en français sur processeur (~3,5 s pour une phrase). Lié depuis le
  # store, il survit à l'impermanence sans figurer dans sa liste.
  home.file.".local/share/anna/whisper/ggml-small.bin".source = pkgs.fetchurl {
    url = "https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-small.bin";
    sha256 = "0ywqxbziyp2bv72riyjpw4brk9v46d4cfbjfwqvvjrrq0srakqqv";
  };
}
