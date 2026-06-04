# Hermes Cron Governance Report

> Generated: 2026-06-04T00:15Z (approx)
> Cron: manaloom-cron-governor-report (21fa86eb0d84) — third execution
> Workdir: /opt/data/workspace/mtgia | Branch: codex/hermes-analysis-docs | HEAD: 42c6325c

## Executive Summary

**Fleet state: 22 crons total — 18 enabled (4 with errors), 4 paused (all intentional).**

Since the last report (2026-06-01), the fleet contracted from 23 to 22 crons (removal of lorehold-battle-analyst and the code-structure-auditor 3h duplicate). The manaloom-knowledge-import cron was re-enabled but runs in DRY RUN mode (no actual PostgreSQL writes). All crons now use opencode-go/deepseek-v4-pro — the openrouter bifurcation is fully resolved.

**New risk: opencode-go weekly quota hit.** On 2026-06-03 at ~18:14-18:22Z, three crons simultaneously failed with HTTP 429: Weekly usage limit reached. Resets in 4 days. This is a hard quota exhaustion on the deepseek-v4-pro workspace, not a transient rate limit. Crons running after 20:24Z succeeded, suggesting either quota reset or separate quota buckets. The 3 affected crons will retry on their next scheduled ticks (starting ~00:14Z June 4).

**CRON_STATUS.md is ~3 days stale** (last update 2026-06-01T16:46Z). No cron currently maintains it.

**Schedule compliance improved dramatically:** Most crons now align with governance policy. The major remaining outlier is lorehold-evolution-oracle at 60m (policy: 240m, 4x too fast).

---

## 1. Fleet Inventory

### 1.1 Enabled Crons (18) — All opencode-go/deepseek-v4-pro

| ID | Name | Schedule | Last Run | Status |
|:---|---:|:---|:---|:---:|
| 757eefb8738b | manaloom-master-watchdog | every 30m | 2026-06-04T00:07Z | OK |
| a50bef4c2a59 | lorehold-evolution-oracle | every 60m WARN | 2026-06-03T23:37Z | OK |
| b2f5c21ce2d7 | manaloom-knowledge-import | every 120m | 2026-06-03T22:42Z | OK |
| 712579b15767 | lorehold-deck-validator | every 180m | 2026-06-03T22:42Z | OK |
| c0591cb18024 | mtg-rules-auditor | every 180m | 2026-06-03T22:35Z | OK |
| de6fb777f5d1 | manaloom-logic-coherence-auditor | every 180m | 2026-06-03T22:28Z | OK |
| 08468451a06a | lorehold-mulligan-analyst | every 180m | 2026-06-03T21:51Z | OK |
| f20ac299992b | lorehold-deck-scout | every 180m | 2026-06-03T21:43Z | OK |
| 7915cc2377a0 | manaloom-gamechanger-research | every 180m | 2026-06-03T21:36Z | OK |
| 75eed994c103 | manaloom-commander-knowledge-deep | every 180m | 2026-06-03T21:33Z | OK |
| b340374bc4e7 | manaloom-tag-accuracy-reporter | every 1440m | 2026-06-03T20:57Z | OK |
| 10a59b3bdf4d | manaloom-knowledge-synthesis | every 240m | 2026-06-03T20:24Z | OK |
| 4b2a79809aed | lorehold-deckbuilding-methodology | every 360m | 2026-06-03T18:22Z | ERROR |
| 444aa9510c2c | manaloom-mana-base-validator | every 360m | 2026-06-03T18:18Z | ERROR |
| 660397bb97e1 | manaloom-hermes-normal-audit | every 360m | 2026-06-03T18:14Z | ERROR |
| 577a0a669714 | manaloom-code-structure-auditor | 0 6 * * 0 | 2026-05-31T06:37Z | OK |
| aeaeb666d377 | manaloom-hermes-weekly-parallel-audit | 0 12 * * 0 | 2026-05-31T12:00Z | ERROR |
| 21fa86eb0d84 | manaloom-cron-governor-report | every 720m | 2026-06-01T15:36Z | OK |

All enabled crons have next_run_at in the future. The 3 batch-error crons retry at ~00:14-00:22Z June 4. Weekly-parallel-audit retries Sunday June 7.

### 1.2 Paused Crons (4) — All Intentional

| ID | Name | Reason | Last Status |
|:---|---:|:---|:---:|
| 2d436c71bbf7 | manaloom-manager-watchdog | superseded_by_report_only_cron_governor | error |
| 11780da0894a | lorehold-wincon-hunter | Pipeline hardening needed | ok |
| 8ea24b001c86 | lorehold-wincon-tester | Pipeline hardening needed | ok |
| 8ede9aa84b4d | lorehold-wincon-builder | Pipeline hardening needed | ok |

All 4 pauses are intentional and architecturally sound.

---

## 2. Error Analysis — 4 Crons with last_status=error

### 2.1 Batch Error: opencode-go Weekly Quota Exhaustion (3 crons)

On 2026-06-03 between 18:14Z and 18:22Z, three crons failed simultaneously:

| Cron | ID | Failed At | Error |
|:-----|:---|:---|:---|
| manaloom-hermes-normal-audit | 660397bb97e1 | 18:14Z | HTTP 429: Weekly usage limit reached. Resets in 4 days. |
| manaloom-mana-base-validator | 444aa9510c2c | 18:18Z | HTTP 429: Weekly usage limit reached. Resets in 4 days. |
| lorehold-deckbuilding-methodology | 4b2a79809aed | 18:22Z | HTTP 429: Weekly usage limit reached. Resets in 4 days. |

**Root cause:** opencode-go/deepseek-v4-pro workspace (wrk_01KT01X25BK8XMN65MH8SD1JYS) exhausted weekly quota. "Resets in 4 days" from June 3 = ~June 7.

**Paradox:** 10 crons ran successfully AFTER 18:22Z (20:24Z through 00:07Z), all same provider/model. Suggests quota reset, different buckets, or lighter subsequent crons stayed under threshold.

**Next retry:** hermes-normal-audit ~00:14Z, mana-base-validator ~00:18Z, deckbuilding-methodology ~00:22Z (all imminent).

### 2.2 Isolated Error: weekly-parallel-audit

| Cron | ID | Failed At | Error |
|:-----|:---|:---|:---|
| manaloom-hermes-weekly-parallel-audit | aeaeb666d377 | 2026-05-31T12:00Z | HTTP 429: free-models-per-day-stealth |

Different 429 variant. Next retry: Sunday 2026-06-07T12:00Z. Do not trigger manually.

### 2.3 Error Trend

| Report Date | Enabled | OK | Error | Notes |
|:---|:---:|:---:|:---:|:---|
| 2026-06-01 (R1) | 17 | 17 | 0 | Post-migration clean |
| 2026-06-01 (R2) | 17 | 17 | 0 | Sustained clean |
| 2026-06-04 (R3) | 18 | 14 | 4 | Weekly quota wave |

---

## 3. Provider / Model Distribution

| Provider | Model | Count | Status |
|:---|:---|---:|:---|
| opencode-go | deepseek-v4-pro | 22 | 18 enabled (4 error, 14 OK), 4 paused |

**Single-provider risk:** 100% of fleet on one provider/model. Previous openrouter redundancy removed. All LLM crons stall if opencode-go has outage or quota exhaustion.

---

## 4. Schedule Compliance vs Governance Policy

| Cron | Policy | Actual | Compliance |
|:-----|:---|:---|:---:|
| lorehold-deck-scout | 180m | 180m | OK |
| lorehold-deck-validator | 180m | 180m | OK |
| lorehold-mulligan-analyst | 180m | 180m | OK |
| lorehold-evolution-oracle | 240m | 60m | FAIL 4x |
| manaloom-knowledge-synthesis | 240m | 240m | OK |
| lorehold-deckbuilding-methodology | 360m | 360m | OK |
| manaloom-hermes-normal-audit | 360m | 360m | OK |
| manaloom-tag-accuracy-reporter | 1440m | 1440m | OK |
| manaloom-mana-base-validator | 360m | 360m | OK |
| manaloom-cron-governor-report | 720m | 720m | OK |
| manaloom-commander-knowledge-deep | 240m | 180m | slightly fast |
| manaloom-gamechanger-research | 120m | 180m | slower (safe) |
| manaloom-logic-coherence-auditor | 120m | 180m | slower (safe) |
| mtg-rules-auditor | not in policy | 180m | undocumented |

**Assessment:** 11/15 (73%) compliant, up from 5/17 (29%) in R2. Only clear violation: evolution-oracle at 4x policy (~24 calls/day).

---

## 5. CRON_STATUS.md — Orphaned Dashboard (3 Days Stale)

Last update: 2026-06-01T16:46:31Z (manual). No cron maintains it.

Key discrepancies from reality:
- Reports 23 crons (actual: 22), 20 enabled (actual: 18)
- Reports lorehold-battle-analyst and code-structure-auditor 3h present (both removed)
- Reports knowledge-import paused (actual: enabled, DRY RUN)
- Reports rate limit recovery (actual: new quota event June 3)
- Schedule table outdated (evolution-oracle listed as 240m, actual 60m)

**Gap:** Flagged P0 in last report 3 days ago. Still unresolved.

---

## 6. Worktree and Repository Risks

| Risk | Status |
|:-----|:------|
| Shared branch contention (18 crons writing) | Active |
| Worktree dirty artifacts | Clean |
| STRUCTURE_AUDIT.md bloat (27,253 lines) | Critical — growing ~800/day |
| SQLite concurrency | Resolved (WAL mode) |
| Orphan output dir | Resolved |
| Root-owned untracked files | Resolved |

---

## 5. CRON_STATUS.md — Orphaned Dashboard (3 Days Stale)

Last update: 2026-06-01T16:46:31Z (manual). No cron maintains it.

Key discrepancies from reality:
- Reports 23 crons (actual: 22), 20 enabled (actual: 18)
- Reports lorehold-battle-analyst and code-structure-auditor 3h present (both removed)
- Reports knowledge-import paused (actual: enabled, DRY RUN)
- Reports rate limit recovery (actual: new quota event June 3)
- Schedule table outdated (evolution-oracle listed as 240m, actual 60m)

**Gap:** Flagged P0 in last report 3 days ago. Still unresolved.
---

## 6. Worktree and Repository Risks

| Risk | Status |
|:-----|:------|
| Shared branch contention (18 crons writing) | Active |
| Worktree dirty artifacts | Clean |
| STRUCTURE_AUDIT.md bloat (27,253 lines) | Critical - growing ~800/day |
| SQLite concurrency | Resolved (WAL mode) |
| Orphan output dir | Resolved |
| Root-owned untracked files | Resolved |

---

## 7. Duplicate Work Assessment

| Pattern | Status |
|:---|:---|
| code-structure-auditor duplicate (weekly + 3h) | Resolved - 3h removed |
| hermes-normal-audit vs weekly-parallel-audit | Low risk - normal at 360m, weekly on Sundays |
| Wincon pipeline | N/A - all paused |
| Knowledge synthesis + import | Gap - import DRY RUN, no PG writes |
| commander-knowledge-deep vs mtg-rules-auditor | Medium - same skill, different crons |
---

## 8. Learning Artifacts Actionable for Product Work

| Artifact | Relevance | Status |
|:---|:---|:---|
| Tag accuracy gaps (payoff 35.5%, 7 tags below 85%) | P1 - 4 code tasks, CMC corruption, 7-day stagnation | Stagnation since May 27 |
| card_rulings in quality gates (77K rulings) | P1 - swap validation | Not integrated |
| Synergy-axis awareness | P1 - optimizer role overlap only | Not implemented |
| Mulligan percent as deck quality signal | P2 - UX metric | Not integrated |
| Wincon diversity (fast/resilient/stealth) | P2 - deck scoring | Pipeline paused |
| MDFC/split-name dedup | P2 - duplicate detection | Not implemented |
| Game Changer 10 gaps | P1 - documented | Research ongoing |
---

## 9. Recommendations

### P0 - Critical Gaps

| # | Action | Evidence | Safe to Automate? |
|:---|:---|---|:---:|
| R1 | Restore CRON_STATUS.md maintenance | Dashboard frozen 3 days. Flagged P0 in last report. | Yes - add to this reports output or create script-based cron. |
| R2 | Investigate opencode-go weekly quota pattern | 3 crons 429 Weekly limit at 18:14-18:22Z, but 10 crons OK afterwards. Inconsistent. | No - manual investigation of workspace quota/billing. |

### P1 - Fleet Health

| # | Action | Evidence | Safe to Automate? |
|:---|:---|---|:---:|
| R3 | Slow lorehold-evolution-oracle to 240m | 60m (4x policy). ~24 calls/day. Major quota contributor. | Yes - PROPOSED ONLY. |
| R4 | Resolve knowledge-import DRY RUN mode | 120m runs, no PG writes, card_deck_profiles frozen at 7710. | Investigate first - security concern may still apply. |
| R5 | Monitor weekly-parallel-audit recovery | Failed May 31 429 on first post-migration run. Retry June 7. | Monitor - do not trigger manually. |

### P2 - Fleet Hygiene

| # | Action | Evidence | Safe to Automate? |
|:---|:---|---|:---:|
| R6 | Trim STRUCTURE_AUDIT.md | 27,253 lines, growing ~800/day. Blocks write tools. | Manual trim (keep last 3 rounds). |
| R7 | Document mtg-rules-auditor in governance policy | Not in policy. Uses same skill as commander-knowledge-deep. | Yes - update governance doc. |
| R8 | Evaluate single-provider risk | 100% of fleet on one provider. No fallback. | Strategic - consider 1-2 crons on alternate provider as canary. |
| R9 | Update governance policy schedule table | Evolution-oracle still at wrong frequency in doc. | Yes. |

### P3 - Documentation

| # | Action | Safe to Automate? |
|:---|:---|---|
| R10 | Document cron-governor-report scope boundary | Yes |
| R11 | Recognize fleet reduction (23->22) in CRON_STATUS.md | Yes |
---

## 10. Previous Recommendations - Status Tracking

| # | Recommendation (from R1/R2) | Status |
|:---|:---|:---|
| R1 | Restore CRON_STATUS.md maintenance | STILL OPEN (3 days) |
| R2 | Resolve knowledge-import blockage | CHANGED - enabled but DRY RUN |
| R3 | Migrate weekly-parallel-audit to deepseek | DONE - errored on first run |
| R4 | Migrate code-structure-auditor weekly | DONE - OK on May 31 |
| R5 | Deprecate code-structure-auditor 3h | DONE - removed |
| R6 | Align schedules with policy | PARTIALLY - 11/15 compliant |
| R7 | Resume master-watchdog | DONE - running OK |
| R8 | Stagger wincon pipeline | N/A - all paused |
| R9 | Trim STRUCTURE_AUDIT.md | NOT DONE - grew 2,500 lines |
| R10 | Enable SQLite WAL mode | DONE |
| R11 | Clean orphan output dir | DONE |

**Completion:** 5/11 done, 2 partially done, 2 open, 2 N/A.
---

## 11. Cron-Governor-Report Self-Check

| Metric | Value |
|:---|---|
| Schedule | every 720m (12h) |
| Last execution | 2026-06-01T15:36Z (~2.5 days ago) |
| Expected next run | ~June 2 03:36Z (missed) |
| Actual next_run_at | 2026-06-04T12:10Z |
| Missed cycles | ~5 |
| Current execution | 2026-06-04T00:15Z |

WARNING: ~69h gap between last_run_at and expected next_run. Investigation recommended.
---

## 12. Current Git State

- **Branch:** codex/hermes-analysis-docs - ahead 2 of origin.
- **Worktree:** Clean.
- **Recent commits:** 42c6325c Merge, 4c8a6a49 auto-commit, dbb5f430 structure audit, 534f5672 MTG rules v3.3, 9d740b4a commander knowledge.
- **Output disk:** ~34MB.

---

*Report: manaloom-cron-governor-report (21fa86eb0d84) - third execution, 2026-06-04T00:15Z.*
*Fleet: 22 crons (18 enabled, 4 paused) - 14 OK, 4 error (429 quota), 4 paused.*
*Previous report: 2026-06-01T15:30Z. This report: 2026-06-04T00:15Z.*