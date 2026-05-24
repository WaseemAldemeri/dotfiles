#!/usr/bin/env bash
# Idempotent: re-stow every package. Safe to run multiple times.
# Uses `stow -R` (restow) which unstows then stows, repairing drift.
set -euo pipefail

cd "$(dirname "$(readlink -f "$0")")"

PACKAGES=(
  shell
  git
  nvim
  zed
  alacritty
  tmux
  btop
  neofetch
  starship
  scripts
  systemd
  claude
)

for pkg in "${PACKAGES[@]}"; do
  if [[ ! -d "$pkg" ]]; then
    echo "skip: $pkg (no such package)"
    continue
  fi
  echo "stow: $pkg"
  stow -R -v -t "$HOME" "$pkg"
done

echo "done."
