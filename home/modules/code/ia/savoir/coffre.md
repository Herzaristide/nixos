# Coffre v4ult — sessions de recherche

Ce dossier est le coffre Obsidian de l'utilisateur. Une session Claude Code
ouverte ici est une session de **recherche et d'apprentissage** (style
« chercheur ») : on y explore un sujet, on prototype dans `~/ciph3r/lab/`, et on
range le résultat dans le coffre.

Ce fichier est généré par la configuration NixOS
(`home/modules/code/ia/savoir.nix`) : le modifier ici ne survivra pas au
prochain rebuild.

## Structure

| Dossier | Contenu | Qui écrit |
|---|---|---|
| `Recherche/` | notes de fond | Claude (`/capitaliser`) et l'utilisateur |
| `Projets/` | une note par projet : décisions, savoir, liens | idem |
| `Skills/` | skills Claude Code, une par dossier (`SKILL.md`) | idem |
| `Lab/` | journaux des prototypes de `~/ciph3r/lab/` | idem |
| `_templates/` | modèles de note | l'utilisateur |
| `claude/` | journal automatique des sessions | **le hook `claude-journal` seul — ne jamais y écrire** |

## Conventions

- Markdown Obsidian, en français. Liens internes en `[[Titre de la note]]`.
- Chaque note commence par un en-tête YAML (les « propriétés » d'Obsidian) :
  voir `_templates/`. Ce que Claude écrit porte `statut: à-relire` jusqu'à ce que
  l'utilisateur le relise.
- Une skill n'est active que si `~/.claude/skills/<nom>` pointe vers
  `Skills/<nom>` (`ln -sfn`). `/capitaliser` crée le lien ; le rebuild NixOS les
  recrée tous.
- Ne déplace ni ne renomme une note existante sans le demander : les liens
  `[[…]]` des autres notes en dépendent.
