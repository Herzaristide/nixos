#!/usr/bin/env bash
# install-nixos — Interactive NixOS installer for the custom flake.
# Partitions disk with disko (LUKS + btrfs), creates password files, runs nixos-install.
set -euo pipefail

FLAKE_DIR="/etc/nixos"
LUKS_KEY_PATH="/tmp/disko-luks-passphrase"

# --- Colors ---
RED='\033[0;31m'
GREEN='\033[0;32m'
BOLD='\033[1m'
NC='\033[0m'

ok()    { echo -e "${GREEN}[OK]${NC} $*"; }
err()   { echo -e "${RED}[ERROR]${NC} $*" >&2; }
header() { echo -e "\n${BOLD}=== $* ===${NC}\n"; }

# Cleanup on exit (always wipe LUKS key from tmpfs)
cleanup() {
  if [ -f "$LUKS_KEY_PATH" ]; then
    shred -u "$LUKS_KEY_PATH" 2>/dev/null || rm -f "$LUKS_KEY_PATH"
  fi
}
trap cleanup EXIT

# Must run as root
if [ "$(id -u)" -ne 0 ]; then
  err "This script must be run as root."
  exit 1
fi

# --- 1. Select hostname ---
header "Select host to install"
echo "Available hosts:"
echo "  1) gary   (desktop — AMD, UEFI, SSD)"
echo "  2) zola   (laptop — Intel+NVIDIA, UEFI, SSD)"
echo "  3) kafka  (server — AMD, BIOS/GRUB, HDD)"
echo ""
read -rp "Choice [1-3]: " host_choice

case "$host_choice" in
  1) TARGET_HOST="gary" ;;
  2) TARGET_HOST="zola" ;;
  3) TARGET_HOST="kafka" ;;
  *) err "Invalid choice"; exit 1 ;;
esac
ok "Installing: $TARGET_HOST"

# --- 2. Select target disk ---
header "Select target disk"
echo "Available disks:"
lsblk -d -o NAME,SIZE,MODEL,TRAN
echo ""
read -rp "Disk to use (e.g. nvme0n1, sda): " disk_name
DISK="/dev/$disk_name"

if [ ! -b "$DISK" ]; then
  err "$DISK is not a valid block device"
  exit 1
fi

echo ""
echo -e "${RED}${BOLD}WARNING: ALL DATA ON $DISK WILL BE DESTROYED${NC}"
read -rp "Type 'yes' to confirm: " confirm
if [ "$confirm" != "yes" ]; then
  err "Aborted."
  exit 1
fi

# --- 3. LUKS passphrase ---
header "Set LUKS encryption passphrase"
while true; do
  read -srp "LUKS passphrase: " luks_pass; echo
  read -srp "Confirm passphrase: " luks_pass2; echo
  if [ "$luks_pass" = "$luks_pass2" ] && [ -n "$luks_pass" ]; then
    break
  fi
  err "Passphrases don't match or are empty. Try again."
done

# --- 4. User passwords ---
header "Set user passwords"

echo "Password for root:"
while true; do
  read -srp "  Password: " root_pass; echo
  read -srp "  Confirm:  " root_pass2; echo
  if [ "$root_pass" = "$root_pass2" ] && [ -n "$root_pass" ]; then break; fi
  err "Passwords don't match or are empty."
done

echo "Password for aristide:"
while true; do
  read -srp "  Password: " user_pass; echo
  read -srp "  Confirm:  " user_pass2; echo
  if [ "$user_pass" = "$user_pass2" ] && [ -n "$user_pass" ]; then break; fi
  err "Passwords don't match or are empty."
done

# --- 5. Write LUKS passphrase to tmpfs file (referenced by disko.nix configs) ---
# /tmp is tmpfs in the live ISO, so the key never touches persistent storage.
# Cleaned up on script exit via trap.
umask 077
printf '%s' "$luks_pass" > "$LUKS_KEY_PATH"

# --- 6. Partition and format with disko ---
# --disk <name> <device> overrides disko.devices.disk.<name>.device, so the
# disko config can declare a default device that's ignored at install time.
header "Partitioning $DISK with disko"
disko --mode disko \
  --flake "$FLAKE_DIR#$TARGET_HOST" \
  --disk main "$DISK"
ok "Disk partitioned and mounted at /mnt"

# --- 7. Create password files ---
header "Creating password files"
mkdir -p /mnt/etc
chmod 755 /mnt/etc

printf '%s' "$root_pass" | mkpasswd -m sha-512 -s > /mnt/etc/passwd-root
printf '%s' "$user_pass" | mkpasswd -m sha-512 -s > /mnt/etc/passwd-aristide
chmod 400 /mnt/etc/passwd-root /mnt/etc/passwd-aristide
ok "Password files created in /mnt/etc/"

# --- 8. Copy flake to target ---
header "Installing flake to target"
mkdir -p /mnt/etc/nixos
cp -aT "$FLAKE_DIR" /mnt/etc/nixos
# /etc/nixos in the live ISO was readonly (Nix store); restore write perms on target
chown -R root:root /mnt/etc/nixos
chmod -R u+w /mnt/etc/nixos
ok "Flake copied to /mnt/etc/nixos"

# --- 9. Run nixos-install ---
# --no-root-passwd: we use hashedPasswordFile, no interactive prompt
header "Running nixos-install"
nixos-install \
  --flake "/mnt/etc/nixos#$TARGET_HOST" \
  --no-root-passwd

# --- Done ---
header "Installation complete!"
echo -e "${GREEN}${BOLD}$TARGET_HOST has been installed on $DISK${NC}"
echo ""
echo "Next steps:"
echo "  1. Remove the USB key"
echo "  2. Reboot into the new system"
echo "  3. LUKS passphrase will be asked at boot"
echo ""
read -rp "Press Enter to reboot (or Ctrl+C to stay)..."
reboot
