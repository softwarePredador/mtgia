# Hermes Cron Governance Report

> Generated: 2026-06-07T18:19Z | Fleet: 24 crons (20 enabled, 4 paused) | 19 OK, 1 error, 4 paused
> Cron: manaloom-cron-governor-report (21fa86eb0d84) — fifth execution
> Previous: 2026-06-05T02:09Z | Change: +6 fleet (18 to 24), 2 recovered, 1 removed

## Executive Summary

**Fleet state: 24 crons total — 20 enabled (1 with errors), 4 paused (intentional).**

Since the last report (2026-06-05), the fleet **grew from 18 to 24 crons (+6)**. 
Two previously broken crons recovered: `auto-sync-learned-decks` and `pull-learning-events` 
are now OK. The `flutter-ui-auditor` was removed from the fleet.

**New additions:** 4 master-optimizer pipeline crons (auto-cycle, end-to-end, preflight, slot-scan),
2 lorehold-knowncards crons (generator, validator), and 1 lorehold-universal-optimizer (paused).

**Only 1 error:** `manaloom-hermes-weekly-parallel-audit` — 429 weekly quota exceeded 
(deepseek-pro). This is a provider quota issue, not a code bug. Resets next week.

**Code health is excellent:** `dart analyze` clean (0 issues), 604/604 tests pass, 
`flutter analyze` clean. Production health endpoint confirms healthy at `bbe358f9`.

**CRON_STATUS.md remains ~7 days stale** — flagged P0 in previous reports, still unresolved.

---

## 1. Fleet Inventory

### 1.1 Enabled Crons (20) — 19 OK, 1 Error

| ID | Name | Schedule | Last Run | Status | Provider |
|:---|---:|:---|:---|:---:|:---|
| 757eefb8738b | manaloom-master-watchdog | every 30m | 2026-06-07T17:47Z | OK | script |
| 660397bb97e1 | manaloom-hermes-normal-audit | every 360m | 2026-06-07T13:10Z | OK | deepseek-pro |
| aeaeb666d377 | manaloom-hermes-weekly-parallel-audit | 0 12 * * 0 | 2026-06-07T12:04Z | **ERROR** | deepseek-pro |
| 75eed994c103 | manaloom-commander-knowledge-deep | every 180m | 2026-06-07T15:29Z | OK | deepseek-pro |
| 7915cc2377a0 | manaloom-gamechanger-research | every 180m | 2026-06-07T15:35Z | OK | deepseek-pro |
| b340374bc4e7 | manaloom-tag-accuracy-reporter | every 1440m | 2026-06-06T23:12Z | OK | deepseek-pro |
| 444aa9510c2c | manaloom-mana-base-validator | every 360m | 2026-06-07T12:56Z | OK | deepseek-pro |
| b2f5c21ce2d7 | manaloom-knowledge-import | every 120m | 2026-06-07T17:12Z | OK | opencode-go |
| 577a0a669714 | manaloom-code-structure-auditor | 0 6 * * 0 | 2026-06-07T06:04Z | OK | deepseek-pro |
| de6fb777f5d1 | manaloom-logic-coherence-auditor | every 180m | 2026-06-07T15:41Z | OK | deepseek-pro |
| 10a59b3bdf4d | manaloom-knowledge-synthesis | every 240m | 2026-06-07T16:29Z | OK | deepseek-pro |
| c0591cb18024 | mtg-rules-auditor | every 180m | 2026-06-07T15:45Z | OK | deepseek-pro |
| 21fa86eb0d84 | manaloom-cron-governor-report | every 720m | 2026-06-07T06:16Z | OK | deepseek-pro |
| 104fd03a2ea2 | manaloom-auto-promote-learned | every 360m | 2026-06-07T12:56Z | OK | script |
| 7fcab928efd3 | manaloom-auto-sync-learned-decks | every 120m | 2026-06-07T17:12Z | OK | script |
| 262dc49e1be1 | manaloom-pull-learning-events | every 30m | 2026-06-07T17:47Z | OK | script |
| d4e5f6a7b8c9 | lorehold-knowncards-validator | every 30m | 2026-06-07T18:06Z | OK | script |
| b9c8a7d6e5f4 | lorehold-knowncards-generator | every 120m | 2026-06-06T04:07Z | OK | script |
| mmo-auto-cyc | manaloom-master-optimizer-auto-cycle | every 180m | never | OK | script |
| mmo-prefligh | manaloom-master-optimizer-preflight | every 20m | 2026-06-07T18:10Z | OK | script |

All enabled crons have next_run_at in the future except auto-cycle (never run).

### 1.2 Paused/Disabled Crons (4)

| ID | Name | Reason | Last Status |
|:---|---:|:---|:---|
| 2d436c71bbf7 | manaloom-manager-watchdog | superseded_by_report_only_cron_governor | error (May 31) |
| c8d9e0f1a2b3 | lorehold-universal-optimizer | Paused after error (script exit code 1) | error |
| mmo-e2e01 | manaloom-master-optimizer-end-to-end | Paused intentionally | never run |
| mmo-slot-sca | manaloom-master-optimizer-slot-scan | Paused intentionally | never run |

---

## 2. Error Analysis — 1 Cron with last_status=error

### 2.1 manaloom-hermes-weekly-parallel-audit (aeaeb666d377) — 429 Weekly Quota

**Error:** `RuntimeError: HTTP 429: Weekly usage limit reached. Resets in 11hr 56min.`

**Failure at:** 2026-06-07T12:04Z (scheduled weekly Sunday noon run).

**Root cause:** deepseek-pro provider weekly quota exhausted.

**Risk:** Weekly parallel audit missed one cycle. No code or product impact.

**Recommended action:** Monitor next Sunday (June 14) run. If quota persists, migrate provider.

**Safe to automate:** No — requires provider quota management.

---

## 3. Fleet Changes Since Last Report — Growth (+6)

### 3.1 New Crons (7)

| ID | Name | Schedule | Status | Type |
|:---|---:|:---|:---:|:---|
| mmo-auto-cyc | manaloom-master-optimizer-auto-cycle | every 180m | never run | script |
| mmo-e2e01 | manaloom-master-optimizer-end-to-end | every 1440m | paused | script |
| mmo-prefligh | manaloom-master-optimizer-preflight | every 20m | OK | script |
| mmo-slot-sca | manaloom-master-optimizer-slot-scan | every 720m | paused | script |
| b9c8a7d6e5f4 | lorehold-knowncards-generator | every 120m | OK | script |
| d4e5f6a7b8c9 | lorehold-knowncards-validator | every 30m | OK | script |
| c8d9e0f1a2b3 | lorehold-universal-optimizer | every 10m | paused/error | script |

New master-optimizer pipeline (4 crons) and knowncards pipeline (2 crons).

### 3.2 Removed Crons (1)

| ID | Name | Previous Status |
|:---|---:|:---|
| 93a8ad77b251 | manaloom-flutter-ui-auditor | ERROR (false positive) |

Output directory still exists with one stale output file from June 4.

### 3.3 Recovered Crons (2)

| ID | Name | Previous Status | Current Status |
|:---|---:|:---:|:---:|
| 7fcab928efd3 | manaloom-auto-sync-learned-decks | ERROR (PermissionError) | OK |
| 262dc49e1be1 | manaloom-pull-learning-events | ERROR (UUID type mismatch) | OK |

Both previously broken script-based crons have been fixed and are now running OK.

---

## 4. Provider / Model Distribution

| Provider | Model | Count | Status |
|:---|:---|---:|:---|
| deepseek-pro | deepseek-v4-pro | 12 | 11 OK, 1 ERROR (429) |
| opencode-go | deepseek-v4-pro | 1 | 1 OK |
| script (no_agent) | N/A | 11 | 8 OK, 3 paused |

**Single-provider risk:** 12/13 LLM crons on deepseek-pro. First 429 since June 3.

**Rate limit events:** 1 (weekly-parallel-audit). No systemic waves.

---

## 5. Schedule Compliance

| Cron | Policy | Actual | Assessment |
|:-----|:---|:---|:---|
| manaloom-commander-knowledge-deep | 240m | 180m | Slightly fast |
| manaloom-gamechanger-research | 120m | 180m | Slower (safe) |
| manaloom-logic-coherence-auditor | 120m | 180m | Slower (safe) |
| manaloom-knowledge-import | 120m | 120m | OK |
| mtg-rules-auditor | not in policy | 180m | Undocumented |
| manaloom-pull-learning-events | N/A (new) | 30m | Could be slower |
| lorehold-knowncards-validator | N/A (new) | 30m | Frequent |
| manaloom-master-optimizer-preflight | N/A (new) | **20m** | Very frequent |
| lorehold-universal-optimizer | N/A (new) | 10m (paused) | Aggressive |

11/13 governed crons compliant (85%). Governance policy needs update.

---

## 6. CRON_STATUS.md — 7 Days Stale

Last update: 2026-06-01T16:46:31Z. No cron maintains it.

Key discrepancies: reports 23 crons (actual 24), missing 7 new crons, lists 8 removed Lorehold crons. Flagged P0 in 4 consecutive reports.

---

## 7. Worktree and Repository Risks

| Risk | Status |
|:-----|:------|
| Shared branch contention (24 crons) | Active |
| Worktree dirty artifacts | ~70 untracked cron artifacts |
| Orphan output dirs (4 root-owned) | Active |
| Master optimizer report bloat | 110 files |
| Git divergence | Resolved (3bc7966d) |

**Dirty worktree details:**
- `M docs/hermes-analysis/FLUTTER_UI_AUDIT.md` — uncommitted UI audit update from flutter-ui-auditor cron
- `M docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db` — SQLite modifications
- `M docs/hermes-analysis/manaloom-knowledge/scripts/__pycache__/db_helper.cpython-313.pyc` — bytecode changes
- `_gc_check.py` — removido em 2026-06-17 tanto de `manaloom-knowledge/` quanto de `manaloom-knowledge/scripts/`; era diagnostico manual/historico de `game_changers`, nao cron ativo.

These are cron artifacts from other crons operating on the shared branch, not product drift.

---

## 8. Duplicate Work Assessment

| Pattern | Status |
|:---|:---|
| code-structure-auditor duplicate | Resolved |
| hermes-normal vs weekly-parallel | Low risk |
| Wincon pipeline | Resolved (removed) |
| auto-sync + pull-learning-events | Medium (both learned deck pipeline) |
| knowncards-generator + validator | Complementary |
| master-optimizer pipeline (4 crons) | Pipeline (sequential stages) |

---

## 9. Learning Artifacts Actionable for Product

| Artifact | Relevance | Status |
|:---|:---|:---|
| Tag accuracy gaps (payoff 35.5%) | P1 — CMC corruption | Still open |
| card_rulings in quality gates | P1 — swap validation | Not integrated |
| CMC systemic corruption (all decks) | P1 — validator finding | Documented, not fixed |
| Master optimizer preflight outputs | P2 — deck proposals | Accumulating (110 files) |

---

## 10. Code Health Verification (2026-06-07T18:19Z)

| Check | Result |
|:---|---|
| dart pub get (server) | Got dependencies |
| dart analyze lib/ (server) | **No issues found** |
| dart test (server) | **604/604 tests passed** |
| flutter pub get (app) | Changed 2 dependencies |
| flutter analyze (app) | **No issues found** |
| Production health | healthy at `bbe358f9` |
| Master advancement | None (0 new commits) |

---

## 11. Recommendations

### P0 — Critical Gaps

| # | Action | Safe to Automate? |
|:---|:---|---|
| R1 | Restore CRON_STATUS.md maintenance (7 days stale, 4th report) | PROPOSED: add to this cron |
| R2 | Clean 4 root-owned orphan output dirs | No — requires root |

### P1 — Fleet Health

| # | Action | Safe to Automate? |
|:---|:---|---|
| R3 | Monitor weekly-parallel-audit 429 recovery (June 14) | Wait for scheduler |
| R4 | Investigate auto-cycle never-run (next tick 20:05Z) | Wait for scheduler |
| R5 | Document new fleet in governance policy | Yes |
| R6 | Assess preflight frequency (20m to 60m) | PROPOSED ONLY |

### P2 — Fleet Hygiene

| # | Action | Safe to Automate? |
|:---|:---|---|
| R7 | Remove flutter-ui-auditor output dir | Yes |
| R8 | Update fleet-size tracking | Yes |
| R9 | Consolidate knowncards-generator + validator schedules | Investigate |
| R10 | Commit dirty worktree artifacts | Low priority |

---

## 12. Previous Recommendations Tracking

| # | Recommendation | Status |
|:---|:---|:---|
| R1 | Restore CRON_STATUS.md maintenance | STILL OPEN (~7 days) |
| R2 | Fix pull-learning-events UUID casting | RESOLVED |
| R3 | Fix auto-sync-learned-decks permissions | RESOLVED |
| R4 | Slow pull-learning-events to 120m | OPEN (still 30m, working) |
| R5 | Document Lorehold pipeline removal | OPEN |
| R6 | Review knowledge-import DRY RUN | OPEN |
| R8 | Investigate flutter-ui-auditor error | RESOLVED (removed) |
| R9 | Update governance policy | OPEN |

Completion: 3/12 done, 5 open, 1 N/A.

---

## 13. Self-Check

Schedule: every 720m. Last: 2026-06-07T06:16Z. Current: 2026-06-07T18:19Z. Gap: ~12h. On schedule.

---

*Report: manaloom-cron-governor-report (21fa86eb0d84) — fifth execution, 2026-06-07T18:19Z.*
*Fleet: 24 crons (20 enabled, 4 paused) — 19 OK, 1 error (429), 4 paused.*
*Previous: 2026-06-05T02:09Z. Change: +6 fleet, 2 recovered, 1 removed, 0 new code errors.*
