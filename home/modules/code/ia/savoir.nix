{
  config,
  lib,
  ...
}:

# Le savoir réutilisable, rangé dans le coffre Obsidian.
#
# Les recherches de l'utilisateur (dev, IA, audio) finissent dans ses projets :
# ce qu'une session apprend doit donc revenir tout seul dans les suivantes. Le
# coffre ~/v4ult en est le support — lisible dans Obsidian, lu et écrit par
# Claude Code :
#   - /capitaliser tire d'une session une note, une skill ou une décision de
#     projet, et la range dans le coffre ;
#   - les skills vivent dans v4ult/Skills/ et sont activées par un lien chacune
#     dans ~/.claude/skills/ ;
#   - une session ouverte dans le coffre (fonction fish `recherche`) prend le
#     style « chercheur ».
#
# claude-journal.nix écrit à côté, dans v4ult/claude/, le journal brut des
# sessions : c'est la trace, ceci est le savoir qu'on en tire.
let
  vault = "${config.home.homeDirectory}/v4ult";
  skillsDir = "${config.programs.claude-code.configDir}/skills";

  dossiers = [
    "Recherche"
    "Projets"
    "Skills"
    "Lab"
    "_templates"
  ];

  templates = [
    "recherche"
    "skill"
    "projet"
    "lab"
  ];
in
{
  programs.claude-code = {
    # ~/.claude/CLAUDE.md : lu par toutes les sessions, donc gardé court — il
    # signale le coffre, il ne le recopie pas.
    context = ./savoir/contexte.md;

    outputStyles.chercheur = ./savoir/chercheur.md;

    commands = {
      capitaliser = ./savoir/capitaliser.md;
      revoir-savoir = ./savoir/revoir-savoir.md;
    };
  };

  # Ce qu'une session ouverte dans le coffre lit en premier. Liens vers le
  # store, donc en lecture seule dans Obsidian : la source est ici.
  home.file = {
    "v4ult/CLAUDE.md".source = ./savoir/coffre.md;

    # Réglages de projet du coffre. Obsidian ignore les dossiers cachés, il
    # n'affiche donc pas .claude/. L'écriture est bornée au coffre ; le web est
    # libre, c'est l'outil même d'une recherche.
    "v4ult/.claude/settings.json".text = builtins.toJSON {
      outputStyle = "chercheur";
      permissions.allow = [
        "WebSearch"
        "WebFetch"
        "Edit(~/v4ult/**)"
        "Bash(ln -sfn ~/v4ult/Skills/*)"
      ];
    };
  };

  # La structure du coffre et l'activation des skills.
  #
  # Les modèles sont copiés et non liés : l'utilisateur doit pouvoir les
  # retoucher dans Obsidian, et une copie existante n'est jamais écrasée.
  #
  # Une skill n'est vue par Claude Code qu'au premier niveau de ~/.claude/skills
  # (un lien vers v4ult/Skills entier n'expose rien — vérifié le 2026-10-15) :
  # d'où un lien par skill. /capitaliser crée le sien à la volée ; cette passe
  # les recrée tous et retire ceux dont la cible a disparu du coffre. Seuls les
  # liens qui pointent dans v4ult/Skills sont touchés : ceux de home-manager et
  # le dossier synced/ restent intacts.
  home.activation.savoirCoffre = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
    ${lib.concatMapStringsSep "\n" (d: ''run mkdir -p $VERBOSE_ARG "${vault}/${d}"'') dossiers}

    ${lib.concatMapStringsSep "\n" (t: ''
      if [ ! -e "${vault}/_templates/${t}.md" ]; then
        run install -m 0644 ${./savoir/templates + "/${t}.md"} "${vault}/_templates/${t}.md"
      fi
    '') templates}

    run mkdir -p $VERBOSE_ARG "${skillsDir}"
    for skill in "${vault}"/Skills/*/; do
      [ -f "$skill/SKILL.md" ] || continue
      name=$(basename "$skill")
      run ln -sfn $VERBOSE_ARG "${vault}/Skills/$name" "${skillsDir}/$name"
    done
    for link in "${skillsDir}"/*; do
      [ -L "$link" ] || continue
      case "$(readlink "$link")" in
        "${vault}/Skills/"*)
          [ -e "$link" ] || run rm -f $VERBOSE_ARG "$link"
          ;;
      esac
    done
  '';

  # Ouvre une session de recherche dans le coffre, puis revient au dossier de
  # départ. Les arguments passent à claude (`recherche "question…"`).
  programs.fish.functions.recherche = ''
    pushd ${vault}
    claude $argv
    popd
  '';
}
