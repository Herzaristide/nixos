---
title: Sécurité & utilisateurs
group: Système
summary: Utilisateurs immuables, mots de passe hashés, groupes et allowlist sudo.
links: [system-modules, build]
---

# Sécurité & utilisateurs

Gérés principalement dans `modules/common.nix` (voir [Modules système](#system-modules)).

## Utilisateurs immuables

- `users.mutableUsers = false` — les mots de passe sont des **hashs SHA-512**
  inscrits dans `modules/common.nix`. `passwd`/`useradd` n'ont aucun effet :
  créer ou modifier un utilisateur se fait **uniquement via Nix**.

## L'utilisateur `aristide`

Groupes :

```
networkmanager wheel docker video render audio storage greeter gamemode
```

## Sudo

Allowlist **NOPASSWD** limitée à des requêtes matérielles en lecture seule :

- `smartctl`
- `dmidecode`

## Réseau

SSH est activé avec authentification par mot de passe, derrière le pare-feu
(voir `network.nix` dans [Modules système](#system-modules)).

## Métadonnées du dépôt

- Git : `Herzaristide <aristide.pichereau@gmail.com>`.
- Helper de credentials : `store` (texte clair).
- Secrets dans `secrets/` (git-ignoré).
