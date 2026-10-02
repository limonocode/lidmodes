# LidModes

Keep your Mac awake — three clear modes.

LidModes is a tiny macOS menu bar app: **Default** (normal sleep), **Stay awake** with the lid open (`caffeinate`), and **Stay awake with the lid closed** (experimental `pmset disablesleep`). Open-source Amphetamine alternative — short menu, honest limits.

## Modes

| Mode | What it does |
|------|----------------|
| Default | Normal sleep (closing the lid sleeps the Mac) |
| Stay awake | Open lid; uses `caffeinate` |
| Stay awake (lid closed) | Experimental `pmset disablesleep` + dim display + optional heartbeat click |

## Limits (read this)

- Lid-closed is **experimental**. The Mac may still sleep; clock and network can glitch.
- Prefer **AC power**. AC Safety Lock (default ON) blocks lid-closed on battery and restores Default if you unplug.
- **Not for use in a bag.**
- Display dim to 0 is best-effort on the built-in panel; with the lid closed the panel is dark anyway.
- While lid-closed is on, LidModes plays a soft system **Tink** every **5 minutes** so you can hear the Mac is still awake (toggle in menu; default ON).
- We do **not** claim “lid closed always works.”

## Install (dev)

```bash
./scripts/run.sh
```

Requires macOS 14+. Menu bar icon appears after launch.

### One-time passwordless sudo (for lid-closed)

From the menu: **Install passwordless sudo** (one admin password), or:

```bash
./scripts/install-nopasswd.sh
```

This installs a path-pinned helper at `/usr/local/libexec/lidmodes-pmset` and a narrow `/etc/sudoers.d/lidmodes` entry. Details: [SECURITY.md](SECURITY.md).

Uninstall from the menu or `./scripts/uninstall-nopasswd.sh`.

## Compared with

| | LidModes | Amphetamine | KeepingYouAwake / Caffeine / Lungo | `caffeinate` |
|--|:--:|:--:|:--:|:--:|
| Open-lid idle awake | yes | yes | yes | yes |
| Lid closed, no display | experimental | Closed-Display / Power Protect | no (by design) | no |
| Open source | yes | no (App Store) | KYA yes | Apple CLI |
| One-shot sudo for pmset | yes (optional) | helper / store limits | n/a | manual sudo |

## Security

See [SECURITY.md](SECURITY.md). Do not point NOPASSWD at a user-writable script.

## License

MIT — see [LICENSE](LICENSE).
