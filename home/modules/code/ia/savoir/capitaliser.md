---
description: Range dans le coffre Obsidian ce que la session a appris de réutilisable (note, skill, note projet)
argument-hint: [sujet ou consigne facultative]
allowed-tools: Read, Glob, Grep, Edit(~/v4ult/**), Bash(ln -sfn ~/v4ult/Skills/*), Bash(date *)
---

Tire de cette session ce qui mérite d'être gardé, et range-le dans le coffre
Obsidian `~/v4ult`. Consigne de l'utilisateur, s'il y en a une : $ARGUMENTS

## 1. Trier

Relis la conversation et isole ce qui sera **réutilisé** : une technique, un
pattern, une décision et sa raison, un piège, une configuration qui marche. Ignore
le déroulé de la session — le hook `claude-journal` en garde déjà la trace dans
`~/v4ult/claude/`, n'y écris jamais.

Range chaque élément dans **une** de ces catégories :

| Catégorie | Quand | Où |
|---|---|---|
| **skill** | une procédure ou un pattern réutilisable d'un projet à l'autre, que Claude devra appliquer seul | `Skills/<nom-kebab>/SKILL.md` |
| **recherche** | du savoir de fond, une comparaison, une explication | `Recherche/<Titre>.md` |
| **projet** | une décision ou un savoir propre à un projet | une section datée dans `Projets/<projet>.md` |
| **lab** | un prototype qui marche, dans `~/ciph3r/lab/` | `Lab/<sujet>.md` |

Avant d'écrire, cherche dans le coffre une note existante sur le même sujet
(`Grep` sur `Recherche/`, `Skills/`, `Projets/`, `Lab/`) : **complète-la** plutôt
que d'en créer une seconde, et mets alors à jour son champ `revu`.

Rien de réutilisable ? Dis-le en une ligne et n'écris rien.

## 2. Écrire

Les modèles sont dans `~/v4ult/_templates/` : suis celui de la catégorie. Pour
toutes les notes :

- un en-tête YAML avec au moins `type`, `sujets`, `date`, `revu` (aujourd'hui,
  via `date +%Y-%m-%d`), `statut: à-relire`, et `projet` / `session` (8 premiers
  caractères de l'identifiant de session) quand ils s'appliquent ;
- `versions` pour tout ce qui dépend d'une version d'outil ou de bibliothèque ;
- des liens `[[…]]` vers les notes voisines du coffre, et des liens web vers
  les sources ;
- en français, dense, sans le récit de la session.

Pour une **skill** :

- `name` en kebab-case, identique au nom du dossier ;
- une `description` qui dit **quand** l'utiliser : c'est elle qui décide si
  Claude la charge, sois précis sur les déclencheurs ;
- un corps actionnable : étapes, extraits minimaux, pièges ;
- puis active-la : `ln -sfn ~/v4ult/Skills/<nom> ~/.claude/skills/<nom>`.

Pour une note **projet**, si `Projets/<projet>.md` n'existe pas, crée-la depuis
le modèle `projet`.

## 3. Rendre compte

Termine par la liste des fichiers créés ou modifiés, un par ligne, avec la
catégorie et une phrase de contenu. Rappelle que tout est en `statut: à-relire`.
