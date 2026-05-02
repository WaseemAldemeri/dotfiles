#!/usr/bin/env bash
# Snapshot system state into the dotfiles repo.
# Idempotent: re-running refreshes snapshots in place.
# After running, use `git diff` / `git status` to review changes, then commit.
set -euo pipefail

cd "$(dirname "$(readlink -f "$0")")"

mkdir -p packages packages/apt-sources dconf cosmic-config

echo "→ apt: manually installed packages"
apt-mark showmanual | sort > packages/apt-manual.txt

echo "→ apt: source lists"
# rsync mirrors current state of sources.list.d/, deleting stale entries
rsync -a --delete /etc/apt/sources.list.d/ packages/apt-sources/

echo "→ flatpak: installed apps"
if command -v flatpak >/dev/null 2>&1; then
  flatpak list --app --columns=application,origin > packages/flatpak.txt
else
  echo "(flatpak not installed)" > packages/flatpak.txt
fi

echo "→ dconf: GTK / leftover GNOME settings"
dconf dump / > dconf/dconf.dump

echo "→ cosmic: desktop environment config"
rsync -a --delete "$HOME/.config/cosmic/" cosmic-config/

echo "→ runtimes: fnm Node versions"
if command -v fnm >/dev/null 2>&1; then
  fnm list 2>/dev/null | awk '{print $2}' | grep '^v' | sort -u > packages/fnm-versions.txt
else
  : > packages/fnm-versions.txt
fi

echo "→ runtimes: fvm Flutter versions"
if command -v fvm >/dev/null 2>&1; then
  fvm api list 2>/dev/null \
    | python3 -c 'import json,sys; print("\n".join(v["name"] for v in json.load(sys.stdin).get("versions",[])))' \
    > packages/fvm-versions.txt
else
  : > packages/fvm-versions.txt
fi

echo "→ runtimes: npm globals"
if command -v npm >/dev/null 2>&1; then
  npm ls -g --depth=0 --json 2>/dev/null \
    | python3 -c 'import json,sys; deps=json.load(sys.stdin).get("dependencies",{}); print("\n".join(k for k in sorted(deps) if k not in ("npm","corepack")))' \
    > packages/npm-globals.txt
else
  : > packages/npm-globals.txt
fi

echo "done. review with: git status && git diff"
