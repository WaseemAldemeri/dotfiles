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
#   9. Run ./stow.sh to symlink configs into $HOME
#  10. Restore ~/.config/cosmic/ from cosmic-config/ (no --delete; merges)
#  11. Load dconf snapshot
#  12. chsh to zsh
set -euo pipefail

DOTFILES="$(dirname "$(readlink -f "$0")")"
cd "$DOTFILES"

log() { printf '\n\033[1;34m▸ %s\033[0m\n' "$*"; }
warn() { printf '\033[1;33m! %s\033[0m\n' "$*"; }

# ─── 1. Prerequisites ─────────────────────────────────────────────────────────
log "1/12  Installing prerequisites"
sudo apt update
sudo apt install -y curl wget git stow rsync gpg ca-certificates apt-transport-https

# ─── 2. Vendor signing keys ───────────────────────────────────────────────────
log "2/12  Installing apt signing keys (Docker, Cloudflare, Chrome)"
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
log "3/12  Restoring /etc/apt/sources.list.d/"
sudo rsync -a packages/apt-sources/ /etc/apt/sources.list.d/

# ─── 4. APT packages ──────────────────────────────────────────────────────────
log "4/12  apt update + install (apt-manual.txt — already-installed are no-ops)"
sudo apt update
xargs -a packages/apt-manual.txt sudo apt install -y || warn "Some apt packages failed (likely missing on this release) — continuing"

# ─── 5. Flatpak ───────────────────────────────────────────────────────────────
log "5/12  Flatpak setup + apps"
if ! command -v flatpak >/dev/null; then sudo apt install -y flatpak; fi
flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo || true
# packages/flatpak.txt is "appid<TAB>origin" per line
while IFS=$'\t' read -r appid origin; do
  [[ -z "$appid" || "$appid" == "(flatpak"* ]] && continue
  flatpak install -y --noninteractive "${origin:-flathub}" "$appid" || warn "flatpak install failed: $appid"
done < packages/flatpak.txt

# ─── 6. Oh-My-Zsh + plugins ───────────────────────────────────────────────────
log "6/12  Oh-My-Zsh + plugins"
if [[ ! -d "$HOME/.oh-my-zsh" ]]; then
  RUNZSH=no CHSH=no sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
fi
ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"
[[ -d "$ZSH_CUSTOM/plugins/zsh-autosuggestions" ]]     || git clone --depth 1 https://github.com/zsh-users/zsh-autosuggestions     "$ZSH_CUSTOM/plugins/zsh-autosuggestions"
[[ -d "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" ]] || git clone --depth 1 https://github.com/zsh-users/zsh-syntax-highlighting "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting"

# ─── 7. TPM (Tmux Plugin Manager) ─────────────────────────────────────────────
log "7/12  Tmux Plugin Manager"
TPM_DIR="$HOME/.config/tmux/plugins/tpm"
mkdir -p "$(dirname "$TPM_DIR")"
[[ -d "$TPM_DIR" ]] || git clone --depth 1 https://github.com/tmux-plugins/tpm "$TPM_DIR"

# ─── 8. Starship ──────────────────────────────────────────────────────────────
log "8/12  Starship prompt"
if ! command -v starship >/dev/null; then
  curl -fsSL https://starship.rs/install.sh | sh -s -- --yes
fi

# ─── 9. Stow configs into $HOME ───────────────────────────────────────────────
log "9/12  Stowing configs"
"$DOTFILES/stow.sh"

# ─── 10. Restore COSMIC config (merge, do not delete) ─────────────────────────
log "10/12 Restoring ~/.config/cosmic/ from snapshot"
mkdir -p "$HOME/.config/cosmic"
rsync -a cosmic-config/ "$HOME/.config/cosmic/"

# ─── 11. dconf snapshot ───────────────────────────────────────────────────────
log "11/12 Loading dconf snapshot"
if [[ -s dconf/dconf.dump ]]; then
  dconf load / < dconf/dconf.dump || warn "dconf load failed (non-fatal)"
fi

# ─── 12. Default shell → zsh ──────────────────────────────────────────────────
log "12/12 Setting default shell to zsh"
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
