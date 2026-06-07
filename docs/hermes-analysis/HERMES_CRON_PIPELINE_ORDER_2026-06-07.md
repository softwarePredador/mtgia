# Hermes Cron Pipeline Order — Deck Learning + Optimizer

Updated: 2026-06-07

## Current operational snapshot

Hermes currently has 23 scheduler jobs.

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
- `lorehold-universal-optimizer` — paused; schedule remains `every 10m`, but it must stay disabled because `universal_optimizer.py` has auto-apply behavior and permission failures.
- `manaloom-master-optimizer-slot-scan` — ready but paused until an approved baseline is frozen.
- `manaloom-master-optimizer-end-to-end` — manual-only pipeline; schedule placeholder is `every 1440m`, but it is disabled/paused for supervised runs only.

Agent/report jobs paused by provider 429 backoff:

- `manaloom-hermes-normal-audit`
- `manaloom-commander-knowledge-deep`
- `manaloom-gamechanger-research`
- `manaloom-tag-accuracy-reporter`
- `manaloom-mana-base-validator`
- `manaloom-code-structure-auditor`
- `manaloom-logic-coherence-auditor`
- `manaloom-knowledge-synthesis`
- `mtg-rules-auditor`
- `manaloom-cron-governor-report`

Provider backoff evidence:

- Script: `docs/hermes-analysis/manaloom-knowledge/scripts/hermes_provider_backoff.py`.
- Report: `docs/hermes-analysis/master_optimizer_reports/hermes_provider_backoff_20260607_081300.md`.
- Backup on server: `/opt/data/cron/jobs.json.bak_provider_backoff_20260607_081300`.

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

- Conflicts from `kc_validator.py` are now persisted as actionable review items.
- Latest report: `docs/hermes-analysis/kc_validator_reports/kc_validator_conflicts_20260607_081557.md`.
- Latest result: 500 cards validated, 0 corrections, 2 conflicts.

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

Current state:

- Agent jobs that were blocked by provider 429 are paused by backoff, instead of failing noisily.
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

- Implemented as `master_optimizer_baseline.py`.
- Validated on Hermes with baseline id `2`: 45.0% WR, 27W/31L/2S, 60 games.
- Baseline data is persisted in `optimizer_baseline_runs`.

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

- Implemented as `master_optimizer_confirmation.py`.
- `swap_benchmarks` now has short `confirmation` and stricter `full_confirmation` rows.
- Full confirmation validated `Sticky Fingers` over `Storm-Kiln Artist`: 55.8% WR, +10.8pp, 67W/53L/0S, 120 games.

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

- Implemented as `master_optimizer_quality_gate.py`.
- Quality gate blocks illegal color identity candidates and records reasons in `optimizer_quality_reviews`.
- It now prevents off-color candidates such as `Imperial Seal`, `Aether Channeler`, `Korvold, Fae-Cursed King`, and `Spectral Sailor`.

### 8. Replay audit

Needed script/job:

- `replay_decision_auditor.py`
- `manaloom-master-optimizer-replay-audit`

Purpose:

- Generate replays for baseline and proposed optimized deck.
- Detect bad attacks, bad blocks, bad spell timing, bad counter/removal use, ignored wincons and tutor mistakes.
- If the battle AI made bad decisions, fix `battle_analyst_v8.py` before trusting optimizer results.

Current state:

- Implemented as turn-by-turn `replay_decision_auditor.py`.
- `battle_replay_v10_3.py` now writes text replay plus JSONL structured events.
- Audits attacks, blocks, target selection, cleanup, Approach, tutor, removal, board wipe and game close.
- Latest report: `docs/hermes-analysis/master_optimizer_reports/master_optimizer_replay_audit_20260607_081614.md`.
- Latest result: 895 structured events across 3 fresh replays, 0 turn-by-turn findings.
- Remaining hardening: larger seed batches and deeper counter/removal expected-value scoring.

### 9. Apply only after approval

Needed job:

- `manaloom-master-optimizer-approved-apply`

Purpose:

- Apply swaps only from a reviewed approval file.
- Never auto-apply from quick scan.
- Write before/after decklist summary and rollback data.

Current state:

- Implemented as `master_optimizer_apply.py`.
- Old `universal_optimizer.py` had auto-apply and is paused.
- One manual approved apply was validated on Hermes local SQLite only.
- Applied `Sticky Fingers` over `Storm-Kiln Artist` after full confirmation.
- Before/after hashes and rollback path were generated.
- Post-apply deck state was validated at 100 cards, 35 lands and CMC 2.5.
- No production database was mutated.

Post-apply proof:

- Report: `docs/hermes-analysis/master_optimizer_reports/master_optimizer_apply_hermes_20260607_041841.md`.
- Post-apply baseline: `docs/hermes-analysis/master_optimizer_reports/master_optimizer_post_apply_baseline_hermes_20260607_041859.md`.
- Post-apply battle: 47.5% WR, 57W/63L/0S, 120 games.

### 10. Product-facing handoff

Needed before copying any Hermes-local result into the app/product database:

- `master_optimizer_product_handoff.py`

Purpose:

- Separate Hermes learning from product mutation.
- Require explicit product owner approval.
- Require product backup, dry-run diff, legality check and app/API smoke test.
- Prevent automatic optimizer changes from touching product-facing decks.

Current state:

- Implemented and validated.
- Report: `docs/hermes-analysis/master_optimizer_reports/master_optimizer_product_handoff_20260607_081454.md`.
- Status: `needs_product_owner_approval`.
- No production database was mutated.

## What is missing to build the best Lorehold deck

1. Review the 2 KC conflicts and decide whether classification rules need adjustment.
2. Fix stale prompts in agent jobs that reference old cron IDs or old SQLite schema.
3. Resume provider-backed agent jobs only after quota/backoff is resolved.
4. Keep `lorehold-universal-optimizer` paused unless it is rewritten into proposal-only mode.
5. Re-run confirmation and replay audit with larger sample sizes before product-facing mutation.
6. Execute product apply only through the product handoff checklist.

## Recommended next implementation order

1. Review KC conflicts and patch classification rules if needed.
2. Update stale provider-backed agent prompts while they remain paused.
3. Run larger confirmation plus larger replay audit before any product-facing mutation.
4. If approved, run product backup/dry-run/smoke-test flow from the product handoff.

## Practical verdict

The Hermes pipeline now has a functional safe loop through manual apply on Hermes local SQLite:

- sync metadata;
- preflight;
- freeze baseline;
- quality gate;
- short confirmation;
- full confirmation;
- aggregate replay audit;
- manual-review handoff.
- rollback-aware manual apply;
- post-apply battle verification.
- turn-by-turn replay audit;
- KC conflict report;
- provider 429 backoff;
- product-facing handoff gate.

It produced and applied one approved Hermes-local swap for Lorehold:

- `Sticky Fingers` over `Storm-Kiln Artist`;
- full confirmation: 55.8% WR, +10.8pp, 67W/53L/0S, 120 games.
- post-apply baseline: 47.5% WR, 57W/63L/0S, 120 games.

It still must not auto-apply. The remaining gap is operational review: KC conflicts, stale prompt cleanup, larger samples and explicit product approval before copying any Hermes-local result into a product-facing deck.
