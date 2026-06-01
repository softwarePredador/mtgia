# Hermes Cron Governance Report

> Generated: 2026-06-01T13:30Z (approx)
> Cron: `manaloom-cron-governor-report` (21fa86eb0d84) — first execution
> Workdir: `/opt/data/workspace/mtgia` | Branch: `codex/hermes-analysis-docs`

## Executive Summary

**Fleet state: 23 crons total — 11 enabled (10 OK, 1 never-run), 12 paused (9 error/429, 3 OK).**

A mass pause event at 2026-05-31T15:58:08Z disabled 10 openrouter/owl-alpha crons suffering from systemic 429 rate limit. The manager-watchdog responsible for recovery was also paused. Enabled crons (all deepseek-v4-pro/opencode-go) are running normally without errors.

**CRON_STATUS.md is 29+ hours stale** — last updated 2026-05-31T07:13:03Z, before the mass pause. The fleet has grown from 18 to 23 crons.

---

## 1. Fleet Inventory

### 1.1 Enabled Crons (11) — All deepseek-v4-pro / opencode-go

| Job ID | Name | Schedule | Last Run | Status | Completed |
|:---|---:|:---|:---|:---:|---:|
| `f20ac299992b` | lorehold-deck-scout | every 180m | 2026-06-01T11:32Z | ok | 93 |
| `712579b15767` | lorehold-deck-validator | every 180m | 2026-06-01T11:28Z | ok | 55 |
| `08468451a06a` | lorehold-mulligan-analyst | every 180m | 2026-06-01T10:33Z | ok | 38 |
| `a50bef4c2a59` | lorehold-evolution-oracle | every 240m | 2026-06-01T11:38Z | ok | 34 |
| `de6fb777f5d1` | manaloom-logic-coherence-auditor | every 360m | 2026-06-01T12:41Z | ok | 19 |
| `10a59b3bdf4d` | manaloom-knowledge-synthesis | every 240m | 2026-06-01T09:55Z | ok | 13 |
| `11780da0894a` | lorehold-wincon-hunter | every 360m | 2026-06-01T11:15Z | ok | 4 |
| `8ea24b001c86` | lorehold-wincon-tester | every 360m | 2026-06-01T11:11Z | ok | 5 |
| `8ede9aa84b4d` | lorehold-wincon-builder | every 360m | 2026-06-01T10:34Z | ok | 2 |
| `4b2a79809aed` | lorehold-deckbuilding-methodology | every 360m | 2026-06-01T10:39Z | ok | 3 |
| `21fa86eb0d84` | manaloom-cron-governor-report | every 720m | **never** | null | 0 |

**Scheduling health:** All enabled crons have `next_run_at` in the future. No stale crons detected. The `mulligan-analyst` ran 132m ago on a 180m schedule (within threshold). All others are well within their schedule windows.

### 1.2 Paused Crons (12)

#### Paused with 429 Error (9) — All openrouter/owl-alpha

Paused simultaneously at **2026-05-31T15:58:08Z** (±5ms). Root cause: `HTTP 429: Rate limit exceeded: free-models-per-day-stealth`.

| Job ID | Name | Schedule | Last Run | Last Error |
|:---|---:|:---|:---|:---|
| `660397bb97e1` | manaloom-hermes-normal-audit | 0 16,21 * * * | 2026-05-30T21:00Z | 429 |
| `aeaeb666d377` | manaloom-hermes-weekly-parallel-audit | 0 12 * * 0 | 2026-05-31T12:00Z | 429 |
| `75eed994c103` | manaloom-commander-knowledge-deep | every 240m | 2026-05-31T14:50Z | 429 |
| `7915cc2377a0` | manaloom-gamechanger-research | every 120m | 2026-05-31T13:58Z | 429 |
| `2d436c71bbf7` | **manaloom-manager-watchdog** | every 30m | 2026-05-31T15:29Z | 429 |
| `b340374bc4e7` | manaloom-tag-accuracy-reporter | every 1440m | 2026-05-31T14:44Z | 429 |
| `444aa9510c2c` | manaloom-mana-base-validator | every 360m | 2026-05-31T15:14Z | 429 |
| `b2f5c21ce2d7` | manaloom-knowledge-import | every 120m | 2026-05-31T14:45Z | 429 |
| `bb03201b8911` | manaloom-code-structure-auditor (3h) | every 180m | 2026-05-31T14:23Z | 429 |

#### Paused but OK (3)

| Job ID | Name | Provider | Schedule | Paused At | Last Status |
|:---|---:|:---|:---|:---|:---:|
| `757eefb8738b` | manaloom-master-watchdog | (script) | every 30m | 2026-05-31T15:58Z | ok |
| `577a0a669714` | manaloom-code-structure-auditor (weekly) | openrouter/owl-alpha | 0 6 * * 0 | 2026-05-31T15:58Z | ok |
| `c0591cb18024` | mtg-rules-auditor | deepseek-v4-pro | 0 0 * * * | 2026-06-01T02:25Z | ok |

**Anomaly — `mtg-rules-auditor`:** Paused separately at 2026-06-01T02:25:01Z, ~10h after the mass pause. Provider is deepseek-v4-pro (same as working crons), last run 2026-06-01T00:08:53Z with status=ok, 4 completions. Pause reason is `null`. This may be intentional deprecation or a bug — investigate.

---

## 2. CRON_STATUS.md Staleness

**CRON_STATUS.md last updated: 2026-05-31T07:13:03Z** by the manager-watchdog (2d436c71bbf7).

**What it reports:** 18 crons, 16 OK, 2 error. "Estagnacao quebrada", rate limit recovering.

**Reality now (30h later):** 23 crons, 10 OK, 9 error/429, 1 never-run, 3 paused-but-OK. The manager-watchdog itself has been paused for 22h.

**Impact:** The main operational dashboard for cron health is frozen at a point before the most significant event (mass pause). No recovery actions are being tracked because the manager-watchdog is down.

**Recommendation (P0):** Resume manager-watchdog (2d436c71bbf7) or migrate it to deepseek-v4-pro. Without it, auto-recovery is dead and CRON_STATUS.md won't update.

---

## 3. Provider / Model Distribution

| Provider | Model | Count | Status |
|:---|:---|---:|:---|
| opencode-go | deepseek-v4-pro | 12 | All enabled, all OK (1 never-run) |
| openrouter | owl-alpha | 10 | All paused, 9 with 429 errors |
| (none) | (script) | 1 | Paused, was OK |

**Observation:** The fleet has cleanly bifurcated. All deepseek-v4-pro crons work. All openrouter/owl-alpha crons are paused with rate-limit errors. This is not a transient rate-limit recovery — it's a hard pause that happened at the scheduler/infrastructure level.

---

## 4. Fleet Changes Since Last CRON_STATUS.md Update

### New Crons Added (6)

| Job ID | Name | Created | Schedule | Provider |
|:---|---:|:---|:---|:---|
| `11780da0894a` | lorehold-wincon-hunter | 2026-06-01T09:17Z | every 360m | deepseek-v4-pro |
| `8ea24b001c86` | lorehold-wincon-tester | 2026-06-01T09:17Z | every 360m | deepseek-v4-pro |
| `8ede9aa84b4d` | lorehold-wincon-builder | 2026-06-01T09:17Z | every 360m | deepseek-v4-pro |
| `4b2a79809aed` | lorehold-deckbuilding-methodology | 2026-06-01T09:34Z | every 360m | deepseek-v4-pro |
| `c0591cb18024` | mtg-rules-auditor | 2026-05-31T15:59Z | 0 0 * * * | deepseek-v4-pro |
| `21fa86eb0d84` | manaloom-cron-governor-report | 2026-06-01T12:36Z | every 720m | deepseek-v4-pro |

### Crons Removed (1)

- `94f8590b1beb` — lorehold-battle-analyst. No longer in jobs.json. Was listed as OK in CRON_STATUS.md at 2026-05-31T01:18Z. Output directory also absent. Appears intentionally deprecated (possibly merged into mtg-rules-auditor which covers battle analysis).

### Orphaned Output Directory

- `4430f8384ce4` — Single output from 2026-05-27. No corresponding job in jobs.json. Safe to archive/delete.

---

## 5. Worktree Risks

- **Shared branch:** All crons use `codex/hermes-analysis-docs`. Multiple crons can produce concurrent writes to `docs/hermes-analysis/**`. The pull-edit-stage-push atomic pattern is documented but not all cron prompts include it.
- **Current worktree:** Clean (`git status --short` returns empty). No dirty artifacts.
- **Knowledge.db:** Shared SQLite DB at `docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db`. Multiple crons read/write it concurrently. No WAL mode observed — risk of `SQLITE_BUSY` under concurrent writes.
- **STRUCTURE_AUDIT.md bloat:** Known to exceed 400KB+ threshold that blocks the `patch` tool. The 3h structure auditor is paused so no new bloat is accumulating, but trimming old sections is still needed for future runs.

---

## 6. Duplicate Work Assessment

| Pattern | Crons | Risk |
|:---|:---|:---|
| Two `code-structure-auditor` crons (weekly + 3h) | `577a0a669714`, `bb03201b8911` | Medium — overlapping analysis. The 3h rotation covers all 6 foci in 18h, making the weekly one redundant except for the "inventory" foci. Both are paused. |
| Wincon pipeline (hunter -> tester -> builder) | `11780da0894a`, `8ea24b001c86`, `8ede9aa84b4d` | Low — intentionally chained. But tester and builder share the same 360m schedule and run within minutes of each other. Consider staggering. |
| Multiple deck validators | `712579b15767`, `444aa9510c2c` | Low — validator does PG profile comparison, mana-base does mana-specific validation. Complementary. |
| Knowledge synthesis + import | `10a59b3bdf4d`, `b2f5c21ce2d7` | Low — synthesis generates tasks from knowledge, import pushes to PostgreSQL. Different outputs. |
| Battle analyst -> mtg-rules-auditor | `94f8590b1beb` (removed), `c0591cb18024` (paused) | The battle-analyst was removed and mtg-rules-auditor now covers battle analysis. Consolidation appears intentional. |

---

## 7. Learning Artifacts Actionable for Product Work

From the CRON_STATUS.md and enabled cron outputs:

| Artifact | Source Cron | Product Relevance |
|:---|:---|---|
| `card_rulings` usage in quality gates | knowledge-synthesis | P1 — 77K rulings in PostgreSQL, use for swap validation in optimizer |
| Synergy-axis awareness beyond role equality | knowledge-synthesis | P1 — current optimizer only checks role overlap, not synergy depth |
| MDFC/split-name dedup in deck validation | knowledge-synthesis | P2 — app/backend don't detect duplicate cards across faces |
| Wincon diversity (fast/resilient/stealth) | evolution-oracle, wincon-hunter | P2 — could inform deck scoring UX |
| Mulligan % as deck quality signal | mulligan-analyst | P2 — measurable signal for "deck health" UX metric |
| Tag accuracy: `stax_disruption` 0/3, `ninja` 0/17, `payoff` 35.5% | tag-accuracy-reporter | P2 — known classifier gaps, documented but not yet fixed |

---

## 8. Recommendations

### P0 — Resume Critical Infrastructure

| # | Action | Evidence | Risk If Not Done |
|:---|:---|---|:---|
| R1 | Resume and migrate `manaloom-manager-watchdog` (2d436c71bbf7) to deepseek-v4-pro | Paused with 429, last ran 22h ago. CRON_STATUS.md is stale. No auto-recovery in fleet. | Fleet degradation continues undetected. Paused crons stay paused indefinitely. |
| R2 | Resume `manaloom-knowledge-import` (b2f5c21ce2d7) — migrate to deepseek-v4-pro | Paused with 429. Last PostgreSQL import 22h ago. | Knowledge pipeline to PostgreSQL stalls. Synthesis crons have stale data. |

### P1 — Restore Core Audits

| # | Action | Evidence | Risk If Not Done |
|:---|:---|---|:---|
| R3 | Resume `manaloom-hermes-normal-audit` (660397bb97e1) — migrate or wait for 429 recovery | Next scheduled run 2026-06-01T16:00Z. Only audit that checks master for product changes. | Product drift undetected. |
| R4 | Resume `manaloom-mana-base-validator` (444aa9510c2c) — migrate | Validates mana bases of analyzed decks. Paused 22h ago. | No mana validation for 22h+. Quality gate blind spot. |

### P2 — Fleet Hygiene

| # | Action | Evidence | Risk If Not Done |
|:---|:---|---|:---|
| R5 | Resolve `mtg-rules-auditor` pause anomaly | Paused despite deepseek-v4-pro + ok status. 4 completions. Reason null. | Either restore or document deprecation. |
| R6 | Consolidate two `code-structure-auditor` crons | Weekly (`577a0a669714`) and 3h (`bb03201b8911`) — overlapping purpose. Both paused. | Resource waste, STRUCTURE_AUDIT.md bloat from duplicate runs. Keep 3h rotation, deprecate weekly. |
| R7 | Stagger wincon pipeline crons | All at 360m, all run within same ~30min window. | Peak load on opencode-go. Stagger by 60-90m. |
| R8 | Trim `STRUCTURE_AUDIT.md` | Known to exceed 400KB+ patch tool threshold. | Future structure audit runs blocked from writing results. |
| R9 | Archive orphan `4430f8384ce4` output directory | Single output from 2026-05-27, no corresponding job. | Clutter only, no operational risk. |

### P3 — Policy Alignment

| # | Action | Evidence | Risk If Not Done |
|:---|:---|---|:---|
| R10 | Update `HERMES_KNOWLEDGE_PIPELINE_GOVERNANCE.md` frequency table | Wincon crons (360m) comply. New governor (720m) not in policy table. Battle-analyst removed but still referenced. | Policy doc drifts from reality. |
| R11 | Enable SQLite WAL mode on knowledge.db | Multiple concurrent read/write crons. No WAL observed. | `SQLITE_BUSY` errors under concurrent access. |

---

## 9. Migration Plan for Paused openrouter/owl-alpha Crons

All 9 paused-with-429 crons can be migrated to deepseek-v4-pro/opencode-go, which has demonstrated 100% reliability across 10 active crons.

**PROPOSED ONLY — do not execute from this governance report:**

| Cron | Action | Safe to Automate? |
|:---|---|:---:|
| `2d436c71bbf7` — manager-watchdog | `cronjob(action='update', provider='opencode-go', model='deepseek-v4-pro')` then `cronjob(action='resume')` | Yes |
| `b2f5c21ce2d7` — knowledge-import | Same pattern | Yes |
| `660397bb97e1` — hermes-normal-audit | Same pattern | Yes |
| `aeaeb666d377` — hermes-weekly-parallel-audit | Same pattern | Yes |
| `75eed994c103` — commander-knowledge-deep | Same pattern | Yes |
| `7915cc2377a0` — gamechanger-research | Same pattern | Yes |
| `b340374bc4e7` — tag-accuracy-reporter | Same pattern | Yes |
| `444aa9510c2c` — mana-base-validator | Same pattern | Yes |
| `bb03201b8911` — code-structure-auditor (3h) | Same pattern | Yes |
| `577a0a669714` — code-structure-auditor (weekly) | Consider deprecation (R6) instead | Evaluate |
| `757eefb8738b` — master-watchdog | Script-based (no_agent=true). Already OK. Just needs resume. | Yes |
| `c0591cb18024` — mtg-rules-auditor | Already deepseek-v4-pro. Resume or document deprecation. | Investigate first |

**Rollout strategy:** Resume manager-watchdog first (R1). It will then auto-resume other crons per its logic. This is the lowest-touch recovery path.

---

## 10. Current Git State

- **Branch:** `codex/hermes-analysis-docs` — up to date with origin.
- **Worktree:** Clean.
- **Recent commits (last 10):** Lorehold wincon learning, governance consolidation, knowledge synthesis tasks, evolution oracle pipeline integrity alerts, mulligan regressions, EDHREC deck imports.
- **master activity:** Not inspected in detail (governor is report-only, not an audit cron).

---

*Report produced by `manaloom-cron-governor-report` (21fa86eb0d84) — first execution.*
*Next scheduled run: 2026-06-02T00:42Z (720m interval).*
