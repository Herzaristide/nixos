#!/usr/bin/env bash
# Clone this flake into /etc/nixos, regenerate hardware-configuration.nix for this
# machine, fix ownership, then nixos-rebuild switch.
#
# Usage:
#   sudo install-nixos <git-url> <flake-hostname>
#   nix run github:YOU/nixos#install-nixos -- git@github.com:YOU/nixos.git zola
#
# The flake-hostname must match hosts/<name>/ in the repo (e.g. zola, kafka).
#
# Env:
#   REPLACE_SKIP_REBUILD=1  — clone + hardware + chown only, no rebuild
#   REPLACE_BRANCH=main     — optional; default = remote default branch
set -euo pipefail

if [[ "$(id -u)" -ne 0 ]]; then
  exec sudo -E env \
    "PATH=$PATH" \
    "REPLACE_CALLER_UID=$(id -u)" \
    "REPLACE_CALLER_GID=$(id -g)" \
    "${BASH_SOURCE[0]}" "$@"
fi

OWNER_UID="${SUDO_UID:-${REPLACE_CALLER_UID:-}}"
OWNER_GID="${SUDO_GID:-${REPLACE_CALLER_GID:-}}"
if [[ -n "$OWNER_UID" && -z "$OWNER_GID" ]]; then
  OWNER_GID="$OWNER_UID"
fi

REPO="${1:-}"
HOST="${2:-}"
if [[ -z "$REPO" || -z "$HOST" ]]; then
  echo "usage: install-nixos <git-url> <flake-hostname>" >&2
  echo "  example: install-nixos git@github.com:you/nixos.git kafka" >&2
  echo "  flake-hostname = directory under hosts/ and nixosConfigurations name" >&2
  exit 1
fi

if ! command -v git >/dev/null 2>&1; then
  echo "error: git not in PATH" >&2
  exit 1
fi

if ! command -v nixos-generate-config >/dev/null 2>&1; then
  echo "error: nixos-generate-config not in PATH (are you on NixOS?)" >&2
  exit 1
fi

STAMP="$(date -u +%Y%m%dT%H%M%SZ)"
BACKUP=""
if [[ -e /etc/nixos ]]; then
  BACKUP="/etc/nixos.bak.$STAMP"
  mv /etc/nixos "$BACKUP"
  echo "Backed up: /etc/nixos -> $BACKUP"
fi

if [[ -n "${REPLACE_BRANCH:-}" ]]; then
  git clone --depth 1 -b "$REPLACE_BRANCH" "$REPO" /etc/nixos
else
  git clone --depth 1 "$REPO" /etc/nixos
fi

if [[ ! -f /etc/nixos/flake.nix ]]; then
  echo "error: clone succeeded but /etc/nixos/flake.nix is missing" >&2
  exit 1
fi

HOST_DIR="/etc/nixos/hosts/$HOST"
HW_FILE="$HOST_DIR/hardware-configuration.nix"
if [[ ! -d "$HOST_DIR" ]]; then
  echo "error: no hosts/$HOST in repo — create hosts/$HOST/ or fix flake-hostname" >&2
  exit 1
fi

tmp="$(mktemp)"
nixos-generate-config --show-hardware-config >"$tmp"
mv "$tmp" "$HW_FILE"
echo "Generated: $HW_FILE"

if [[ -n "$OWNER_UID" ]]; then
  chown -R "$OWNER_UID:$OWNER_GID" /etc/nixos
  [[ -n "$BACKUP" ]] && chown -R "$OWNER_UID:$OWNER_GID" "$BACKUP"
  echo "Ownership: $OWNER_UID:$OWNER_GID on /etc/nixos${BACKUP:+ and $BACKUP}"
fi

if [[ "${REPLACE_SKIP_REBUILD:-}" == 1 ]]; then
  echo "Skipped rebuild. Run: nixos-rebuild switch --flake /etc/nixos#$HOST"
  exit 0
fi

exec nixos-rebuild switch --flake "/etc/nixos#$HOST"
