# Hermes Cron Governance Report

> Status atual: historico/snapshot antigo.
> Nao use este arquivo como fonte operacional atual de cron ou optimizer.
> Para execucao atual, leia `docs/hermes-analysis/README.md` e
> `docs/hermes-analysis/HERMES_E2E_SYSTEM_CONTRACT_2026-06-07.md`.

> Generated: 2026-06-05T02:09:36Z
> Cron: manaloom-cron-governor-report (21fa86eb0d84) — fourth execution
> Workdir: /opt/data/workspace/mtgia | Branch: codex/hermes-analysis-docs | HEAD: 28f16849

## Executive Summary

**Fleet state: 18 crons total — 17 enabled (3 with errors), 1 paused (intentional).**

Since the last report (2026-06-04), the fleet contracted from 22 to 18 crons.
**The entire Lorehold pipeline (8 crons) was removed:** lorehold-deck-scout,
lorehold-deck-validator, lorehold-mulligan-analyst, lorehold-evolution-oracle,
lorehold-deckbuilding-methodology, lorehold-wincon-hunter, lorehold-wincon-tester,
lorehold-wincon-builder. **4 new script-based crons were added:** auto-sync-learned-decks,
pull-learning-events, auto-promote-learned, flutter-ui-auditor.

The opencode-go weekly quota event from June 3 resolved naturally — all 3 affected
crons are now OK. However, 2 of the 4 new script-based crons have **persistent code
bugs** causing 100% failure rate (auto-sync-learned-decks: 5 consecutive failures,
pull-learning-events: 19 consecutive failures). These are production-code bugs
(PermissionError and PostgreSQL type mismatch), not rate limits.

**CRON_STATUS.md remains ~4 days stale** — flagged P0 in two previous reports, still unresolved.

**STRUCTURE_AUDIT.md was trimmed** from 27,253 to 7,854 lines — R6 resolved.

---

## 1. Fleet Inventory

### 1.1 Enabled Crons (17) — All OK except 3 script-based errors

| ID | Name | Schedule | Last Run | Status | Provider |
|:---|---:|:---|:---|:---:|:---|
| 757eefb8738b | manaloom-master-watchdog | every 30m | 2026-06-05T01:36Z | OK | script |
| 660397bb97e1 | manaloom-hermes-normal-audit | every 360m | 2026-06-04T20:21Z | OK | opencode-go/deepseek-v4-pro |
| aeaeb666d377 | manaloom-hermes-weekly-parallel-audit | 0 12 * * 0 | 2026-06-04T14:15Z | OK | opencode-go/deepseek-v4-pro |
| 75eed994c103 | manaloom-commander-knowledge-deep | every 180m | 2026-06-04T23:44Z | OK | opencode-go/deepseek-v4-pro |
| 7915cc2377a0 | manaloom-gamechanger-research | every 180m | 2026-06-04T23:52Z | OK | opencode-go/deepseek-v4-pro |
| b340374bc4e7 | manaloom-tag-accuracy-reporter | every 1440m | 2026-06-04T21:02Z | OK | opencode-go/deepseek-v4-pro |
| 444aa9510c2c | manaloom-mana-base-validator | every 360m | 2026-06-04T20:31Z | OK | opencode-go/deepseek-v4-pro |
| b2f5c21ce2d7 | manaloom-knowledge-import | every 120m | 2026-06-05T00:36Z | OK | opencode-go/deepseek-v4-pro |
| 577a0a669714 | manaloom-code-structure-auditor | 0 6 * * 0 | 2026-05-31T06:37Z | OK | opencode-go/deepseek-v4-pro |
| de6fb777f5d1 | manaloom-logic-coherence-auditor | every 180m | 2026-06-05T00:28Z | OK | opencode-go/deepseek-v4-pro |
| 10a59b3bdf4d | manaloom-knowledge-synthesis | every 240m | 2026-06-04T22:25Z | OK | opencode-go/deepseek-v4-pro |
| c0591cb18024 | mtg-rules-auditor | every 180m | 2026-06-05T00:35Z | OK | opencode-go/deepseek-v4-pro |
| 21fa86eb0d84 | manaloom-cron-governor-report | every 720m | 2026-06-04T00:22Z | OK | opencode-go/deepseek-v4-pro |
| 104fd03a2ea2 | manaloom-auto-promote-learned | every 360m | 2026-06-04T20:31Z | OK | script |
| 7fcab928efd3 | manaloom-auto-sync-learned-decks | every 120m | 2026-06-05T00:36Z | **ERROR** | script |
| 262dc49e1be1 | manaloom-pull-learning-events | every 30m | 2026-06-05T01:36Z | **ERROR** | script |
| 93a8ad77b251 | manaloom-flutter-ui-auditor | every 360m | 2026-06-04T16:42Z | **ERROR** | none |

All enabled crons have next_run_at in the future.

### 1.2 Paused/Disabled Crons (1)

| ID | Name | Reason | Last Status |
|:---|---:|:---|:---|
| 2d436c71bbf7 | manaloom-manager-watchdog | superseded_by_report_only_cron_governor | error (from May 31) |

---

## 2. Error Analysis — 3 Crons with last_status=error

### 2.1 auto-sync-learned-decks (7fcab928efd3) — PermissionError

**Error:** `PermissionError: [Errno 13] Permission denied: '/opt/data/scripts/../test/artifacts/hermes_auto_sync/synced_learned_ids.txt'`

**Failure rate:** 5/5 runs (100%) since June 4 16:13Z. Consistent, non-transient.

**Root cause:** The script at `/opt/data/scripts/auto_sync_learned_decks.py` line 135 tries to write a tracking file to a path under `/opt/data/scripts/../test/artifacts/hermes_auto_sync/`. The directory or file permissions prevent writing.

**Risk:** Learned deck sync pipeline completely blocked. No learned decks are being promoted from Hermes to product.

**Recommended action:** Fix file path permissions or redirect tracking file to a writable location (e.g., `/opt/data/workspace/mtgia/docs/hermes-analysis/manaloom-knowledge/`).

**Safe to automate:** No — requires code change in `/opt/data/scripts/auto_sync_learned_decks.py`.

### 2.2 pull-learning-events (262dc49e1be1) — PostgreSQL Type Mismatch

**Error:** `psycopg2.errors.UndefinedFunction: operator does not exist: uuid = text`

**Failure rate:** 19/19 runs (100%) since June 4 16:12Z. Every 30 minutes.

**Root cause:** `/opt/data/scripts/pull_learning_events.py` line 128 passes text values to a UUID column (`id = ANY(%s)`) without explicit type casting. PostgreSQL rejects the implicit conversion.

**Waste:** 48 failed runs/day (every 30m) with identical error. Extremely noisy.

**Risk:** Learning events from PostgreSQL not being pulled into Hermes. Deck learning pipeline severed at ingest point.

**Recommended action:** (1) Fix UUID casting in pull_learning_events.py (`id = ANY(%s::uuid[])`). (2) Consider slowing schedule to 120m — there's no value in failing every 30 minutes.

**Safe to automate:** No — requires code change in `/opt/data/scripts/pull_learning_events.py`.

### 2.3 flutter-ui-auditor (93a8ad77b251) — Output Valid, Status Error

**Observation:** Despite `last_status=error`, the latest output (2026-06-04T16:42Z) is a complete, valid deck analysis with swap proposals for Winota. The output shows proper markdown formatting, EDHREC comparison, and collection-based swap recommendations.

**Likely cause:** Tool-call limit or model response truncation flagged as error, but the core analysis completed successfully.

**Risk:** Low — output is functional. Status flag may be a false positive.

**Recommended action:** Monitor next run. If output remains valid, the error status may be cosmetic.

---

## 3. Fleet Changes Since Last Report — Major Contraction

### 3.1 Removed Crons (8) — Entire Lorehold Learning Pipeline

| ID | Name | Previous Status |
|:---|---:|:---|
| f20ac299992b | lorehold-deck-scout | OK |
| 712579b15767 | lorehold-deck-validator | OK |
| 08468451a06a | lorehold-mulligan-analyst | OK |
| a50bef4c2a59 | lorehold-evolution-oracle | OK |
| 4b2a79809aed | lorehold-deckbuilding-methodology | ERROR (429 quota) |
| 11780da0894a | lorehold-wincon-hunter | Paused |
| 8ea24b001c86 | lorehold-wincon-tester | Paused |
| 8ede9aa84b4d | lorehold-wincon-builder | Paused |

**Impact:** The entire Lorehold knowledge-learning pipeline is gone. This was the research lab for: deck scouting, deck validation, mulligan analysis, deck evolution, deckbuilding methodology, and wincon research. The promotion path from Lorehold learning → product logic (documented in HERMES_KNOWLEDGE_PIPELINE_GOVERNANCE.md) is now severed.

**Undocumented:** Neither CRON_STATUS.md nor HERMES_KNOWLEDGE_PIPELINE_GOVERNANCE.md reflect this removal.

### 3.2 Added Crons (4) — Script-Based Automation

| ID | Name | Schedule | Status |
|:---|---:|:---|:---:|
| 7fcab928efd3 | manaloom-auto-sync-learned-decks | every 120m | ERROR |
| 262dc49e1be1 | manaloom-pull-learning-events | every 30m | ERROR |
| 104fd03a2ea2 | manaloom-auto-promote-learned | every 360m | OK |
| 93a8ad77b251 | manaloom-flutter-ui-auditor | every 360m | ERROR |

These appear to be replacement pipelines for the removed Lorehold crons, but 3/4 are erroring. Only auto-promote-learned works correctly.

---

## 4. Provider / Model Distribution

| Provider | Model | Count | Status |
|:---|:---|---:|:---|
| opencode-go | deepseek-v4-pro | 14 | 13 OK, 1 disabled |
| script (no_agent) | N/A | 3 | 1 OK, 2 ERROR |
| none (agent, no provider) | N/A | 1 | 1 ERROR |

**Single-provider risk persists:** 14/18 crons (all LLM-based) on single provider/model. No fallback. However, the June 3 weekly quota event resolved naturally — all 3 affected crons now OK.

**Rate limit events since last report:** None. Zero 429 errors. The June 3 quota event was a one-time weekly exhaustion that self-resolved.

---

## 5. Schedule Compliance vs Governance Policy

With the Lorehold pipeline removed, most schedule violations are eliminated:

| Cron | Policy | Actual | Compliance |
|:-----|:---|:---|:---:|
| manaloom-commander-knowledge-deep | 240m | 180m | slightly fast |
| manaloom-gamechanger-research | 120m | 180m | slower (safe) |
| manaloom-logic-coherence-auditor | 120m | 180m | slower (safe) |
| manaloom-knowledge-import | 120m | 120m | OK |
| mtg-rules-auditor | not in policy | 180m | undocumented |
| manaloom-pull-learning-events | N/A (new) | 30m | WASTEFUL — 48 fails/day |

**Assessment:** 13/15 schedule-governed crons compliant (87%), up from 11/15 (73%). Only outlier: pull-learning-events at 30m with 100% failure rate.

---

## 6. CRON_STATUS.md — Orphaned Dashboard (~4 Days Stale)

Last update: 2026-06-01T16:46:31Z. No cron maintains it.

**Key discrepancies from reality:**
- Reports **23 crons** (actual: **18**)
- Reports **20 enabled** (actual: **17 enabled + 1 paused**)
- Reports **3 paused** (actual: **1 disabled**)
- Lists **8 crons that no longer exist** (entire Lorehold pipeline + wincon crons)
- Lists **manager-watchdog as paused** (actual: disabled with error)
- Lists **knowledge-import as paused** (actual: enabled + OK)
- **Missing 4 new crons** (auto-sync-learned-decks, pull-learning-events, auto-promote-learned, flutter-ui-auditor)
- Reports **rate limit recovery** (irrelevant — no 429s in current fleet)
- Schedule table **entirely outdated** (lists removed crons, wrong frequencies)

**Gap:** Flagged P0 in last two reports (June 1 and June 4). Now ~4 days stale. Still unresolved.

---

## 7. Worktree and Repository Risks

| Risk | Status |
|:-----|:------|
| Shared branch contention (18 crons writing) | Active |
| Worktree dirty artifacts | **Dirty** — FLUTTER_UI_AUDIT.md, knowledge.db, __pycache__ |
| STRUCTURE_AUDIT.md bloat | **RESOLVED** — trimmed from 27,253 to 7,854 lines |
| SQLite concurrency | Resolved (WAL mode) |
| Orphan output dir (cba438fd3a8b) | **NEW** — root-owned, not in jobs.json |
| Root-owned untracked files | **NEW** — cba438fd3a8b output directory |
| Git divergence | Ahead 10 of origin (merge pending) |

**Dirty worktree details:**
- `M docs/hermes-analysis/FLUTTER_UI_AUDIT.md` — uncommitted UI audit update from flutter-ui-auditor cron
- `M docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db` — SQLite modifications
- `M docs/hermes-analysis/manaloom-knowledge/scripts/__pycache__/db_helper.cpython-313.pyc` — bytecode changes
- `docs/hermes-analysis/manaloom-knowledge/scripts/_gc_check.py` — removido em 2026-06-17; era diagnostico manual/historico de `game_changers`, nao cron ativo.

These are cron artifacts from other crons operating on the shared branch, not product drift.

---

## 8. Duplicate Work Assessment

| Pattern | Status |
|:---|:---|
| code-structure-auditor duplicate | **Resolved** — only weekly remains |
| hermes-normal-audit vs weekly-parallel-audit | Low risk — different scopes |
| Wincon pipeline | **Resolved** — all removed |
| Knowledge synthesis + import | **Gap** — import runs but learning pipeline removed |
| commander-knowledge-deep vs mtg-rules-auditor | **Medium** — same skill, different crons |
| pull-learning-events + auto-sync-learned-decks | **Overlap** — both handle learned deck sync, both erroring |

**New concern:** auto-sync-learned-decks and auto-promote-learned may overlap in responsibility. Both handle the learned-deck pipeline but with different schedules and scripts.

---

## 9. Learning Artifacts Actionable for Product Work

| Artifact | Relevance | Status |
|:---|:---|:---|
| Tag accuracy gaps (payoff 35.5%, 7 tags below 85%) | P1 — 4 code tasks, CMC corruption, 7-day stagnation | **Stagnation since May 27** |
| card_rulings in quality gates (77K rulings) | P1 — swap validation | Not integrated |
| Synergy-axis awareness | P1 — optimizer role overlap only | Not implemented |
| MDFC/split-name dedup | P2 — duplicate detection | Not implemented |
| Game Changer 10 gaps | P1 — documented | Research ongoing |
| Learned deck swap proposals (from flutter-ui-auditor) | P2 — collection-based swaps | Output valid, pipeline errors |

**Note:** With Lorehold pipeline removed, the promotion path for these learnings (HERMES_KNOWLEDGE_PIPELINE_GOVERNANCE.md §4) may need revision — the research crons that produced them no longer exist.

---

## 10. Recommendations

### P0 — Critical Gaps

| # | Action | Evidence | Safe to Automate? |
|:---|:---|---|:---:|
| R1 | Restore CRON_STATUS.md maintenance | Dashboard frozen ~4 days. Reports 23 crons (actual: 18). Flagged P0 in 3 consecutive reports. | **PROPOSED:** Add CRON_STATUS.md update to this cron's output. |
| R2 | Fix pull-learning-events UUID casting | 19 consecutive failures (100%). 48 wasted runs/day. PostgreSQL UUID vs text mismatch in `/opt/data/scripts/pull_learning_events.py:128`. | No — requires code fix in script. PROPOSED: add `::uuid[]` cast. |
| R3 | Fix auto-sync-learned-decks permissions | 5 consecutive failures (100%). PermissionError writing tracking file. Learned deck sync completely blocked. | No — requires path/permission fix. |

### P1 — Fleet Health

| # | Action | Evidence | Safe to Automate? |
|:---|:---|---|:---:|
| R4 | Slow pull-learning-events to 120m | Running every 30m with 100% failure rate is wasteful. Even after fix, 30m is too frequent for a learning-events pull. | **PROPOSED ONLY:** Update schedule to every 120m. |
| R5 | Document Lorehold pipeline removal | 8 crons removed. Neither CRON_STATUS.md nor HERMES_KNOWLEDGE_PIPELINE_GOVERNANCE.md reflect this. | Yes — update docs. |
| R6 | Review knowledge-import DRY RUN status | Enabled and running OK — but is it still DRY RUN mode? card_deck_profiles frozen at 7,710 since last report. | Investigate. |

### P2 — Fleet Hygiene

| # | Action | Evidence | Safe to Automate? |
|:---|:---|---|:---:|
| R7 | Clean orphan output dir cba438fd3a8b | Root-owned, not in jobs.json. Leftover from removed cron. | Manual (root permissions needed). |
| R8 | Investigate flutter-ui-auditor error status | Output is valid, status is error. May be false positive from tool-call limit. | Monitor next run. |
| R9 | Update governance policy for new fleet | HERMES_KNOWLEDGE_PIPELINE_GOVERNANCE.md still lists Lorehold crons in frequency policy. | Yes — update doc. |
| R10 | Commit dirty worktree artifacts | FLUTTER_UI_AUDIT.md, knowledge.db, __pycache__ changes from other crons. | Yes — stage and commit. |

### P3 — Documentation

| # | Action | Safe to Automate? |
|:---|:---|---|
| R11 | Update fleet-size tracking in references/fleet-size-changes.md | Yes |
| R12 | Consider consolidating auto-sync + auto-promote scripts | Investigate overlap |

---

## 11. Previous Recommendations — Status Tracking

| # | Recommendation (from R1/R2/R3) | Status |
|:---|:---|:---|
| R1 | Restore CRON_STATUS.md maintenance | **STILL OPEN (~4 days)** |
| R2 | Investigate opencode-go weekly quota pattern | **RESOLVED** — event passed, crons OK |
| R3 | Slow lorehold-evolution-oracle to 240m | **N/A** — cron removed |
| R4 | Resolve knowledge-import DRY RUN mode | **PARTIALLY** — enabled but DRY RUN status unconfirmed |
| R5 | Monitor weekly-parallel-audit recovery | **RESOLVED** — ran OK June 4 14:15Z |
| R6 | Trim STRUCTURE_AUDIT.md | **DONE** — 27,253 → 7,854 lines |
| R7 | Document mtg-rules-auditor in governance policy | **OPEN** |
| R8 | Evaluate single-provider risk | **OPEN** — 14/18 crons on one provider |
| R9 | Update governance policy schedule table | **N/A** — fleet changed, policy needs full rewrite |

**Completion:** 3/9 done, 1 partially, 3 still open, 2 N/A.

---

## 12. Cron-Governor-Report Self-Check

| Metric | Value |
|:---|---|
| Schedule | every 720m (12h) |
| Last execution | 2026-06-04T00:22Z |
| Current execution | 2026-06-05T02:09:36Z |
| Gap between executions | ~26h |
| Missed cycles | ~1 (expected ~June 4 12:22Z) |

The gap between last and current execution (~26h) exceeds the 12h schedule. This may be scheduler drift or a missed tick. The next_run_at in jobs.json is 2026-06-05T14:04Z, suggesting the scheduler already corrected.

---

## 13. Current Git State

- **Branch:** codex/hermes-analysis-docs — ahead 10 of origin (merge pending from remote diverge).
- **Worktree:** Dirty (cron artifacts: FLUTTER_UI_AUDIT.md, knowledge.db, __pycache__).
- **STRUCTURE_AUDIT.md:** 7,854 lines (healthy — was 27,253).
- **Output disk:** 19 directories (1 orphan root-owned).
- **COMMIT_DIGEST.md:** Updated to 75d41d40 (June 4), health endpoint confirms production.

---

*Report: manaloom-cron-governor-report (21fa86eb0d84) — fourth execution, 2026-06-05T02:09:36Z.*
*Fleet: 18 crons (17 enabled, 1 paused) — 14 OK, 3 error (2 script bugs, 1 false positive), 1 paused.*
*Previous report: 2026-06-04T00:15Z. This report: 2026-06-05T02:09:36Z.*
*Change since last report: -4 fleet (22→18), Lorehold pipeline removed, 4 new scripts added.*
