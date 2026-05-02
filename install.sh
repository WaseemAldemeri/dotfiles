#!/usr/bin/env bash
# Bootstrap a fresh Pop!_OS COSMIC machine from this dotfiles repo.
# Fully automatic. Re-runnable. Run with: ./install.sh
#
# What it does, in order:
#   1. apt prerequisites (curl, git, stow, rsync, gpg, ca-certificates)
#   2. Install vendor signing keys (Docker, Cloudflare, Chrome)
#   3. Copy our /etc/apt/sources.list.d/ snapshot
#   4. apt update + install all packages from packages/apt-manual.txt
#   5. flatpak setup + install apps from packages/flatpak.txt
#   6. Install Oh-My-Zsh + zsh-autosuggestions + zsh-syntax-highlighting
#   7. Install TPM (Tmux Plugin Manager)
#   8. Install starship prompt (official installer)
#   9. Runtimes: fnm + Node + npm globals, fvm + Flutter, Deno, Claude Code
#  10. Pre-stow cleanup: backup + remove conflicting target files
#  11. Run ./stow.sh to symlink configs into $HOME
#  12. Restore ~/.config/cosmic/ from cosmic-config/ (no --delete; merges)
#  13. Load dconf snapshot
#  14. chsh to zsh
set -euo pipefail

DOTFILES="$(dirname "$(readlink -f "$0")")"
cd "$DOTFILES"

log() { printf '\n\033[1;34m▸ %s\033[0m\n' "$*"; }
warn() { printf '\033[1;33m! %s\033[0m\n' "$*"; }

# ─── 1. Prerequisites ─────────────────────────────────────────────────────────
log "1/14  Installing prerequisites"
sudo apt update
sudo apt install -y curl wget git stow rsync gpg ca-certificates apt-transport-https

# ─── 2. Vendor signing keys ───────────────────────────────────────────────────
log "2/14  Installing apt signing keys (Docker, Cloudflare, Chrome)"
sudo install -m 0755 -d /etc/apt/keyrings
sudo install -m 0755 -d /usr/share/keyrings

# Docker
if [[ ! -f /etc/apt/keyrings/docker.asc ]]; then
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo tee /etc/apt/keyrings/docker.asc >/dev/null
  sudo chmod a+r /etc/apt/keyrings/docker.asc
fi

# Cloudflare
if [[ ! -f /usr/share/keyrings/cloudflare-main.gpg ]]; then
  curl -fsSL https://pkg.cloudflare.com/cloudflare-main.gpg | sudo tee /usr/share/keyrings/cloudflare-main.gpg >/dev/null
fi

# Google Chrome — install the .deb directly; it sets up its own key & source
if ! dpkg -s google-chrome-stable >/dev/null 2>&1; then
  TMPDEB=$(mktemp --suffix=.deb)
  curl -fsSL -o "$TMPDEB" https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
  sudo apt install -y "$TMPDEB"
  rm -f "$TMPDEB"
fi

# ─── 3. Apt sources ───────────────────────────────────────────────────────────
log "3/14  Restoring /etc/apt/sources.list.d/"
sudo rsync -a packages/apt-sources/ /etc/apt/sources.list.d/

# ─── 4. APT packages ──────────────────────────────────────────────────────────
log "4/14  apt update + install (apt-manual.txt — already-installed are no-ops)"
sudo apt update
xargs -a packages/apt-manual.txt sudo apt install -y || warn "Some apt packages failed (likely missing on this release) — continuing"

# ─── 5. Flatpak ───────────────────────────────────────────────────────────────
log "5/14  Flatpak setup + apps"
if ! command -v flatpak >/dev/null; then sudo apt install -y flatpak; fi
flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo || true
# packages/flatpak.txt is "appid<TAB>origin" per line
while IFS=$'\t' read -r appid origin; do
  [[ -z "$appid" || "$appid" == "(flatpak"* ]] && continue
  flatpak install -y --noninteractive "${origin:-flathub}" "$appid" || warn "flatpak install failed: $appid"
done < packages/flatpak.txt

# ─── 6. Oh-My-Zsh + plugins ───────────────────────────────────────────────────
log "6/14  Oh-My-Zsh + plugins"
if [[ ! -d "$HOME/.oh-my-zsh" ]]; then
  RUNZSH=no CHSH=no sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
fi
ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"
[[ -d "$ZSH_CUSTOM/plugins/zsh-autosuggestions" ]]     || git clone --depth 1 https://github.com/zsh-users/zsh-autosuggestions     "$ZSH_CUSTOM/plugins/zsh-autosuggestions"
[[ -d "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" ]] || git clone --depth 1 https://github.com/zsh-users/zsh-syntax-highlighting "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting"

# ─── 7. TPM (Tmux Plugin Manager) ─────────────────────────────────────────────
log "7/14  Tmux Plugin Manager"
TPM_DIR="$HOME/.config/tmux/plugins/tpm"
mkdir -p "$(dirname "$TPM_DIR")"
[[ -d "$TPM_DIR" ]] || git clone --depth 1 https://github.com/tmux-plugins/tpm "$TPM_DIR"

# ─── 8. Starship ──────────────────────────────────────────────────────────────
log "8/14  Starship prompt"
if ! command -v starship >/dev/null; then
  curl -fsSL https://starship.rs/install.sh | sh -s -- --yes
fi

# ─── 9. Runtimes: fnm/Node/npm + fvm/Flutter + Deno + Claude Code ─────────────
log "9/14  Runtimes (fnm, fvm, deno, claude)"

# Make sure $HOME/.local/bin is on PATH for tools we install below
mkdir -p "$HOME/.local/bin"
export PATH="$HOME/.local/bin:$PATH"

# fnm — Node version manager
if ! command -v fnm >/dev/null; then
  curl -fsSL https://fnm.vercel.app/install | bash -s -- --skip-shell
fi
export PATH="$HOME/.local/share/fnm:$PATH"
eval "$(fnm env --shell=bash)" || warn "fnm env failed"

# Node versions from packages/fnm-versions.txt
if [[ -s packages/fnm-versions.txt ]]; then
  while read -r v; do
    [[ -z "$v" ]] && continue
    fnm install "$v" || warn "fnm install $v failed"
  done < packages/fnm-versions.txt
  fnm default "$(tail -n1 packages/fnm-versions.txt)" 2>/dev/null || true
fi

# npm globals from packages/npm-globals.txt
if [[ -s packages/npm-globals.txt ]] && command -v npm >/dev/null; then
  while read -r pkg; do
    [[ -z "$pkg" ]] && continue
    npm install -g "$pkg" || warn "npm install -g $pkg failed"
  done < packages/npm-globals.txt
fi

# Deno
if ! command -v deno >/dev/null; then
  curl -fsSL https://deno.land/install.sh | sh -s -- -y || warn "deno install failed"
fi

# fvm — Flutter version manager (installer uses sudo to write /usr/local/bin)
if ! command -v fvm >/dev/null; then
  curl -fsSL https://fvm.app/install.sh | bash || warn "fvm install failed"
fi

# Flutter versions from packages/fvm-versions.txt
if [[ -s packages/fvm-versions.txt ]] && command -v fvm >/dev/null; then
  while read -r v; do
    [[ -z "$v" ]] && continue
    fvm install "$v" || warn "fvm install $v failed"
  done < packages/fvm-versions.txt
fi

# Claude Code (Anthropic official installer → ~/.local/bin/claude)
if ! command -v claude >/dev/null; then
  curl -fsSL https://claude.ai/install.sh | bash || warn "claude install failed"
fi

# ─── 10. Pre-stow cleanup: back up + remove conflicting targets ───────────────
log "10/14 Pre-stow cleanup (back up any pre-existing target files)"
STOW_TARGETS=(
  "$HOME/.zshrc"
  "$HOME/.bashrc"
  "$HOME/.profile"
  "$HOME/.gitconfig"
  "$HOME/.config/git/hooks/prepare-commit-msg"
  "$HOME/.config/git/ignore"
  "$HOME/.config/nvim"
  "$HOME/.config/zed"
  "$HOME/.config/alacritty/alacritty.toml"
  "$HOME/.config/tmux/tmux.conf"
  "$HOME/.config/tmux/scripts/sessionizer"
  "$HOME/.config/tmux/projects"
  "$HOME/.config/btop/btop.conf"
  "$HOME/.config/neofetch/config.conf"
  "$HOME/.config/starship.toml"
  "$HOME/.local/bin/start-work"
  "$HOME/.claude/CLAUDE.md"
  "$HOME/.claude/RTK.md"
  "$HOME/.claude/settings.json"
  "$HOME/.claude/keybindings.json"
  "$HOME/.claude/skills/brag-doc-generator"
  "$HOME/.claude/skills/branch-context"
  "$HOME/.claude/skills/draft-pr"
  "$HOME/.claude/skills/sprint-update"
  "$HOME/.claude/skills/suggest-commit"
  "$HOME/.claude/plugins/installed_plugins.json"
  "$HOME/.claude/plugins/known_marketplaces.json"
  "$HOME/.claude/plugins/blocklist.json"
)
BACKUP="$HOME/.config-backup-$(date +%Y%m%d-%H%M%S)"
moved=0
for t in "${STOW_TARGETS[@]}"; do
  # skip if missing or already a symlink (re-runs / already stowed)
  [[ -e "$t" || -L "$t" ]] || continue
  [[ -L "$t" ]] && continue
  rel="${t#$HOME/}"
  mkdir -p "$BACKUP/$(dirname "$rel")"
  mv "$t" "$BACKUP/$rel"
  echo "  backed up: $rel"
  moved=$((moved + 1))
done
if (( moved > 0 )); then
  echo "  $moved file(s) moved to: $BACKUP"
else
  echo "  no conflicts — nothing to back up"
  rmdir "$BACKUP" 2>/dev/null || true
fi

# ─── 11. Stow configs into $HOME ──────────────────────────────────────────────
log "11/14 Stowing configs"
"$DOTFILES/stow.sh"

# ─── 12. Restore COSMIC config (merge, do not delete) ─────────────────────────
log "12/14 Restoring ~/.config/cosmic/ from snapshot"
mkdir -p "$HOME/.config/cosmic"
rsync -a cosmic-config/ "$HOME/.config/cosmic/"

# ─── 13. dconf snapshot ───────────────────────────────────────────────────────
log "13/14 Loading dconf snapshot"
if [[ -s dconf/dconf.dump ]]; then
  dconf load / < dconf/dconf.dump || warn "dconf load failed (non-fatal)"
fi

# ─── 14. Default shell → zsh ──────────────────────────────────────────────────
log "14/14 Setting default shell to zsh"
if [[ "$SHELL" != *zsh ]]; then
  ZSH_BIN="$(command -v zsh)"
  if grep -qx "$ZSH_BIN" /etc/shells; then
    sudo chsh -s "$ZSH_BIN" "$USER"
  else
    warn "$ZSH_BIN not in /etc/shells — skipping chsh"
  fi
fi

log "✓ Bootstrap complete."
cat <<'EOF'

Next steps (manual):
  • Open a new terminal so zsh loads
  • Inside tmux, run:  prefix + I   (capital I) to install TPM plugins
  • Log out/in (or restart cosmic-comp) so COSMIC picks up restored settings
  • Verify: nvim, zed, alacritty all open with their configs
EOF
