# Remote Dev Setup: Laptop → Pi → Desktop

Work from a low-power laptop anywhere with internet, leveraging the desktop's CPU/RAM/disk on demand. Desktop sleeps when idle; Pi wakes it via WoL; Tailscale handles the network.

## Architecture

```
[ Laptop (IdeaPad 3, 8GB) ]                [ Raspberry Pi ]              [ Desktop (Pop!_OS, headless) ]
  - Zed (remote)                              - Always on (~3W)             - Sleeps when idle
  - Alacritty + mosh + tmux (remote)          - Tailscale 24/7              - Tailscale + sshd
  - Zen browser (local)                       - wakeonlan on LAN            - All dev servers + tmux
  - autossh (tunnels)                                                       - Big projects, NVMe, GPU
        │                                           │                              │
        └────── Tailscale ─────────────────────────►│                              │
                                                    └──── magic packet (LAN) ─────►│
        └──────────────────── Tailscale (after wake) ────────────────────────────►│
```

**Roles:**
- **Laptop**: thin-ish client. Runs editor UI, terminal UI, browser. No heavy compute.
- **Pi**: always-on bridge. Only job is sending WoL magic packets on the LAN when triggered over Tailscale. (Tailscale can't wake a sleeping host directly — magic packets are layer-2.)
- **Desktop**: does all the work. Headless (no GUI), suspends to RAM when idle.

## Why this beats alternatives

- **vs. always-on desktop**: saves ~50W × 24h when not working.
- **vs. cloud dev box**: free, faster (local NVMe + your real GPU), no monthly fee.
- **vs. streaming the whole desktop (Sunshine/Moonlight)**: lower bandwidth, works fine on 4G, and the laptop stays useful offline for browsing/notes.
- **vs. tmux on laptop SSHing out**: one connection instead of N; survives disconnects; processes don't die when the link drops.

## Components & setup

### Desktop (Pop!_OS)

**Headless boot:**
```sh
sudo systemctl set-default multi-user.target
```
Boots to TTY, no GDM/Cosmic. `systemctl start gdm` if ever needed locally.

**BIOS:**
- Enable Wake-on-LAN (often "Power On by PCIe" or similar).
- Disable "Halt on no keyboard" / "Halt on no display."
- Set sleep mode to S3 (suspend-to-RAM). Avoid S4/hibernate — WoL often doesn't work from it.

**Wake-on-LAN persistence (OS side):**

`ethtool -s <iface> wol g` resets on reboot. Persist via systemd-networkd or NetworkManager. Example systemd unit:
```ini
# /etc/systemd/system/wol.service
[Unit]
Description=Enable Wake-on-LAN
After=network.target

[Service]
Type=oneshot
ExecStart=/usr/sbin/ethtool -s enp4s0 wol g

[Install]
WantedBy=multi-user.target
```
`sudo systemctl enable --now wol.service`

**Test cold-boot wake AND suspend wake separately.** Some boards only do one.

**Services to verify enabled at boot:**
- `tailscaled`
- `sshd`
- `wol.service` (above)

**SSH hardening:** key-only, no password auth. Tailscale ACLs lock external reach.

### Pi

- Tailscale installed, `tailscale up`, authenticated, stays online 24/7.
- `wakeonlan` package installed.
- SSH key from laptop authorized.

That's it. The Pi exists only to run `wakeonlan AA:BB:CC:DD:EE:FF` on demand.

### Laptop

**`~/.ssh/config`:**
```
Host pi
    HostName pi.tailnet-name.ts.net
    User pi

Host desktop
    HostName desktop.tailnet-name.ts.net
    User waseem
    # Forwarded dev ports
    LocalForward 3000 localhost:3000
    LocalForward 5173 localhost:5173
    LocalForward 8000 localhost:8000
    LocalForward 8080 localhost:8080
    LocalForward 5432 localhost:5432
    LocalForward 6379 localhost:6379
    LocalForward 9000 localhost:9000
```

**Tools:** Zed, Alacritty, mosh, autossh, tailscale, ssh-agent loaded with key.

## Scripts

### `wake-desktop`
```sh
#!/bin/sh
set -e
ssh pi 'wakeonlan AA:BB:CC:DD:EE:FF'
echo "magic packet sent, waiting for ssh..."
timeout 60 sh -c 'until ssh -o ConnectTimeout=2 -o BatchMode=yes desktop true 2>/dev/null; do sleep 1; done' \
  || { echo "desktop didn't wake in 60s"; exit 1; }
echo "desktop is up"
```

### `start-work`
```sh
#!/bin/sh
set -e
wake-desktop
autossh -M 0 -fN desktop                          # tunnels in background
zed ssh://desktop/home/waseem/projects/current &  # editor
alacritty -e mosh desktop -- ./sessionizer        # terminal in foreground
```

### `sleep-desktop`
```sh
#!/bin/sh
ssh desktop sudo systemctl suspend
```
(Configure passwordless sudo for `systemctl suspend` only, or use `loginctl suspend` which doesn't need sudo.)

## Connection layers

Three independent connections to the desktop, all over Tailscale:

| Connection | Purpose | Reconnect | Latency handling |
|---|---|---|---|
| `autossh -fN desktop` | Port forwards (dev servers) | autossh auto-reconnects | n/a — TCP |
| `mosh desktop -- ./sessionizer` | Terminal + tmux | survives drops & IP changes | predictive local echo |
| `zed ssh://desktop/...` | Editor | Zed handles drops itself | round-trip per keystroke (no echo prediction) |

Mosh and tmux are orthogonal: mosh = transport, tmux = session persistence. They compose. Tmux runs **on the desktop** so processes survive disconnects.

Zed Remote runs LSP/search/indexing on the desktop — only UI diffs cross the network. Big codebases search at desktop speed.

## Bandwidth & latency

- **Bandwidth**: steady state <1 Mbps across all three connections. 4G is overkill on throughput.
- **Latency**: this is the real variable.
  - Tailscale direct P2P: usually fine.
  - Tailscale via DERP relay: +80–200ms RTT.
  - 4G adds another 30–80ms typical.
- **Mosh** hides typing latency in shells/editors via predictive echo.
- **Zed** does not predict — keystroke echo is round-trip. Usable on 4G, noticeable.

## Gotchas / things that will bite if not handled

- WoL setting in OS resets on reboot → systemd unit (above).
- Hibernate (S4) usually breaks WoL → use suspend (S3).
- Mosh **does not** forward ports → autossh handles tunnels separately.
- `ssh-agent` must hold the key, otherwise each of (autossh, Zed, mosh) prompts independently.
- Port forwards die when desktop sleeps mid-session → autossh reconnects after wake.
- Zed's integrated terminal is a fresh shell on the desktop, not the tmux session — keep mosh+tmux for persistent work.
- First wake after a desktop reboot: confirm `tailscaled` and `sshd` start before login.
- Pi must stay on Tailscale 24/7 — it's the only always-reachable node.

## Open questions / decisions

- **Offline work**: laptop has nothing local. Acceptable, or mirror critical repos?
- **Auto-resleep**: `IdleAction=suspend` in logind respects active SSH sessions, so desktop won't sleep mid-work but also won't sleep until you disconnect. Likely fine; revisit if power becomes an issue.
- **Sessionizer location**: lives on desktop. Keep `.tmux.conf`, shell history, fzf bindings all on desktop where the work is.

## Status

- [ ] Pi acquired + Tailscale auth
- [ ] Desktop BIOS WoL + halt-on-error settings
- [ ] Desktop `multi-user.target` default
- [ ] Desktop `wol.service` + persistence test across reboot
- [ ] WoL test: cold boot
- [ ] WoL test: suspend
- [ ] SSH config + Tailscale ACLs
- [ ] `wake-desktop` script
- [ ] `start-work` script
- [ ] `sleep-desktop` script
- [ ] First end-to-end run from 4G
