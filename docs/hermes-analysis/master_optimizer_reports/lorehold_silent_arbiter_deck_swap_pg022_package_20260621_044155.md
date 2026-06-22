# PG-022 Lorehold Silent Arbiter Deck Swap Package

Status: `applied_and_postchecked_and_battle_validated`

## Proposed Swap

- Add: `Silent Arbiter`
- Cut: `Monument to Endurance`
- Target PostgreSQL deck: `528c877f-f829-4207-95e6-73981776c323`

## Evidence

All runs use corrected PG-021 global attack-rule scope and the same seed window starting at `63212310`.

| Run | Artifact | Result | Gate |
| --- | --- | ---: | --- |
| Baseline PG-020, corrected rules, 64 seeds | `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260621_041725/summary.json` | `4/64 = 6.25%` | `trusted_for_strategy_learning` |
| Silent Arbiter over Monument, corrected rules, 64 seeds | `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260621_032623/summary.json` | `8/64 = 12.5%` | `trusted_for_strategy_learning` |

Seed delta:

- New wins versus baseline: `63212318`, `63212320`, `63212343`, `63212357`, `63212358`, `63212360`.
- Lost baseline wins: `63212316`, `63212344`.
- Shared wins: `63212323`, `63212339`.
- Net: `+4` Lorehold wins over 64 seeds.

Pressure note:

- Baseline pressure to Lorehold: `912`; Silent variant: `1103`.
- Average final turn increased from `8.81` to `10.11`, and pressure per turn stayed close (`1.62` baseline, `1.70` Silent). This suggests the higher total pressure is largely longer game duration, not a gate failure.

## Execution

```bash
cd /Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia
set -a && source server/.env && set +a
PGPASSWORD="$DB_PASS" psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -v ON_ERROR_STOP=1 -f docs/hermes-analysis/master_optimizer_reports/lorehold_silent_arbiter_deck_swap_pg022_precheck_20260621_044155.sql
PGPASSWORD="$DB_PASS" psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -v ON_ERROR_STOP=1 -f docs/hermes-analysis/master_optimizer_reports/lorehold_silent_arbiter_deck_swap_pg022_apply_20260621_044155.sql
PGPASSWORD="$DB_PASS" psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -v ON_ERROR_STOP=1 -f docs/hermes-analysis/master_optimizer_reports/lorehold_silent_arbiter_deck_swap_pg022_postcheck_20260621_044155.sql
```

Rollback:

```bash
cd /Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia
set -a && source server/.env && set +a
PGPASSWORD="$DB_PASS" psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -v ON_ERROR_STOP=1 -f docs/hermes-analysis/master_optimizer_reports/lorehold_silent_arbiter_deck_swap_pg022_rollback_20260621_044155.sql
```

## Post-Apply Required

1. Sync target deck from PostgreSQL to Hermes SQLite.
2. Rerun 16-seed smoke and 64-seed battle on the synchronized deck.
3. Record post-sync hashes and battle artifacts in the central registers.

## Execution Result

- Precheck returned `ready_to_apply=true`.
- Apply completed and reported `Monument to Endurance=0`,
  `Silent Arbiter=1`, `total_quantity=100`.
- Postcheck passed:
  `deck_rows=100`, `deck_quantity=100`, `monument_rows=0`,
  `silent_rows=1`, `silent_is_commander=false`, `backup_rows=1`,
  `postcheck_passed=true`.
- PG -> Hermes deck sync report:
  `sync_pg_target_deck_to_hermes_pg022_silent_arbiter_20260621_044155.json`,
  `apply=true`, `cards_written=100`, `quantity_written=100`,
  `duplicate_rows_collapsed=0`.
- Post-sync smoke:
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260621_044419/summary.json`,
  `codex_pg022_post_pg_sync_silent_arbiter_16`,
  `3/16 = 18.75%`, `battle_replay_final_status=trusted_for_strategy_learning`,
  `mandatory_gate_divergences=[]`.
- Post-sync full validation:
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260621_044758/summary.json`,
  `codex_pg022_post_pg_sync_silent_arbiter_64`,
  `8/64 = 12.5%`, `battle_replay_final_status=trusted_for_strategy_learning`,
  `mandatory_gate_divergences=[]`.
