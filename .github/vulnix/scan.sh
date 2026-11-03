#!/usr/bin/env bash
# Scan vulnix (CVE connues, base NVD) des systèmes NixOS du flake, sans rien
# construire : on évalue la dérivation de chaque hôte et vulnix parcourt sa
# clôture de dérivations. Construire les systèmes en CI serait trop lourd
# (Blender CUDA de bernanos : plusieurs heures).
#
# Contrepartie : la clôture de dérivations inclut les outils de build (bootstrap
# Go, Python 2.7, paquets Haskell/Rust homonymes de « curl », « zlib »…), donc
# plus de faux positifs qu'un scan de la clôture runtime sur la machine.
# Mesuré le 2026-11-03 : bernanos 118 paquets (dérivations) contre 41 (runtime).
# Les alertes vérifiées vont dans ./whitelist.toml.
#
# Usage : scan.sh [hôte…]   (défaut : tous les nixosConfigurations)
# Variables :
#   VULNIX_CACHE    cache NVD (défaut ~/.cache/vulnix, ~400 Mo)
#   OUT             dossier des rapports (défaut ./vulnix-out)
#   FAIL_ON_CVSS    code de sortie 1 si un paquet non whitelisté atteint ce
#                   score (défaut 9 ; 11 = ne jamais échouer)
# Sorties : $OUT/<hôte>.json (rapport vulnix), $OUT/summary.md (Markdown).
set -euo pipefail

here=$(cd "$(dirname "$0")" && pwd)
flake=$(cd "$here/../.." && pwd)
cache=${VULNIX_CACHE:-$HOME/.cache/vulnix}
out=${OUT:-$PWD/vulnix-out}
fail_on=${FAIL_ON_CVSS:-9}
mkdir -p "$out"

if [ $# -gt 0 ]; then
  hosts=("$@")
else
  mapfile -t hosts < <(nix eval --raw "$flake#nixosConfigurations" \
    --apply 'c: builtins.concatStringsSep "\n" (builtins.attrNames c)')
fi

# vulnix du nixpkgs du flake (même version que sur les machines).
vulnix=$(nix build --no-link --print-out-paths \
  "$flake#nixosConfigurations.${hosts[0]}.pkgs.vulnix^out")/bin/vulnix

worst=0
{
  echo "# vulnix — $(date -u '+%F %R') UTC"
  echo
  echo "Seuil d'échec : CVSS ≥ $fail_on (hors whitelist)."
  echo
} > "$out/summary.md"

for host in "${hosts[@]}"; do
  echo "== $host" >&2
  drv=$(nix eval --raw "$flake#nixosConfigurations.$host.config.system.build.toplevel.drvPath")

  # 0 = rien, 2 = vulnérabilités trouvées, autre = erreur.
  rc=0
  "$vulnix" --json --cache-dir "$cache" --whitelist "$here/whitelist.toml" \
    "$drv" > "$out/$host.json" || rc=$?
  if [ "$rc" -ne 0 ] && [ "$rc" -ne 2 ]; then
    echo "vulnix a échoué sur $host (code $rc)" >&2
    exit "$rc"
  fi

  jq -r --arg host "$host" '
    [.[] | select((.affected_by | length) > 0)
      | . as $e
      | {name, score: ([.affected_by[] | $e.cvssv3_basescore[.] // 0] | max // 0), cves: .affected_by}] as $p
    | ($p | map(select(.score >= 9))) as $crit
    | ($p | map(select(.score >= 7 and .score < 9))) as $high
    | "## \($host)",
      "",
      "\($p | length) paquets touchés, \([$p[] | .cves[]] | length) CVE — critiques (≥ 9) : \($crit | length), hautes (7-9) : \($high | length)",
      "",
      (if ($crit + $high | length) > 0 then
        "<details><summary>Détail (CVSS ≥ 7)</summary>\n\n| CVSS | Paquet | CVE |\n|---|---|---|",
        ($crit + $high | sort_by(-.score)[]
          | "| \(.score) | `\(.name)` | \(.cves[:5] | join(" "))\(
              if (.cves | length) > 5 then " … (+\((.cves | length) - 5))" else "" end) |"),
        "\n</details>\n"
      else empty end)
  ' "$out/$host.json" >> "$out/summary.md"

  host_worst=$(jq '[.[] | . as $e | .affected_by[] | $e.cvssv3_basescore[.] // 0] | max // 0' "$out/$host.json")
  worst=$(jq -n "[$worst, $host_worst] | max")
done

cat "$out/summary.md"
if jq -e -n "$worst >= $fail_on" > /dev/null; then
  echo "Échec : au moins un paquet atteint CVSS $worst (seuil $fail_on)." >&2
  exit 1
fi
