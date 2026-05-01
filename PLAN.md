# Dotfiles Management Plan

## Current System State

### Found Configurations
| Tool | Location | Notes |
|------|----------|-------|
| **nvim** | `~/.config/nvim/` | LazyVim setup with lua configs |
| **zed** | `~/.config/zed/` | settings.json, keymap.json, tasks.json |
| **alacritty** | `~/.config/alacritty/` | alacritty.toml |
| **tmux** | `~/.tmux.conf` + `~/.tmux/` | Custom config + scripts + plugins |
| **zsh** | `~/.zshrc` | Uses oh-my-zsh |
| **oh-my-zsh** | `~/.oh-my-zsh/` | Custom plugins in `custom/plugins/` |
| **starship** | `~/.config/starship.toml` | Prompt config |
| **git** | `~/.gitconfig` + `~/.config/git/` | Core settings + hooks |
| **btop** | `~/.config/btop/` | System monitor |
| **neofetch** | `~/.config/neofetch/` | System info display |

### Oh-My-Zsh Plugins (Custom)
- zsh-autosuggestions
- zsh-syntax-highlighting

### ZSH Plugins (from .zshrc)
- git
- vi-mode
- fzf
- zsh-autosuggestions
- zsh-syntax-highlighting

---

## Proposed Stow Structure

GNU Stow creates symlinks from `~` to files in the dotfiles repo. The structure mirrors the target location:

```
dotfiles/
├── README.md
├── PLAN.md
├── install.sh              # Main restore script
├── backup.sh               # Script to dump configs/packages
├── packages/               # Package lists
│   ├── apt-packages.txt
│   ├── apt-repositories.txt
│   └── flatpak-packages.txt
├── dconf/                  # Pop!_OS settings dump
│   └── popos-settings.dconf
├── nvim/                   # → stow nvim
│   └── .config/
│       └── nvim/
├── zed/                    # → stow zed
│   └── .config/
│       └── zed/
├── alacritty/              # → stow alacritty
│   └── .config/
│       └── alacritty/
├── tmux/                   # → stow tmux
│   └── .config/
│       └── tmux/
│           └── tmux.conf   # renamed from ~/.tmux.conf
├── zsh/                    # → stow zsh
│   ├── .zshrc
│   └── .config/
│       └── zsh/            # custom configs
├── oh-my-zsh/              # → stow oh-my-zsh
│   └── .oh-my-zsh/
│       └── custom/
│           └── plugins/
├── starship/               # → stow starship
│   └── .config/
│       └── starship.toml
├── git/                    # → stow git
│   ├── .gitconfig
│   └── .config/
│       └── git/
│           └── hooks/
├── btop/                   # → stow btop
│   └── .config/
│       └── btop/
└── neofetch/               # → stow neofetch
    └── .config/
        └── neofetch/
```

---

## Migration Strategy

### Phase 1: Create Directory Structure
```bash
cd ~/Work/Test/dotfiles
mkdir -p nvim/.config/nvim
mkdir -p zed/.config/zed
mkdir -p alacritty/.config/alacritty
mkdir -p tmux/.config/tmux
mkdir -p zsh/.config/zsh
mkdir -p oh-my-zsh/.oh-my-zsh/custom/plugins
mkdir -p starship/.config
mkdir -p git/.config/git/hooks
mkdir -p btop/.config/btop
mkdir -p neofetch/.config/neofetch
mkdir -p packages
mkdir -p dconf
```

### Phase 2: Copy Configurations

**NVim:**
```bash
cp -r ~/.config/nvim/* ~/Work/Test/dotfiles/nvim/.config/nvim/
```

**Zed:**
```bash
cp -r ~/.config/zed/* ~/Work/Test/dotfiles/zed/.config/zed/
```

**Alacritty:**
```bash
cp ~/.config/alacritty/alacritty.toml ~/Work/Test/dotfiles/alacritty/.config/alacritty/
```

**Tmux (Migration to XDG config):**
```bash
# Move from ~/.tmux.conf to ~/.config/tmux/tmux.conf
cp ~/.tmux.conf ~/Work/Test/dotfiles/tmux/.config/tmux/tmux.conf
cp -r ~/.tmux/scripts ~/Work/Test/dotfiles/tmux/.config/tmux/
# Note: plugins/ managed by TPM, don't backup
```

**Zsh:**
```bash
cp ~/.zshrc ~/Work/Test/dotfiles/zsh/
# Any additional custom zsh configs
cp -r ~/.config/zsh/* ~/Work/Test/dotfiles/zsh/.config/zsh/ 2>/dev/null || true
```

**Oh-My-Zsh (Custom only):**
```bash
cp -r ~/.oh-my-zsh/custom/plugins/* ~/Work/Test/dotfiles/oh-my-zsh/.oh-my-zsh/custom/plugins/
# Note: We don't backup the entire oh-my-zsh, just custom plugins
```

**Starship:**
```bash
cp ~/.config/starship.toml ~/Work/Test/dotfiles/starship/.config/
```

**Git:**
```bash
cp ~/.gitconfig ~/Work/Test/dotfiles/git/
cp -r ~/.config/git/hooks/* ~/Work/Test/dotfiles/git/.config/git/hooks/ 2>/dev/null || true
```

**Btop:**
```bash
cp -r ~/.config/btop/* ~/Work/Test/dotfiles/btop/.config/btop/
```

**Neofetch:**
```bash
cp -r ~/.config/neofetch/* ~/Work/Test/dotfiles/neofetch/.config/neofetch/
```

### Phase 3: Dump System Settings

**Pop!_OS dconf settings:**
```bash
dconf dump / > ~/Work/Test/dotfiles/dconf/popos-settings.dconf
```

**Package lists:**
```bash
# APT packages (manually installed)
apt list --installed 2>/dev/null | grep -v "automatic" > ~/Work/Test/dotfiles/packages/apt-packages.txt

# APT repositories
ls -1 /etc/apt/sources.list.d/ > ~/Work/Test/dotfiles/packages/apt-repositories.txt
cat /etc/apt/sources.list >> ~/Work/Test/dotfiles/packages/apt-repositories.txt

# Flatpak packages
flatpak list --app --columns=application,origin > ~/Work/Test/dotfiles/packages/flatpak-packages.txt
```

### Phase 4: Test Stow (Dry Run)
```bash
cd ~/Work/Test/dotfiles
# Backup existing configs first
mkdir -p ~/.config-backup-$(date +%Y%m%d)
cp -r ~/.config/nvim ~/.config-backup-$(date +%Y%m%d)/
cp -r ~/.config/zed ~/.config-backup-$(date +%Y%m%d)/
# ... etc

# Test stow (shows what it would do)
stow -n -v nvim
stow -n -v zed
stow -n -v alacritty
stow -n -v tmux
stow -n -v zsh
stow -n -v starship
stow -n -v git
stow -n -v btop
stow -n -v neofetch
```

### Phase 5: Apply Stow
```bash
cd ~/Work/Test/dotfiles

# Remove original configs (they're backed up)
rm -rf ~/.config/nvim
rm -rf ~/.config/zed
rm -rf ~/.config/alacritty
rm -rf ~/.tmux.conf
rm -rf ~/.tmux
rm ~/.zshrc
rm ~/.gitconfig
rm ~/.config/starship.toml

# Apply stow
stow nvim
stow zed
stow alacritty
stow tmux
stow zsh
stow starship
stow git
stow btop
stow neofetch
```

---

## Tmux XDG Migration Notes

Tmux supports XDG Base Directory spec. We need to:
1. Move `~/.tmux.conf` → `~/.config/tmux/tmux.conf`
2. Move `~/.tmux/` → `~/.config/tmux/`
3. Update any hardcoded paths in scripts

The config file can detect its location:
```bash
# In tmux.conf
# Use XDG_CONFIG_HOME if set, else ~/.config
TMUX_CONFIG="${XDG_CONFIG_HOME:-$HOME/.config}/tmux"
source-file "$TMUX_CONFIG/extra.conf"
```

---

## Restore Script Features (`install.sh`)

The restore script on a new machine will:

1. **Check prerequisites:**
   - git
   - stow
   - curl/wget

2. **Install package managers:**
   - apt update
   - Install flatpak if not present

3. **Restore packages:**
   - Read `packages/apt-packages.txt` and install via apt
   - Read `packages/flatpak-packages.txt` and install via flatpak
   - Add apt repositories from `packages/apt-repositories.txt`

4. **Install Oh-My-Zsh:**
   - Download and install oh-my-zsh
   - Stow will overlay custom plugins

5. **Install TPM (Tmux Plugin Manager):**
   - Clone TPM to `~/.config/tmux/plugins/tpm`

6. **Apply all stow packages:**
   ```bash
   cd ~/dotfiles
   stow */
   ```

7. **Install additional tools:**
   - Install starship prompt
   - Install fzf
   - Install zoxide (if used)
   - Install lazygit (if used)

8. **Apply dconf settings:**
   ```bash
   dconf load / < dconf/popos-settings.dconf
   ```

9. **Final setup:**
   - Change shell to zsh
   - Source zshrc
   - Run tmux plugin install

---

## File Structure After Migration

```
~/Work/Test/dotfiles/
├── README.md
├── install.sh
├── backup.sh
├── packages/
│   ├── apt-packages.txt
│   ├── apt-repositories.txt
│   └── flatpak-packages.txt
├── dconf/
│   └── popos-settings.dconf
├── nvim/.config/nvim/
├── zed/.config/zed/
├── alacritty/.config/alacritty/
├── tmux/.config/tmux/
├── zsh/.zshrc + .config/zsh/
├── oh-my-zsh/.oh-my-zsh/custom/
├── starship/.config/starship.toml
├── git/.gitconfig + .config/git/
├── btop/.config/btop/
└── neofetch/.config/neofetch/
```

---

## Next Steps

1. Review this plan
2. Run the backup script to capture current state
3. Create the directory structure
4. Copy all configurations
5. Test stow with dry-run
6. Apply stow and verify everything works
7. Commit to git
8. Test the install script on a clean environment (or VM)

Would you like me to proceed with creating the scripts and structure?
