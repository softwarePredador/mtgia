# Hermes Cron Pipeline Order — Deck Learning + Optimizer

Updated: 2026-06-07

## Current operational snapshot

Hermes currently has 22 scheduler jobs.

Healthy script jobs:

- `manaloom-master-watchdog` — every 30m, ok.
- `manaloom-knowledge-import` — every 120m, ok.
- `manaloom-auto-sync-learned-decks` — every 120m, ok.
- `manaloom-pull-learning-events` — every 30m, ok.
- `manaloom-auto-promote-learned` — every 360m, ok.
- `manaloom-master-optimizer-preflight` — every 20m, ok.
- `lorehold-knowncards-validator` — every 30m, manually recovered after ownership fix.

Paused intentionally:

- `manaloom-manager-watchdog` — superseded by report-only governance.
- `lorehold-knowncards-generator` — paused after permission failure; validator now expands the pool.
- `lorehold-universal-optimizer` — paused because `universal_optimizer.py` has auto-apply behavior and permission failures.
- `manaloom-master-optimizer-slot-scan` — ready but paused until an approved baseline is frozen.

Agent/report jobs currently failing mostly because of provider usage limits:

- `manaloom-hermes-normal-audit`
- `manaloom-commander-knowledge-deep`
- `manaloom-gamechanger-research`
- `manaloom-tag-accuracy-reporter`
- `manaloom-mana-base-validator`
- `manaloom-logic-coherence-auditor`
- `manaloom-knowledge-synthesis`
- `mtg-rules-auditor`
- `manaloom-cron-governor-report`

## Current Lorehold evidence

Latest manual battle proof run on Hermes:

```text
Battle Analyst v8, 50 games vs each of 12 real learned opponent decks.
Overall WR: 50.2% (301W/294L/5S)
Weak matchups:
- Winota, Joiner of Forces: 22.0% and 34.0%
- Korvold, Fae-Cursed King: 46.0%
- Niv-Mizzet, Parun: 50.0%
```

SQLite state:

- `deck_cards` has 100 cards for deck id 6.
- `slot_benchmarks` has 1855 rows.
- `swap_benchmarks` has 0 rows.
- Best slot-scan candidates are still below the baseline used by the old scan; this means the scan found many bad replacement/cut pairs, not that the deck is proven optimal.

Important interpretation:

- The current deck is playable in the simulator, but not proven optimal.
- The old 75.0% battle entry was from a previous state/configuration and should not be treated as the current baseline.
- Current baseline should be frozen from the latest clean 50.2% run or rerun with a dedicated baseline script before any swap test.

## Ideal order for end-to-end deck learning

### 1. Ingest real data

Jobs:

- `manaloom-pull-learning-events`
- `manaloom-knowledge-import`
- `manaloom-auto-sync-learned-decks`
- `manaloom-auto-promote-learned`

Purpose:

- Pull real user/deck learning events.
- Sync learned decks into Hermes SQLite.
- Promote only complete and usable deck profiles.

Missing hardening:

- Promotion must reject incomplete decks by code, not only by prompt.
- Any deck with fewer than 90 cards should be excluded from optimizer/battle candidate pools.

### 2. Maintain card knowledge

Jobs:

- `lorehold-knowncards-validator`
- `manaloom-master-optimizer-preflight`

Purpose:

- Expand `known_cards_generated.json`.
- Validate card classifications.
- Sync real Postgres metadata into `card_oracle_cache`.
- Keep mana cost, oracle text, power/toughness and keywords available for battle.

Missing hardening:

- Conflicts from `kc_validator.py` must be persisted as actionable review items.
- The validator should not only print conflicts; it should write a compact conflict report.

### 3. Validate rules and simulator readiness

Jobs:

- `manaloom-master-optimizer-preflight`
- `mtg-rules-auditor`
- `manaloom-mana-base-validator`
- `manaloom-tag-accuracy-reporter`

Purpose:

- Prove battle regression is green before optimization.
- Check MTG rules assumptions.
- Check mana base and functional tags.

Current blocker:

- Agent jobs are mostly blocked by provider 429.
- Some prompts still reference legacy/decommissioned cron IDs or old schema assumptions.

### 4. Freeze current baseline

Needed job:

- `manaloom-master-optimizer-baseline`

Purpose:

- Run battle on the current exact deck.
- Save immutable baseline metrics:
  - overall winrate;
  - matchup winrate;
  - average turn to win/loss;
  - screw/flood/stall;
  - win reason;
  - deck hash;
  - battle version;
  - card pool/cache version.

Current state:

- This job does not exist yet.
- Without it, slot scan results can be compared against stale or wrong baselines.

### 5. Scan candidate swaps safely

Prepared job:

- `manaloom-master-optimizer-slot-scan`

Purpose:

- Run `slot_optimizer.py`.
- Test candidate swaps one at a time.
- Restore the deck after each test.
- Write benchmark rows.

Current state:

- Job is registered but paused.
- It should stay paused until baseline is frozen.
- It should replace the old `lorehold-universal-optimizer`.

### 6. Confirm promising candidates

Needed job:

- `manaloom-master-optimizer-confirmation`

Purpose:

- Read top candidates from `slot_benchmarks`.
- Reject candidates with illegal color identity, wrong bracket, wrong type, or bad cut target.
- Retest only promising pairs with larger sample size.
- Write `swap_benchmarks` full-phase rows.

Current state:

- `swap_benchmarks` exists but is empty.
- No confirmation job exists.

### 7. Quality gate before applying

Needed job:

- `manaloom-master-optimizer-quality-gate`

Purpose:

- Validate proposed swaps before any deck mutation:
  - 100-card Commander legality;
  - commander color identity;
  - land count;
  - curve;
  - mana color production;
  - Game Changer/bracket budget;
  - protected cards;
  - role preservation;
  - commander plan.

Current state:

- Quality gate rules are documented, but no Hermes cron enforces them before swap application.

### 8. Replay audit

Needed script/job:

- `replay_decision_auditor.py`
- `manaloom-master-optimizer-replay-audit`

Purpose:

- Generate replays for baseline and proposed optimized deck.
- Detect bad attacks, bad blocks, bad spell timing, bad counter/removal use, ignored wincons and tutor mistakes.
- If the battle AI made bad decisions, fix `battle_analyst_v8.py` before trusting optimizer results.

Current state:

- Missing.

### 9. Apply only after approval

Needed job:

- `manaloom-master-optimizer-approved-apply`

Purpose:

- Apply swaps only from a reviewed approval file.
- Never auto-apply from quick scan.
- Write before/after decklist summary and rollback data.

Current state:

- Missing.
- Old `universal_optimizer.py` had auto-apply and is paused.

## What is missing to build the best Lorehold deck

1. Freeze a current baseline from the exact current deck.
2. Create `baseline_runs` or equivalent table to persist baseline data.
3. Create a confirmation runner that fills `swap_benchmarks`.
4. Add a quality gate cron before any swap application.
5. Add replay decision audit.
6. Convert `kc_validator.py` conflicts into a report and review queue.
7. Fix stale prompts in agent jobs that reference old cron IDs or old SQLite schema.
8. Resolve provider 429 or slow/pause agent jobs so they do not fail noisily.
9. Keep `lorehold-universal-optimizer` paused unless it is rewritten into proposal-only mode.
10. Use `manaloom-master-optimizer-slot-scan` only after baseline approval.

## Recommended next implementation order

1. Add `master_optimizer_baseline.py`.
2. Add `master_optimizer_confirmation.py`.
3. Add `master_optimizer_quality_gate.py`.
4. Add `replay_decision_auditor.py`.
5. Add a final handoff report generator.
6. Only then enable `manaloom-master-optimizer-slot-scan`.

## Practical verdict

The Hermes pipeline now has the right ingredients, but not the full closed loop yet.

It can ingest, sync, preflight, validate known cards and run battle.
It cannot yet safely transform slot-scan findings into an approved best Lorehold deck without manual review, because the baseline, confirmation, quality gate and replay-audit stages are still missing.
