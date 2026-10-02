# Smoke — LidModes day-1

| # | Step | Expect |
|---|------|--------|
| 1 | `./scripts/run.sh` | Menu bar icon; no crash |
| 2 | Default → Stay awake | `caffeinate=on`, `SleepDisabled=0`, no password |
| 3 | Install passwordless sudo | Admin once; status `sudo=ok` |
| 4 | Stay awake (lid closed) on AC | `SleepDisabled=1`; brightness dims if API works; no password dialog |
| 5 | Wait 5 minutes | One soft Tink |
| 6 | Heartbeat click off | Silence |
| 7 | Unplug AC (AC Safety ON) | → Default; `SleepDisabled=0`; brightness restored |
| 8 | Closed on battery with AC Safety ON | Refused; mode unchanged |
| 9 | Quit while closed | Brightness restored; `SleepDisabled=0` |
| 10 | Uninstall passwordless sudo | `sudo=missing`; `sudo -n` fails |
| 11 | README / SECURITY | No “lid closed always works” |
