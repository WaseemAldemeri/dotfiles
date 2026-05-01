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

echo "done. review with: git status && git diff"
