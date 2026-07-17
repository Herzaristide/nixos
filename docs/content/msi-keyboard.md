---
title: Clavier RGB MSI (SteelSeries KLC)
group: Système
summary: État de la rétro-ingénierie du contrôleur SteelSeries KLC 1038:113a de zola — protocole, faits établis, pistes mortes et prochaines étapes.
links: [zola, quirks, theming]
---

# Clavier RGB MSI — SteelSeries KLC (1038:113a)

Le clavier de **zola** est rétroéclairé par un contrôleur USB interne
**SteelSeries KLC** (*Keyboard Light Controller*). Il n'a **aucun driver**
sous Linux, et son protocole n'est documenté nulle part. Ce document
rassemble ce qui a été établi en vue d'écrire un driver **OpenRGB**.

État actuel : **non fonctionnel**. `msiKeyboard.enable = false` sur zola —
plus rien dans la config n'écrit dans le contrôleur.

## Le périphérique

```
Bus 003 Device 0xx: ID 1038:113a SteelSeries ApS SteelSeries KLC
bcdDevice = 1.02   full-speed (12 Mbit/s)
```

Il est câblé en interne sur le port 9 du hub USB 2.0 (`00:14.0`), et sysfs le
situe dans la base du châssis — pas dans l'écran :

| Attribut | Valeur |
|---|---|
| `connect_type` | `hardwired` |
| `panel` / `lid` | `top` / `no` |
| `over_current_count` | `0` (n'a jamais monté) |

Le **clavier de frappe est un périphérique distinct** : il passe par le
contrôleur PS/2 hérité (`AT Translated Set 2 keyboard`, `i8042`), pas par
l'USB. Le KLC ne gère **que les LED** — il ne peut pas bloquer la saisie.

## Descripteur HID

Lu sur l'interface 0 (`/sys/kernel/debug/hid/0003:1038:113A.000X/rdesc`) :

```
06 c0 ff  09 01  a1 01        Collection (vendor 0xFFC0)
06 c1 ff  15 00  26 ff 00     Logical 0..255
75 08                         Report Size (8)
09 f0  95 40  81 02           Input   : 64 octets
09 f1  95 40  91 02           Output  : 64 octets
09 f2  96 0c 02  b1 02        Feature : 0x020c = 524 octets
c0
```

Trois points décisifs :

1. **Aucun `Report ID` déclaré** (pas un seul item `85 xx`). En hidraw, le
   premier octet du buffer doit donc être `0x00` — le noyau le retire avant
   l'envoi. En libusb, l'ID voyage dans `wValue` et n'est pas dans les données.
2. **Feature = 524 octets**, ce qui correspond exactement à la taille des
   paquets construits par `msi-rgb/msi_rgb_set.py`.
3. **Aucun endpoint OUT n'existe** : `ep_81` (64 o, IN) sur l'interface 0 et
   `ep_82` (4 o, IN) sur l'interface 1. L'Output report de 64 octets ne peut
   donc partir qu'en `SET_REPORT` control — et le device le **refuse** (`EIO`).
   Autrement dit, **la seule écriture qu'il accepte est le Feature de 524 o**.

## Protocole (état des connaissances)

Cible : **interface 0**. L'interface 1 existe mais ignore silencieusement les
feature reports.

### Paquet de région — 524 octets, accepté par le firmware

```
offset 0 : 0x0E  0x00  <region_id>  0x00        header (4 o)
offset 4 : 42 × 12 octets :
             RR GG BB 00 00 00 00 00 00 01 00 <keycode>
           (les touches non utilisées sont paddées à zéro)
offset 508 : 00 × 14  0x08 0x39                 trailer (16 o)
```

Quatre régions, dont les identifiants sont **validés par le firmware** :

| Région | `region_id` | Touches |
|---|---|---|
| `alphanum` | `0x2A` | 42 |
| `enter` | `0x0B` | 11 |
| `modifiers` | `0x18` | 24 |
| `numpad` | `0x24` | 36 |

Ces valeurs coïncident avec le nombre de touches de chaque région, mais ce
**ne sont pas des compteurs libres** : les modifier (ex. 23 touches +
`count=23`) fait rejeter le paquet. Ce sont des identifiants fixes.

### Commit — inconnu

`msi_rgb_set.py` envoie un paquet `refresh` de 64 octets (`0x09` + 63 zéros)
censé appliquer les couleurs. Il **ne fonctionne pas** :

- en Output control (`wValue=0x0200`) → `EIO`
- il n'existe aucun endpoint OUT pour l'envoyer autrement

**C'est la pièce manquante.** Sans commit valide, chaque paquet de région ne
produit qu'un flash : les LED s'allument une fraction de seconde puis
s'éteignent. Rien ne persiste.

## Faits établis

- Le **firmware allume le clavier** à la mise sous tension, et à l'extinction.
  Il s'éteint quand **le noyau prend la main** — `usbhid` se lie au device à
  ~1,7 s (`hid-generic 0003:1038:113A.0001: hiddev96,hidraw0`). Ce n'est pas
  la config NixOS qui l'éteint.
- **`bConfigurationValue = 1` est appliqué par le noyau tout seul.** La règle
  udev historique qui le forçait ne sert plus à rien (le commentaire du module
  affirmant que « the kernel ships with bConfigurationValue empty » est obsolète).
- **Détacher `usbhid` ne rallume pas le clavier** (contrairement à ce que
  rapporte le thread Arch ci-dessous). L'extinction vient du `SET_CONFIGURATION`
  de l'énumération, que l'unbind ne défait pas.
- **L'unbind est nécessaire pour libusb** : tant que `usbhid` tient les
  interfaces, libusb ne peut pas les claim — les écritures partent dans le vide
  (« writes succeeded with no error and the LEDs never changed »).
- Les **quatre paquets de région sont acceptés**, en hidraw comme en libusb.

## Pistes mortes

| Hypothèse | Verdict |
|---|---|
| Défaut matériel / nappe | **Faux** — le firmware allume le clavier au boot, `over_current_count=0` |
| Keycode `240` (`0xF0`) non standard | **Faux** — le paquet `modifiers` d'origine est accepté tel quel |
| Région `modifiers` fautive | **Faux** — acceptée seule |
| Délai inter-paquets (0,35 s trop court) | **Faux** — 0,6 s ne change rien |
| USB autosuspend (powertop) | **Faux** — `active_duration ≈ connected_duration` |
| OpenRGB éteignait le clavier | **Faux** — il ne détecte rien (0 contrôleur, aucun driver SteelSeries dans le binaire) |
| Le daemon anna écrivait le clavier | **Faux** — `msi::run()` n'est appelé que par `anna msi-rgb-watch` |
| Ajouter le préfixe `0x00` (report ID) suffit | **Insuffisant** — nécessaire en hidraw, mais ne règle pas le commit |

## L'obstacle méthodologique : le lien est non déterministe

Le contrôleur **décroche du bus par intermittence**, y compris **sans aucune
écriture** (des `-71` apparaissent au boot alors que `msi-rgb-boot` avait
skippé sans rien envoyer) :

```
usb 3-9: device descriptor read/64, error -71
usb 3-9: device not accepting address NN, error -71
usb usb3-port9: unable to enumerate USB device
```

Récupération : **`systemctl suspend`** (un reboot ne suffit pas — il ne coupe
pas le rail USB ; le resume réinitialise l'EC). Le device revient intact à
chaque fois, sans séquelle.

**Conséquence : aucun test unitaire n'est concluant.** Le même paquet, envoyé
à l'identique, a donné `OK`, `EPROTO (71)` et `ETIMEDOUT (110)` selon les
essais. Tout résultat sur un seul run est ininterprétable — succès comme échec
peuvent venir de l'instabilité du lien plutôt que du contenu.

## Prochaine étape : capturer le vrai protocole

Deviner est épuisé. La seule voie fiable est d'observer MSI Center piloter le
clavier :

**VM Windows + USB passthrough + `usbmon` côté hôte.** Le `1038:113a` est passé
à une VM QEMU/KVM (le passthrough marche sur un périphérique interne comme sur
n'importe quel autre), MSI Center le pilote depuis Windows, et la capture se
fait **depuis Linux** avec Wireshark sur `usbmon3` (bus 3). Équivalent
d'USBPcap, sans dual boot.

À chercher dans la capture : le **paquet d'initialisation / bascule en mode
logiciel** envoyé avant les couleurs, et la forme réelle du **commit**.

Wine ne convient pas : USBPcap est un driver kernel Windows, et MSI Center
charge ses propres drivers ring 0 pour l'EC.

## Références

- [OpenRGB #4827 — MSI GP66 Leopard 11UG with SteelSeries KLC](https://gitlab.com/CalcProgrammer1/OpenRGB/-/work_items/4827)
  — même `1038:113a`, **aucun driver, aucun protocole identifié**. Note que le
  device n'a été reconnu qu'après désactivation du **Fast Boot** dans le BIOS.
- [msi-perkeyrgb #57 — Mystic Light](https://github.com/Askannz/msi-perkeyrgb/issues/57)
  — `msi-perkeyrgb --id 1038:113a` **fonctionne** d'après un utilisateur de GE66
  (« when i supply KLC as the id it changes my keyboard »). Distingue
  `1038:113a` (KLC, clavier) de `1038:113c` (ALC, header Mystic Light).
- [msi-perkeyrgb #24 — Sending an effect without transitions bricks the backlight](https://github.com/Askannz/msi-perkeyrgb/issues/24)
  — le « bricking » est connu : le clavier disparaît de `lsusb`. Récupération
  par arrêt complet (chez nous, un suspend suffit).
- [Arch BBS #293009 — MSI Creator Z16 keyboard RGB (SOLVED)](https://bbs.archlinux.org/viewtopic.php?id=293009)
  — même PID ; solution par unbind de `usbhid`. Signale le même symptôme
  d'énumération intermittente.
- [msi-perkeyrgb](https://github.com/Askannz/msi-perkeyrgb) — cible `1038:1122`
  par défaut (GE63/GS65…), localise sa lib via `ldconfig -p` (cassé sur NixOS).
  Pas dans nixpkgs.

## Code

- `msi-rgb/msi_rgb_set.py` — l'implémentation hidraw actuelle (statique
  uniquement ; les effets animés wedgent le contrôleur). N'ajoute pas le
  préfixe `0x00` du report ID et garde le fd ouvert pour les quatre régions.
- `modules/msi-keyboard.nix` — module NixOS (règle udev, service de boot, hook
  de resume). **Désactivé** sur zola.
- `karenine/anna/src/msi.rs` — client qui reflétait l'accent sur le clavier
  (debounce 200 ms, cooldown 2 s). Lancé uniquement par `anna msi-rgb-watch`.
