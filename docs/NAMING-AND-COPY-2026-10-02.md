Было: LidModes locked по имени; код ещё RU + AppleScript pmset.
Есть: day-1 код — EN меню, path-pinned sudo helper, AC Safety, dim, heartbeat; docs SECURITY/README/SMOKE.
Дальше: ручной smoke; `gh repo create` по «выложи».

# Naming & copy — 2026-10-02

Источник спроса: [`research/SEARCH-DEMAND-2026-10-02.md`](../research/SEARCH-DEMAND-2026-10-02.md).  
Правило long-tail: **чужие имена только в сравнении / «alternative to …»**, не в названии продукта.

**LOCK 2026-10-02:** имя утверждено владельцем.

---

## Канон (locked)

| | |
|--|--|
| **Имя** | **LidModes** |
| **Slug / GitHub** | `limonocode/lidmodes` |
| **Tagline** | Keep your Mac awake — three clear modes. |
| **Binary / SPM** | `LidModes` |
| **Folder (local)** | `mac-tray-sleep` (path можно оставить) |

Позиция: menubar keep-awake; три режима; lid-closed = experimental opt-in.  
Не брать: LidStay, AwakeBar, Theanine, чужие бренды в CFBundleName.

---

## Consul history (кратко)

| Run | Вердикт |
|-----|---------|
| `2026-10-02-theanine-name` | REJECT Theanine |
| `2026-10-02-lidstay-pre-github` | LidStay занят (bruno + ghk); AwakeBar crowded; → LidModes |

Коллизии LidStay: https://github.com/brunoqgalvao/lidstay · https://github.com/ghkdqhrbals/LidStay

---

## Меню (EN source)

1. **Default** — normal sleep (lid closes → sleep)  
2. **Stay awake** — open lid; `caffeinate`  
3. **Stay awake (lid closed)** — experimental `pmset disablesleep`  

Disclaimer (closed):  
*Experimental. May still sleep; clock/network can glitch. Prefer AC. Not for use in a bag.*

---

## GitHub About (≤350)

> macOS menu bar keep-awake with three modes: Default, open-lid caffeinate, experimental lid-closed (pmset). Amphetamine alternative for a short menu. Prefer AC; not for use in a bag.

## Topics

`macos` `menubar` `keep-awake` `caffeinate` `clamshell` `pmset` `amphetamine` `keepingyouawake` `ai-agents`

---

## README blurb (EN)

См. корневой [`README.md`](../README.md).

---

## Comparison (for README)

| | LidModes | Amphetamine | KeepingYouAwake / Caffeine / Lungo | `caffeinate` |
|--|:--:|:--:|:--:|:--:|
| Open-lid idle awake | yes | yes | yes | yes |
| Lid closed, no display | experimental | Closed-Display / Power Protect | no (by design) | no |
| Open source | yes | no (App Store) | KYA yes | Apple CLI |
| One-shot sudo for pmset | yes (optional) | helper / store limits | n/a | manual sudo |
| Triggers / sessions | minimal (timer, AC lock) | full | timer | flags |

---

## Long-tail map

| Query / phrase | Где |
|----------------|-----|
| Amphetamine alternative mac | H2, compare |
| KeepingYouAwake / Caffeine / caffeinate | compare / how we differ |
| pmset disablesleep | technical |
| Clamshell / LidRun / Sleepless | similar tools list |
| LidStay (чужие репо) | не наше имя; не путать |

**Avoid:** title с голым `amphetamine` без `mac` / `alternative`.

---

## ASO draft (если .app)

**Name:** LidModes  
**Subtitle:** Keep Mac Awake · Three Modes  
**Keywords:** `awake,sleep,lid,clamshell,caffeine,amphetamine,keepingyouawake,pmset,caffeinate,agent`

---

## RU (вторично)

Меню: по умолчанию / не спать / не спать с закрытой крышкой (experimental). Альтернатива Amphetamine с коротким меню и честными лимитами.
