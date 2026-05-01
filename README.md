# dotfiles

Personal config + system snapshot for Pop!_OS COSMIC. Managed with [GNU Stow](https://www.gnu.org/software/stow/).

## What's tracked

| Stow package | Targets |
|---|---|
| `shell/` | `~/.zshrc`, `~/.bashrc`, `~/.profile` |
| `git/` | `~/.gitconfig`, `~/.config/git/{hooks,ignore}` |
| `nvim/` | `~/.config/nvim/` (LazyVim) |
| `zed/` | `~/.config/zed/` |
| `alacritty/` | `~/.config/alacritty/alacritty.toml` |
| `tmux/` | `~/.config/tmux/{tmux.conf,scripts,projects}` (plugins/ ignored — TPM-managed) |
| `btop/` | `~/.config/btop/btop.conf` |
| `neofetch/` | `~/.config/neofetch/config.conf` |
| `starship/` | `~/.config/starship.toml` |

Plus snapshot-only (not symlinked):

| Path | Source |
|---|---|
| `packages/apt-manual.txt` | `apt-mark showmanual` |
| `packages/apt-sources/` | `/etc/apt/sources.list.d/` |
| `packages/flatpak.txt` | `flatpak list --app` |
| `dconf/dconf.dump` | `dconf dump /` (mostly GTK leftovers — COSMIC bypasses dconf) |
| `cosmic-config/` | `~/.config/cosmic/` (COSMIC desktop settings: keybinds, panel, theme, ...) |

## Scripts

| Script | What it does |
|---|---|
| `stow.sh` | Idempotently restows every package via `stow -R`. Run after editing files in this repo. |
| `backup.sh` | Refreshes the snapshot dirs from the live system. Run before committing system changes. |
| `install.sh` | Bootstraps a fresh Pop!_OS COSMIC machine end-to-end (12 phases). |

## Daily workflow

**After editing a config file in this repo:**
```sh
./stow.sh        # repair any drift (usually a no-op since stowed files are symlinks)
git add -A && git commit -m "..."
```

**After installing packages or changing COSMIC settings:**
```sh
./backup.sh      # refresh snapshots
git diff         # review what changed
git add -A && git commit -m "..."
```

## Fresh-install bootstrap

On a new Pop!_OS COSMIC box:

```sh
git clone <this-repo-url> ~/dotfiles
cd ~/dotfiles
./install.sh
```

Then:
- Open a new terminal so zsh loads
- In tmux, hit `prefix + I` (capital I) to install TPM plugins
- Log out/in (or restart `cosmic-comp`) so COSMIC reloads restored settings

## Notes

- **COSMIC config is a copy, not a symlink.** Some apps write configs via atomic rename, which silently breaks symlinks. `cosmic-config/` is a snapshot — re-run `backup.sh` to capture changes.
- **APT signing keys** for Docker / Cloudflare / Chrome are not committed; `install.sh` re-fetches them from each vendor.
- **`apt-manual.txt`** includes Pop!_OS base packages (bash, apt, etc.). Re-installing them is a no-op so the noise is harmless.
- **Favorites and a few COSMIC values reference `/home/waseem`** absolute paths. They survive only if the same username exists on the new machine.
