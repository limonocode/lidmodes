Было: нет карты поискового спроса под MacTraySleep.
Есть: исследование запросов EN/RU (Google Suggest + Google Ads volume) и кластеры для README/ASO.
Дальше: Wordstat Яндекса восстановить (сейчас 403) и при желании App Store Suggest.

# Search demand — keep-awake / lid-closed Mac apps

Дата: **2026-10-02**. Проект: `/Users/dmitry/projects/mac-tray-sleep`.  
Источники: Google Suggest, Google Ads Keyword Volume (DataForSEO via treg), статьи/репо конкурентов.  
**Яндекс Wordstat / XML: 403** в этой сессии — RU натуральные фразы без показов Wordstat; для РФ опираемся на Suggest + how-to и brand EN.

Сырые файлы в этой папке:

| Файл | Что |
|------|-----|
| `google-suggest.json` / `google-suggest-flat.csv` | автодополнение Google EN/RU по сидам |
| `google-volume-us-en.csv` | объёмы Google Ads, US / en |
| `google-volume-ru.csv` | объёмы Google Ads, RU (мало натуральных фраз) |
| `google-ideas-amphetamine-mac.csv` | related ideas от сида `amphetamine mac` |
| `wordstat-ru-seeds.csv` | пустой (API 403) |

---

## Вывод одной строкой

Спрос в Google **брендовый и «keep mac awake»**, а не длинный «lid closed». Узкий lid-closed — **десятки** показов/мес в US, но **растёт** (seed `keep mac awake with lid closed`: avg ~20, Aug 2026 уже ~90). Навигация: Amphetamine / Caffeine / caffeinate / KeepingYouAwake.

---

## Кластеры запросов (для README, ASO, GitHub topics)

### A. Brand / app name (высокий объём)

| Запрос (US en) | Volume/мес | Заметка |
|----------------|----------:|---------|
| caffeine mac | 5400 | путаница с напитком + app |
| caffeinate mac | 5400 | CLI Apple |
| amphetamine mac | 1900 | главный конкурент App Store |
| caffeine mac app | 480 | уточнение app |
| keepingyouawake | 320 | OSS idle |
| lungo mac | 20 | Setapp; шум «lungo macchiato» |

**RU Google (geo RU):** `caffeine mac` 480 · `amphetamine mac` 320 · `caffeinate` 320 · `keepingyouawake` 40.  
Голое `amphetamine` (~90k) — **не наш интент** (наркотик/ADHD), в контенте не целить.

### B. Job-to-be-done: не спать (открытая крышка)

| Запрос | Volume US | Suggest / notes |
|--------|----------:|-----------------|
| keep mac awake | 260 | ядро idle |
| keep mac awake app / caffeine / terminal | — | сильные саджесты |
| keep mac awake when plugged in | — | suggest |

### C. Job-to-be-done: крышка закрыта (наша ниша)

| Запрос | Volume US | Динамика / notes |
|--------|----------:|------------------|
| keep mac awake with lid closed | **20** (Aug **90**) | yearly trend ↑ сильно |
| mac sleep when lid closed | 140 | смешанный интент (почему спит / как не спать) |
| keep mac awake when lid closed / when closed | — | сильный Suggest |
| keep macbook awake lid closed / from sleeping when closed | — | Suggest, volume 0 в Ads |
| pmset disablesleep | 30 | power-user / how-to |
| prevent mac sleep lid closed | 0 Ads | живой язык в статьях |
| amphetamine alternative (+ mac) | 30 / 10 | конкуренты SEO: Clamshell, LidRun, Sleepless |

### D. AI / agents (новый слой 2025–2026)

Suggest и репо: `keep mac awake for claude`, Cursor / Codex / Claude Code + lid.  
Volume Ads по точной фразе ~0, но **контентный спрос** (LidAwake, Vigil, StayAwake, macowl) — целить в README/topics: `ai-agents`, `claude-code`, `cursor`.

### E. RU how-to язык (Wordstat недоступен)

Из Google Suggest RU + статей (iphones.ru, remontka, caffeine-app.net):

- macbook не засыпать / не уходит в сон  
- macbook работает с закрытой крышкой  
- программа не давать маку заснуть  
- запретить сон macbook / как отключить сон macbook  
- amphetamine / caffeine mac (латиница в RU поиске)

В РФ люди часто ищут **имя приложения на EN**, а how-to — на русском в статьях.

---

## Что пишут в поиске вокруг конкурентов

Сиды Suggest `amphetamine alternative*`: mac, macos, github, reddit, vs caffeine.  
Related: `amphetamine power protect`, `amphetamine enhancer`, `amphetamine triggers`, `amphetamine vs caffeine mac`.

Позиционирование контента конкурентов (для нашего README):

- «Amphetamine alternative» + lid closed  
- «caffeinate / KeepingYouAwake can’t close lid»  
- `pmset disablesleep` + timer + battery floor  
- AI agents keep running with lid shut  

---

## Рекомендации для MacTraySleep (публичный репо / сайт)

**Primary keywords (EN README H1/H2):**

1. keep Mac awake  
2. Amphetamine alternative (honest compare)  
3. keep Mac awake with lid closed / MacBook lid closed  
4. pmset disablesleep (docs section)  
5. caffeinate vs lid sleep  

**GitHub topics:** `macos`, `menubar`, `caffeinate`, `amphetamine`, `keep-awake`, `clamshell`, `pmset`, `ai-agents`.

**Не ставить в title:** голое `amphetamine` без `mac` (шум).  
**RU:** вторичный README-блок; ключи brand EN + «закрытой крышкой».

**ASO App Store (если будет):** Title ~ «Stay Awake — Lid Closed»; subtitle «Caffeinate · Amphetamine-style»; keywords: awake,sleep,lid,clamshell,caffeine,pmset,agent.

---

## Ограничения исследования

1. Яндекс Wordstat 403 — нет РФ показов по натуральным фразам.  
2. Google Ads часто даёт **null** на длинные RU фразы (мало рекламного спроса).  
3. Suggest ≠ volume, но хорошо показывает **язык пользователя**.  
4. Повторный Wordstat / App Store Connect Suggest — когда API оживёт.

---

## Связь с продуктом

| Кластер | Наш режим | Сила спроса |
|---------|-----------|-------------|
| keep mac awake / caffeine | Stay awake (open) | средне-высокий brand+job |
| lid closed / pmset / amphetamine closed | Stay awake (lid closed) | низкий volume, высокий intent, рост |
| default / restore sleep | Default | слабо ищется; нужен UX safety |
