#!/usr/bin/env bash
# Migration unique vers le home déclaratif (voir modules/impermanence.nix).
#
# Ne copie ni ne supprime rien : renomme @home en @keep et crée le
# subvolume vierge @home-blank. Le rollback recréera @home au prochain boot.
#
#   sudo ./scripts/impermanence-migrate.sh
#   sudo nixos-rebuild boot --flake .#zola
#   reboot
#
# Le renommage est sûr à chaud : btrfs monte par subvolid, donc le /home
# actuellement monté continue de fonctionner jusqu'au reboot.
set -euo pipefail

DEV="/dev/mapper/cryptroot"
TMP="/btrfs_tmp"

[ "$EUID" -eq 0 ] || {
  echo "Doit être lancé en root." >&2
  exit 1
}
[ -e "$DEV" ] || {
  echo "$DEV introuvable." >&2
  exit 1
}

mkdir -p "$TMP"
mountpoint -q "$TMP" || mount -t btrfs -o subvolid=5 "$DEV" "$TMP"
trap 'umount "$TMP" 2>/dev/null || true' EXIT

echo "== État actuel =="
btrfs subvolume list "$TMP" | sed 's/^/  /'
echo

if [ -e "$TMP/@keep" ]; then
  echo "@keep existe déjà — migration déjà faite. Rien à faire."
  exit 0
fi

if [ ! -e "$TMP/@home" ]; then
  echo "@home introuvable. Abandon." >&2
  exit 1
fi

if [ ! -d "$TMP/@home/aristide" ]; then
  echo "@home ne contient pas aristide/ — layout inattendu. Abandon." >&2
  exit 1
fi

echo "== Renommage @home -> @keep =="
mv "$TMP/@home" "$TMP/@keep"

echo "== Création du subvolume vierge @home-blank =="
btrfs subvolume create "$TMP/@home-blank"

echo
echo "== Nouvel état =="
btrfs subvolume list "$TMP" | sed 's/^/  /'
echo
cat <<'EOF'
Migration OK. Rien n'a été supprimé.

  @keep     ← ton ancien home, intégral (Steam et orphelins compris)
  @home-blank  ← le gabarit vide
  @home        ← sera recréé au prochain boot par rollback-home

Suite :
  sudo nixos-rebuild boot --flake .#zola
  reboot

Au reboot, /home/aristide sera vide, sauf les chemins listés dans
environment.persistence (modules/impermanence.nix), rebranchés depuis
/keep/home/aristide/.

Si quelque chose manque : tout est intact dans /keep/home/aristide/.
Ajoute le chemin à la liste, rebuild, reboot.

Une fois serein, purge /keep/home/aristide/ de ce qui n'est pas dans la
liste (Steam = 35 Go) — c'est ta décision, pas celle de la migration.
EOF
