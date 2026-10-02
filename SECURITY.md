# Security — LidModes

## Passwordless sudo (optional, for lid-closed mode)

Lid-closed mode needs `pmset disablesleep`, which requires root. LidModes does **not** leave a wide admin shell open.

### What install does

1. Copies `bin/lidmodes-pmset` → `/usr/local/libexec/lidmodes-pmset` (owner `root:wheel`, mode `755`).
2. Writes `/etc/sudoers.d/lidmodes` allowing **only** your user:
   ```
   YOUR_USER ALL=(root) NOPASSWD: /usr/local/libexec/lidmodes-pmset
   ```
3. Checks syntax with `visudo -cf` before activating.

After install, the app calls:

```text
sudo -n /usr/local/libexec/lidmodes-pmset on|off|restore|status
```

### What the helper accepts

Only four verbs: `on`, `off`, `restore`, `status`.  
Inside it only runs `/usr/bin/pmset` with fixed flags (no `eval`, no user-supplied shell strings).

### Threat: path hijack

If NOPASSWD pointed at a **user-writable** script, malware could replace it and run as root. Mitigation:

- Install under `/usr/local/libexec/` as root-owned `755`
- Sudoers lists the **full path** only (no wildcards)
- Uninstall removes sudoers + binary (`Uninstall passwordless sudo` in menu, or `scripts/uninstall-nopasswd.sh`)

### What this does *not* grant

- No arbitrary `pmset` argv from the network
- No general root shell
- No passwordless sudo for other binaries

### Lid-closed limits

`disablesleep` is **experimental**. The Mac may still sleep (Clamshell Sleep); clock/network can glitch. Prefer AC power. Do not use in a closed bag. AC Safety Lock (default ON) refuses lid-closed on battery and restores Default if you unplug.

### Terminal install (alternative)

```bash
./scripts/install-nopasswd.sh
./scripts/uninstall-nopasswd.sh
```
