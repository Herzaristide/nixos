{
  pkgs,
  config,
  lib,
  ...
}:

# Journal des sessions Claude Code, en Markdown, dans le coffre Obsidian.
#
# Un hook SessionEnd déclenche un résumé rédigé par un modèle : objectif,
# ce qui a été fait, décisions et reste à faire. Le diff n'est jamais recopié —
# git le détient déjà, et la note porte le SHA pour y renvoyer.
let
  journalDir = "${config.home.homeDirectory}/v4ult/claude";

  # Seuils sous lesquels aucune note n'est écrite : une question sans travail ne
  # mérite pas d'entrée et coûterait un appel modèle à chaque fois.
  minUserTurns = 3;
  minBodyChars = 1500;

  # Le transcript brut pèse ~1 Mo là où la conversation utile en fait 16 Ko :
  # les résultats d'outils et les blocs `thinking` sont 98 % du volume. On
  # n'envoie au modèle que les demandes et les réponses.
  extractJq = pkgs.writeText "claude-journal-extract.jq" ''
    if .type == "user" and (.message.content | type == "string") then
      "\n\n## Demande\n\n" + .message.content
    elif .type == "assistant" and (.message.content | type == "array") then
      (.message.content[] | select(.type == "text") | "\n\n## Réponse\n\n" + .text)
    else
      empty
    end
  '';

  promptFile = pkgs.writeText "claude-journal-prompt.txt" ''
    Tu rédiges l'entrée de journal d'une session de travail Claude Code, destinée
    au coffre Obsidian de l'utilisateur. La conversation arrive sur l'entrée
    standard.

    Réponds UNIQUEMENT en Markdown, en français, sans préambule ni conclusion, et
    sans envelopper le tout dans un bloc de code. Commence directement par le
    titre de niveau 2 `## Objectif`, et n'emploie jamais de titre de niveau 1 :
    la note en possède déjà un. Suis ce plan :

    ## Objectif
    Une ou deux phrases : ce que l'utilisateur voulait obtenir.

    ## Ce qui a été fait
    Trois à six puces. Nomme les fichiers touchés entre `backticks`.

    ## Décisions
    Les choix non évidents et leur raison — pourquoi telle approche plutôt
    qu'une autre. Omets entièrement la section s'il n'y en a pas.

    ## Reste à faire
    Ce qui est en attente, bloqué ou non vérifié. Omets la section s'il n'y a
    rien.

    Ne recopie jamais un secret (jeton, mot de passe, clé privée), même s'il
    apparaît dans la conversation.
  '';

  worker = pkgs.writeShellApplication {
    name = "claude-journal-worker";
    runtimeInputs = with pkgs; [
      claude-code
      coreutils
      git
      gnused
      util-linux # logger
    ];
    text = ''
      body=$1
      sid=$2
      cwd=$3
      trap 'rm -f "$body"' EXIT

      dir=${journalDir}
      mkdir -p "$dir"

      project=$(basename "$cwd")
      if [ -z "$project" ] || [ "$project" = "/" ]; then
        project=divers
      fi
      stamp=$(date +%Y-%m-%d)
      short=$(printf '%s' "$sid" | cut -c1-8)
      out="$dir/$stamp-$project-$short.md"

      # Idempotent : /clear et une reprise de session rejouent SessionEnd sous
      # le même identifiant.
      if [ -e "$out" ]; then
        exit 0
      fi

      # CLAUDE_JOURNAL_CHILD coupe le hook dans la session que `claude -p` ouvre
      # juste ici — sans quoi chaque session en engendrerait une infinité.
      summary=$(CLAUDE_JOURNAL_CHILD=1 timeout 300 \
        claude -p --model sonnet "$(cat ${promptFile})" < "$body" 2>/dev/null) || summary=""

      if [ -z "$summary" ]; then
        logger -t claude-journal "résumé vide ou en échec pour $project ($short)"
        exit 0
      fi

      # Le SHA n'est pas « le commit de la session » mais l'état du dépôt à sa
      # fermeture : un point d'ancrage exact, là où deviner les commits de la
      # session demanderait de borner une fenêtre de temps souvent fausse.
      head=$(git -C "$cwd" rev-parse --short HEAD 2>/dev/null || true)
      branch=$(git -C "$cwd" rev-parse --abbrev-ref HEAD 2>/dev/null || true)

      tmp=$(mktemp -t claude-journal-out-XXXXXX.md)
      {
        echo "---"
        echo "date: $stamp"
        echo "projet: $project"
        echo "session: $short"
        if [ -n "$branch" ]; then echo "branche: $branch"; fi
        if [ -n "$head" ]; then echo "commit: $head"; fi
        echo "tags: [claude/session]"
        echo "---"
        echo
        echo "# $project — $(date '+%d/%m %H:%M')"
        echo
        # Filet déterministe derrière la consigne du prompt : un « # Titre »
        # rendu par le modèle entrerait en collision avec le titre de la note.
        printf '%s\n' "$summary" | sed 's/^# /## /'
      } > "$tmp"

      # Écriture atomique : Obsidian surveille le dossier et afficherait sinon
      # un fichier tronqué.
      mv "$tmp" "$out"
      logger -t claude-journal "note écrite : $out"
    '';
  };

  hook = pkgs.writeShellApplication {
    name = "claude-journal";
    runtimeInputs = with pkgs; [
      coreutils
      jq
      util-linux # setsid
    ];
    text = ''
      # Garde-fou de récursion, côté hook cette fois : la session ouverte par le
      # worker ne doit pas se journaliser elle-même.
      if [ -n "''${CLAUDE_JOURNAL_CHILD:-}" ]; then
        exit 0
      fi

      payload=$(cat)
      transcript=$(printf '%s' "$payload" | jq -r '.transcript_path // empty')
      cwd=$(printf '%s' "$payload" | jq -r '.cwd // empty')
      sid=$(printf '%s' "$payload" | jq -r '.session_id // empty')

      if [ -z "$transcript" ] || [ ! -f "$transcript" ] || [ -z "$sid" ]; then
        exit 0
      fi

      turns=$(jq -r 'select(.type == "user" and (.message.content | type == "string")) | 1' \
        "$transcript" 2>/dev/null | wc -l)
      if [ "$turns" -lt ${toString minUserTurns} ]; then
        exit 0
      fi

      body=$(mktemp -t claude-journal-XXXXXX.md)
      jq -r -f ${extractJq} "$transcript" 2>/dev/null > "$body" || true

      if [ "$(wc -c < "$body")" -lt ${toString minBodyChars} ]; then
        rm -f "$body"
        exit 0
      fi

      # setsid : SessionEnd est le dernier souffle du process, un enfant
      # simplement mis en arrière-plan mourrait avec lui.
      setsid ${lib.getExe worker} "$body" "$sid" "$cwd" >/dev/null 2>&1 </dev/null &
      exit 0
    '';
  };
in
{
  # Pas de `matcher` : SessionEnd n'est pas un événement d'outil.
  programs.claude-code.settings.hooks.SessionEnd = [
    {
      hooks = [
        {
          type = "command";
          command = lib.getExe hook;
          timeout = 10;
        }
      ];
    }
  ];
}
