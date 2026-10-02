# Smoke — LidModes day-1

| # | Step | Expect |
|---|------|--------|
| 1 | `./scripts/run.sh` | Menu bar icon; no crash |
| 2 | Default → Stay awake | `caffeinate=on`, `SleepDisabled=0`, no password |
| 3 | Read the rules, check **I agree — passwordless sudo** | Admin once; status `sudo=ok`; no fixed sudoers file in `/tmp` |
| 3b | Set **Touch ID**, choose lid-closed, cancel the prompt | Mode unchanged |
| 3c | Set **Keychain**, choose lid-closed, approve | Keychain prompt; then lid-closed (no second password if sudo is ok) |
| 3d | Set **Click only** (passwordless stays on) | Next lid-closed switch does not ask |
| 4 | Default → Stay awake (lid closed) on AC | `SleepDisabled=1`; brightness dims if API works; no password dialog |
| 5 | Wait 5 minutes | One soft Tink |
| 6 | Heartbeat click off | Silence |
| 7 | Unplug AC (AC Safety ON) | → Default; `SleepDisabled=0`; brightness restored |
| 8 | Closed on battery with AC Safety ON | Refused; mode unchanged |
| 9 | Quit while closed | Brightness restored; `SleepDisabled=0` |
| 10 | Uncheck **I agree — passwordless sudo** | `sudo=missing`; `sudo -n` fails |
| 10b | Lid-closed again with passwordless off | Administrator prompt (password or Touch ID) |
| 11 | README / SECURITY | No “lid closed always works” |
