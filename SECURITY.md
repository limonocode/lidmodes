# Security — LidModes

## Passwordless sudo (opt-in)

Lid-closed mode needs `pmset disablesleep`, which requires root. By default LidModes does **not** install a sudoers rule. Each power change shows the macOS administrator dialog (password or Touch ID).

The menu checkbox **I agree — passwordless sudo** is the consent. Checking it enters an admin password **once** and installs the helper below. Unchecking removes it. The rules are shown in the menu before the checkbox.

### What install does

1. Copies `bin/lidmodes-pmset` → `/usr/local/libexec/lidmodes-pmset` (owner `root:wheel`, mode `755`).
2. Writes a sudoers draft with `mktemp` to a random file under `/etc/sudoers.d/` whose name contains a dot, so `sudo` ignores it until `visudo -cf` succeeds. It is then renamed to `/etc/sudoers.d/lidmodes`. There is no fixed temporary path.
3. The rule allows **only** your user:
   ```
   YOUR_USER ALL=(root) NOPASSWD: /usr/local/libexec/lidmodes-pmset
   ```

After install, the app calls:

```text
sudo -n /usr/local/libexec/lidmodes-pmset on|off|restore|status
```

### What the helper accepts

Only four verbs: `on`, `off`, `restore`, `status`.  
Inside it only runs `/usr/bin/pmset` with fixed flags (no `eval`, no user-supplied shell strings).

`on` saves the current battery values of `sleep`, `lowpowermode`, and `tcpkeepalive` to `/usr/local/var/lidmodes/battery-snapshot` (root-owned). `off` and `restore` write those values back and clear `disablesleep`. Values that are not plain integers are rejected. The helper does not turn Low Power Mode on by itself.

### Touch ID and Keychain

The menu can require confirmation **before lid-closed turns on**:

- **Touch ID** — LocalAuthentication biometrics. No secret is stored.
- **Keychain** — a random 32-byte token in the login keychain, protected so reading it asks for the device password. The Mac account password is not stored.

Turning the mode off, AC Safety, and Quit do not ask for Touch ID or Keychain, so sleep can be restored even when you are not looking at the prompt. Without the passwordless helper, that restore may still show the administrator dialog once.

### Threat: path hijack

If NOPASSWD pointed at a **user-writable** script, malware could replace it and run as root. Mitigation:

- Install under `/usr/local/libexec/` as root-owned `755`
- Sudoers lists the **full path** only (no wildcards)
- Uninstall removes sudoers + binary (uncheck **I agree — passwordless sudo**, or `scripts/uninstall-nopasswd.sh`)

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
