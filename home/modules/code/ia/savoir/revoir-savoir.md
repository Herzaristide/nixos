---
description: Passe en revue les skills et notes du coffre pour repérer ce qui a vieilli
argument-hint: [dossier ou sujet facultatif]
allowed-tools: Read, Glob, Grep, WebSearch, WebFetch, Bash(date *)
---

Passe en revue le savoir du coffre `~/v4ult` pour repérer ce qui a pu vieillir.
Périmètre : $ARGUMENTS (à défaut, `Skills/` puis `Recherche/`).

1. Liste les notes dont le champ `revu` date de plus de six mois, ou qui n'en
   ont pas, et celles qui portent un champ `versions`.
2. Pour chacune qui dépend d'une version, d'une API ou d'un outil, vérifie
   l'état actuel (documentation, changelog, web).
3. Ne modifie rien. Rends un tableau : note, ce qui a changé ou rien, gravité
   (obsolète / à ajuster / à jour), source.
4. Propose ensuite les corrections, et attends l'accord de l'utilisateur avant
   de toucher au moindre fichier.
