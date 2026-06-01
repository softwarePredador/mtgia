# Hermes Cron Governance Report

> Generated: 2026-06-01T15:30Z (approx)
> Cron: `manaloom-cron-governor-report` (21fa86eb0d84) — second execution
> Workdir: `/opt/data/workspace/mtgia` | Branch: `codex/hermes-analysis-docs` | HEAD: `41a746a2`

## Executive Summary

**Fleet state: 23 crons total — 17 enabled (ALL OK), 6 paused (3 intentional/architectural, 3 openrouter 429).**

Major recovery since last report: **6 crons migrated from paused/openrouter-429 to enabled/deepseek-v4-pro**. All 17 enabled crons are running normally with zero errors. The provider bifurcation (opencode-go vs openrouter) is effectively resolved — all active work runs on deepseek-v4-pro.

Two crons were intentionally paused for architectural reasons: `manager-watchdog` (superseded by this cron-governor-report) and `knowledge-import` (blocked until safe import flow exists). These create operational gaps: CRON_STATUS.md is no longer maintained, and PostgreSQL knowledge imports are stalled.

**CRON_STATUS.md is ~32 hours stale** — last updated 2026-05-31T07:13:03Z. No cron currently updates it.

---

## 1. Fleet Inventory

### 1.1 Enabled Crons (17) — All deepseek-v4-pro / opencode-go — ALL OK

| Job ID | Name | Schedule | Last Run | Age | Completions |
|:---|---:|:---|:---|:---:|---:|
| `f20ac299992b` | lorehold-deck-scout | every 90m | 2026-06-01T14:06Z | ~84m | 94 |
| `712579b15767` | lorehold-deck-validator | every 90m | 2026-06-01T11:28Z | ~242m | 55 |
| `08468451a06a` | lorehold-mulligan-analyst | every 90m | 2026-06-01T14:17Z | ~73m | 39 |
| `a50bef4c2a59` | lorehold-evolution-oracle | every 120m | 2026-06-01T14:26Z | ~63m | 35 |
| `de6fb777f5d1` | manaloom-logic-coherence-auditor | every 180m | 2026-06-01T14:36Z | ~53m | 20 |
| `10a59b3bdf4d` | manaloom-knowledge-synthesis | every 120m | 2026-06-01T14:54Z | ~36m | 14 |
| `11780da0894a` | lorehold-wincon-hunter | every 180m | 2026-06-01T15:10Z | ~19m | 5 |
| `8ea24b001c86` | lorehold-wincon-tester | every 180m | 2026-06-01T15:19Z | ~11m | 6 |
| `8ede9aa84b4d` | lorehold-wincon-builder | every 180m | 2026-06-01T15:19Z | ~10m | 3 |
| `4b2a79809aed` | lorehold-deckbuilding-methodology | every 180m | 2026-06-01T15:21Z | ~9m | 4 |
| `21fa86eb0d84` | **manaloom-cron-governor-report** | every 360m | 2026-06-01T12:48Z | ~162m | 1 |
| `660397bb97e1` | manaloom-hermes-normal-audit | every 120m | 2026-06-01T13:43Z | ~106m | 14 |
| `75eed994c103` | manaloom-commander-knowledge-deep | every 180m | 2026-06-01T14:59Z | ~30m | 59 |
| `7915cc2377a0` | manaloom-gamechanger-research | every 180m | 2026-06-01T15:15Z | ~14m | 64 |
| `b340374bc4e7` | manaloom-tag-accuracy-reporter | every 120m | 2026-06-01T14:45Z | ~44m | 12 |
| `444aa9510c2c` | manaloom-mana-base-validator | every 180m | 2026-06-01T13:53Z | ~96m | 29 |
| `c0591cb18024` | mtg-rules-auditor | every 180m | 2026-06-01T15:10Z | ~20m | 5 |

**Scheduling health:** All enabled crons have `next_run_at` in the future. The `lorehold-deck-validator` last ran 242m ago on a 90m schedule — appears to have missed ~1.5 cycles but its next_run_at (15:37Z) is correct. All other crons are within their schedule windows.

### 1.2 Paused Crons (6)

#### Intentionally Paused — Architectural Decisions (2)

| Job ID | Name | Provider | Paused At | Reason | Last Status |
|:---|---:|:---|:---|:---|:---:|
| `2d436c71bbf7` | manaloom-manager-watchdog | opencode-go | 2026-05-31T15:58Z | `superseded_by_report_only_cron_governor` | error (429) |
| `b2f5c21ce2d7` | manaloom-knowledge-import | opencode-go | 2026-05-31T15:58Z | `blocked_until_secret_safe_import_flow_exists` | error (429) |

**Gap analysis:** The `manager-watchdog` was responsible for updating `CRON_STATUS.md` and auto-recovering failed crons. The `cron-governor-report` (this cron) produces `HERMES_CRON_GOVERNANCE_REPORT.md` but does NOT update `CRON_STATUS.md`. This leaves `CRON_STATUS.md` orphaned — its last update was 2026-05-31T07:13:03Z (~32h ago). Either the governance report should absorb CRON_STATUS.md maintenance, or a separate cron should handle it.

The `knowledge-import` pause means PostgreSQL knowledge tables (`card_deck_profiles`, `theme_contextual_rules`, `analysis_sources`) are not receiving updates. `knowledge-synthesis` (10a59b3bdf4d) continues to run and generate tasks, but the import pipeline to PostgreSQL is severed.

#### Paused with 429 Error — OpenRouter (2)

| Job ID | Name | Schedule | Last Run | Last Error |
|:---|---:|:---|:---|:---|
| `aeaeb666d377` | manaloom-hermes-weekly-parallel-audit | 0 12 * * 0 | 2026-05-31T12:00Z | 429 |
| `bb03201b8911` | manaloom-code-structure-auditor (3h) | every 180m | 2026-05-31T14:23Z | 429 |

#### Paused but Was OK (2)

| Job ID | Name | Provider | Schedule | Paused At | Last Status |
|:---|---:|:---|:---|:---|:---:|
| `757eefb8738b` | manaloom-master-watchdog | (script) | every 30m | 2026-05-31T15:58Z | ok |
| `577a0a669714` | manaloom-code-structure-auditor (weekly) | openrouter | 0 6 * * 0 | 2026-05-31T15:58Z | ok |

---

## 2. Recovery Progress (Since Previous Report ~13:30Z)

### Crons Recovered (Paused to Enabled): 6

| Cron | Previous State | Current State | Migration |
|:-----|:---|:---|:---|
| `manaloom-hermes-normal-audit` | Paused, openrouter, 429 error | **Enabled, deepseek-v4-pro, OK** | Provider + schedule changed |
| `manaloom-commander-knowledge-deep` | Paused, openrouter, 429 error | **Enabled, deepseek-v4-pro, OK** | Provider changed |
| `manaloom-gamechanger-research` | Paused, openrouter, 429 error | **Enabled, deepseek-v4-pro, OK** | Provider changed |
| `manaloom-tag-accuracy-reporter` | Paused, openrouter, 429 error | **Enabled, deepseek-v4-pro, OK** | Provider changed |
| `manaloom-mana-base-validator` | Paused, openrouter, 429 error | **Enabled, deepseek-v4-pro, OK** | Provider changed |
| `mtg-rules-auditor` | Paused, deepseek-v4-pro, was OK | **Enabled, deepseek-v4-pro, OK** | Simply resumed |

**Total recovery:** 12 paused to 6 paused (-50%). All 6 recovered crons are running without errors.

---

## 3. Provider / Model Distribution

| Provider | Model | Count | Status |
|:---|:---|---:|:---|
| opencode-go | deepseek-v4-pro | 17 | All enabled, ALL OK |
| openrouter | owl-alpha | 2 | Paused with 429 errors |
| openrouter | owl-alpha | 1 | Paused, was OK |
| (none) | (script) | 1 | Paused, was OK |
| opencode-go | deepseek-v4-pro | 2 | Paused intentionally |

**Observation:** The openrouter bifurcation is effectively resolved. Only 2 openrouter crons remain with 429 errors. One openrouter cron was OK when paused and can be migrated trivially.

---

## 4. Schedule Changes and Governance Policy Compliance

### Governance Policy vs Actual Schedules

| Cron | Policy Frequency | Actual Frequency | Compliance |
|:-----|:---|:---|:---:|
| lorehold-deck-scout | every 180m | **every 90m** | NO - 2x too fast |
| lorehold-deck-validator | every 180m | **every 90m** | NO - 2x too fast |
| lorehold-mulligan-analyst | every 180m | **every 90m** | NO - 2x too fast |
| lorehold-evolution-oracle | every 240m | **every 120m** | NO - 2x too fast |
| manaloom-knowledge-synthesis | every 240m | **every 120m** | NO - 2x too fast |
| lorehold-wincon-hunter | every 360m | every 180m | NO - 2x too fast |
| lorehold-wincon-tester | every 360m | every 180m | NO - 2x too fast |
| lorehold-wincon-builder | every 360m | every 180m | NO - 2x too fast |
| lorehold-deckbuilding-methodology | every 360m | every 180m | NO - 2x too fast |
| manaloom-hermes-normal-audit | every 360m | **every 120m** | NO - 3x too fast |
| manaloom-tag-accuracy-reporter | every 1440m (daily) | every 120m | NO - 12x too fast |
| manaloom-mana-base-validator | every 360m | every 180m | NO - 2x too fast |
| manaloom-commander-knowledge-deep | every 240m | every 180m | Slightly fast |
| manaloom-gamechanger-research | every 120m | every 180m | Slower than policy |
| manaloom-logic-coherence-auditor | every 120m | every 180m | Slower than policy |
| mtg-rules-auditor | - (new) | every 180m | N/A |
| manaloom-cron-governor-report | every 720m | every 360m | 2x too fast |

**Assessment:** 12 of 17 enabled crons run more frequently than the governance policy allows. Worst offenders: `tag-accuracy-reporter` (12x policy rate), `hermes-normal-audit` (3x policy rate). Lorehold learning crons are uniformly at 2x policy frequency.

**Risk:** Higher frequency means more API calls to opencode-go, increasing rate limit risk. However, all 17 crons are currently healthy with zero errors, suggesting opencode-go can handle the current load.

---

## 5. CRON_STATUS.md — Orphaned Dashboard

**Last update:** 2026-05-31T07:13:03Z (commit `299d2e57`) — by the now-paused `manager-watchdog`.

**Content staleness:**
- Reports 18 crons (actual: 23)
- Reports 16 OK, 2 error (actual: 17 OK, 0 error among enabled)
- Reports "rate limit recovering" (actual: resolved for deepseek-v4-pro)
- Missing 5 new crons and the removal of lorehold-battle-analyst
- Missing all schedule changes

**Impact:** The primary operational dashboard for cron health is frozen. The fleet's dramatic improvement (12 to 0 errors among enabled crons) is invisible in CRON_STATUS.md.

**Recommendation:** Either this cron-governor-report should absorb CRON_STATUS.md maintenance, or a lightweight script-based cron should update it from jobs.json without needing an LLM call.

---

## 6. Worktree and Repository Risks

| Risk | Status | Detail |
|:-----|:------|:------|
| Shared branch contention | **Active** | All crons write to `codex/hermes-analysis-docs`. 17 enabled crons = high concurrent write risk. |
| Worktree dirty artifacts | **Present** | `MULLIGAN_LOG.md` (2 files), `knowledge.db` modified. Cron artifacts, not product drift. |
| STRUCTURE_AUDIT.md bloat | **Critical** | 24,710 lines, 1.5MB. Exceeds patch/write_file tool guard. No cron currently writes to it (both structure auditors paused), but bloat remains. |
| SQLite concurrency | **Active** | `knowledge.db` shared by multiple crons. No WAL mode observed. Risk of `SQLITE_BUSY`. |
| Orphan output dir | **Cosmetic** | `4430f8384ce4` - 1 file from 2026-05-27, no corresponding job. |

---

## 7. Duplicate Work Assessment

| Pattern | Crons | Risk | Recommendation |
|:---|:---|:---|:---|
| Two `code-structure-auditor` crons | weekly + 3h | **Medium** - both paused. Overlapping purpose. | Migrate weekly to deepseek-v4-pro, deprecate 3h. |
| `hermes-normal-audit` vs `hermes-weekly-parallel-audit` | 120m vs weekly | **Medium** - normal-audit at 120m is 3x policy rate. Weekly does deep parallel audits. | Slow normal-audit to 360m per policy. Migrate weekly to deepseek-v4-pro. |
| Wincon pipeline (hunter/tester/builder) | 3 crons at 180m | **Low** - intentionally chained but all run within ~10min window. | Stagger by 60m to reduce peak load. |
| Knowledge synthesis + import | synthesis runs, import paused | **Gap** - synthesis produces tasks that can't reach PostgreSQL. | Either resume import or have synthesis write directly. |

---

## 8. Learning Artifacts Actionable for Product Work

| Artifact | Source Cron | Product Relevance |
|:---|:---|---|
| `card_rulings` usage in quality gates | knowledge-synthesis | P1 - 77K rulings in PostgreSQL, use for swap validation in optimizer |
| Synergy-axis awareness beyond role equality | knowledge-synthesis | P1 - optimizer only checks role overlap, not synergy depth |
| MDFC/split-name dedup in deck validation | knowledge-synthesis | P2 - app/backend don't detect duplicate cards across faces |
| Wincon diversity (fast/resilient/stealth) | evolution-oracle, wincon-hunter | P2 - could inform deck scoring UX |
| Mulligan % as deck quality signal | mulligan-analyst | P2 - measurable signal for "deck health" UX metric |
| Tag accuracy gaps (payoff 35.5%, enabler 50%, engine 75%) | tag-accuracy-reporter | P1 - 4 code tasks already generated in commit `48d795cc` |
| Game Changer 10 gaps | gamechanger-research | P1 - documented in commit `41a746a2` |
| Lorehold pipeline integrity alerts | evolution-oracle | P2 - defensive swap detection improves optimizer safety |

---

## 9. Recommendations

### P0 - Critical Gaps

| # | Action | Evidence | Risk If Not Done | Safe to Automate? |
|:---|:---|---|:---|:---:|
| R1 | Restore CRON_STATUS.md maintenance | No cron updates it since manager-watchdog paused 32h ago. Dashboard frozen. | Fleet health invisible. Recovery events untracked. | Yes - this cron-governor can absorb the task, or a script-based cron can read jobs.json directly. |
| R2 | Resolve knowledge-import blockage | Paused with reason `blocked_until_secret_safe_import_flow_exists`. PostgreSQL knowledge tables not updated for 32h. | Knowledge synthesis produces tasks that can't reach PostgreSQL. Pipeline severed. | Investigate first - the pause reason suggests a known security concern. |

### P1 - Restore Paused Audits

| # | Action | Evidence | Risk If Not Done | Safe to Automate? |
|:---|:---|---|:---|:---:|
| R3 | Migrate `hermes-weekly-parallel-audit` to deepseek-v4-pro and resume | Only remaining weekly deep audit. Last completed run 2026-05-30 (OK). Openrouter. | Weekly comprehensive audit gap. | Yes - same migration pattern applied successfully to 6 other crons. |
| R4 | Migrate `code-structure-auditor` (weekly) to deepseek-v4-pro and resume | Was OK when paused. Produces valuable structure reports. Openrouter. | Structure drift undetected. | Yes - trivial migration (was already OK). |
| R5 | Decide fate of `code-structure-auditor` (3h) | Duplicate of weekly. Both paused. 429 error on openrouter. | Resource waste if both run. | Evaluate: deprecate 3h, keep weekly (or vice versa). |

### P2 - Fleet Hygiene

| # | Action | Evidence | Risk If Not Done | Safe to Automate? |
|:---|:---|---|:---|:---:|
| R6 | Align schedules with governance policy | 12/17 crons exceed policy frequency. `tag-accuracy-reporter` at 12x policy rate. | Rate limit risk on opencode-go. Violates documented policy. | Yes - `cronjob(action='update', schedule=...)`. PROPOSED ONLY. |
| R7 | Resume `master-watchdog` (script-based) | Paused despite OK status. Monitors `origin/master` for product changes. No LLM cost. | Product drift on master undetected by script-based watchdog. | Yes - `cronjob(action='resume')`. |
| R8 | Stagger wincon pipeline crons | hunter, tester, builder all at 180m, all run within ~10min window. | Peak load spike on opencode-go every 180m. | Yes - offset schedules by 60m each. |
| R9 | Trim STRUCTURE_AUDIT.md | 24,710 lines, 1.5MB. Blocks patch/write_file tools. | Future structure audit runs can't write results. | Manual trim needed (keep last 3 rounds). |
| R10 | Enable SQLite WAL mode on knowledge.db | Multiple concurrent read/write crons. No WAL observed. | `SQLITE_BUSY` under concurrent access. | Yes - `PRAGMA journal_mode=WAL;`. |
| R11 | Clean up orphan output dir `4430f8384ce4` | Single file from 2026-05-27, no job. | Clutter only. | Yes - `rm -rf`. |

### P3 - Policy Alignment

| # | Action | Evidence | Risk If Not Done | Safe to Automate? |
|:---|:---|---|:---|:---:|
| R12 | Update `HERMES_KNOWLEDGE_PIPELINE_GOVERNANCE.md` | Schedule table doesn't reflect actual frequencies. New crons not listed. Battle-analyst removed but still in policy. | Policy doc drifts from reality. | Yes - update the frequency table. |
| R13 | Document cron-governor-report's scope | This cron superseded manager-watchdog but doesn't cover CRON_STATUS.md. Scope boundary unclear. | Duplicate effort or gaps in coverage. | Document in governance policy. |

---

## 10. Migration Plan for Remaining Paused Crons

**PROPOSED ONLY - do not execute from this governance report:**

| Cron | Action | Safe to Automate? |
|:---|---|:---:|
| `aeaeb666d377` - hermes-weekly-parallel-audit | Migrate to deepseek-v4-pro + resume | Yes |
| `577a0a669714` - code-structure-auditor (weekly) | Migrate to deepseek-v4-pro + resume | Yes |
| `bb03201b8911` - code-structure-auditor (3h) | Consider deprecation (duplicate of weekly) | Evaluate first |
| `757eefb8738b` - master-watchdog | Resume (script-based, no LLM cost, was OK) | Yes |
| `2d436c71bbf7` - manager-watchdog | Keep paused (intentionally superseded). Ensure CRON_STATUS.md gap is filled. | N/A |
| `b2f5c21ce2d7` - knowledge-import | Investigate security concern, then resume or replace with direct write from synthesis. | Investigate first |

**Rollout strategy:**
1. Resume `master-watchdog` (R7) - zero cost, immediate benefit
2. Migrate + resume `code-structure-auditor` weekly (R4) - was OK, easy win
3. Migrate + resume `hermes-weekly-parallel-audit` (R3) - fills weekly audit gap
4. Restore CRON_STATUS.md maintenance (R1) - prevents dashboard rot
5. Align schedules with governance policy (R6) - prevents future rate limits

---

## 11. Current Git State

- **Branch:** `codex/hermes-analysis-docs` - up to date with origin (`41a746a2`).
- **Worktree:** Modified cron artifacts only (MULLIGAN_LOG.md x2, knowledge.db). No product code changes.
- **Recent commits (last 5):**
  - `41a746a2` - gamechanger research report (10 gaps)
  - `8c212256` - MTG rules compliance report v3.1
  - `12a01046` - PostgreSQL tables-not-used audit
  - `08f02473` - commander deep knowledge report
  - `48d795cc` - synthesis: cross-reference TAG_ACCURACY_REPORT with code (4 tasks)
- **Output disk usage:** 34MB total across all cron output directories.

---

*Report produced by `manaloom-cron-governor-report` (21fa86eb0d84) - second execution.*
*Previous report: 2026-06-01T13:30Z. This report: 2026-06-01T15:30Z (approx).*
*Next scheduled run: ~2026-06-01T21:27Z (360m interval).*
