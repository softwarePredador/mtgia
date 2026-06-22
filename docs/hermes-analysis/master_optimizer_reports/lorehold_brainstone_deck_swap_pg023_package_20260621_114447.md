# PG-023 Lorehold Brainstone Deck Swap Package

Status: `applied_and_postchecked_and_battle_validated`

## Proposed Swap

- Add: `Brainstone`
- Cut: `Generous Gift`
- Target PostgreSQL deck: `528c877f-f829-4207-95e6-73981776c323`

## Evidence

All runs use the same 64-seed window starting at `63212310`, after the PG-022
Silent Arbiter deck state and the corrected Lorehold own-stack protection fix.

| Run | Artifact | Result | Gate |
| --- | --- | ---: | --- |
| Baseline PG-022, 64 seeds | `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260621_044758/summary.json` | `8/64 = 12.5%` | `trusted_for_strategy_learning` |
| Brainstone over Generous Gift, 64 seeds | `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260621_080706/summary.json` | `14/64 = 21.875%` | `trusted_for_strategy_learning` |

Seed delta:

- New wins versus PG-022 baseline: `63212316`, `63212321`, `63212329`,
  `63212330`, `63212334`, `63212336`, `63212337`, `63212341`, `63212342`,
  `63212372`.
- Lost PG-022 wins: `63212320`, `63212343`, `63212357`, `63212358`.
- Shared wins: `63212318`, `63212323`, `63212339`, `63212360`.
- Net: `+6` Lorehold wins over 64 seeds.

Interaction note:

- Brainstone appears in 6 of the 10 new-win replays and is explicitly activated
  as `brainstone_draw_three_put_two_back_for_miracle` in several of them
  (`63212316`, `63212321`, `63212329`, `63212342`).
- In the four lost baseline wins, only seed `63212357` had a Generous Gift event
  in the baseline replay, so the cut is not primarily removing a repeatedly
  decisive interaction spell.

Gate note:

- Candidate run completed `64/64` seeds.
- `mandatory_gate_divergences=[]`.
- `test_results_status_counts={"pass": 18}`.
- `table_intent_target_wins=14`, `table_intent_opponent_wins=49`.
- `target_pressure_opponent_combat_to_target=1050`, with target-pressure gate
  `pass` on all 64 seeds.
- Strategy low-confidence findings are only `forced_keep_after_bad_mulligan`
  (`13`), lower than PG-022 baseline (`15`).

## Execution

```bash
cd /Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia
set -a && source server/.env && set +a
PGPASSWORD="$DB_PASS" psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -v ON_ERROR_STOP=1 -f docs/hermes-analysis/master_optimizer_reports/lorehold_brainstone_deck_swap_pg023_precheck_20260621_114447.sql
PGPASSWORD="$DB_PASS" psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -v ON_ERROR_STOP=1 -f docs/hermes-analysis/master_optimizer_reports/lorehold_brainstone_deck_swap_pg023_apply_20260621_114447.sql
PGPASSWORD="$DB_PASS" psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -v ON_ERROR_STOP=1 -f docs/hermes-analysis/master_optimizer_reports/lorehold_brainstone_deck_swap_pg023_postcheck_20260621_114447.sql
```

Rollback:

```bash
cd /Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia
set -a && source server/.env && set +a
PGPASSWORD="$DB_PASS" psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -v ON_ERROR_STOP=1 -f docs/hermes-analysis/master_optimizer_reports/lorehold_brainstone_deck_swap_pg023_rollback_20260621_114447.sql
```

## Execution Result

- Precheck returned `ready_to_apply=true`.
- Apply completed and reported `Generous Gift=0`, `Brainstone=1`,
  `total_quantity=100`.
- Postcheck passed:
  `deck_rows=100`, `deck_quantity=100`, `gift_rows=0`,
  `brainstone_rows=1`, `brainstone_is_commander=false`,
  `deck_backup_rows=1`, `rule_backup_rows=1`,
  `brainstone_rule_verified=true`, `postcheck_passed=true`.
- PG -> Hermes battle-rule sync report:
  `battle_card_rules_sqlite_from_pg_pg023_brainstone_20260621_114447.json`,
  `sqlite_inserted_or_updated=5211`, `pg_rows_loaded=5244`.
- PG -> Hermes deck sync report:
  `sync_pg_target_deck_to_hermes_pg023_brainstone_20260621_114447.json`,
  `apply=true`, `cards_written=100`, `quantity_written=100`,
  `duplicate_rows_collapsed=0`,
  `deck_hash=c160e490b9e887d7b1f15ca6557be97d59b5aaff60bdee926805fd36359a6cbf`,
  `semantics_hash=0c9a7c65e28993112e340aebd35d873847af3b4dd7b6d13712ea6afc74ec068b`,
  `ruleset_hash=86a6271a29428335e47f1d74355c8d899f075c79898711f70c3f284dd85d6fcc`.
- Post-sync smoke:
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260621_121648/summary.json`,
  `4/16 = 25%`, `battle_replay_final_status=trusted_for_strategy_learning`,
  `mandatory_gate_divergences=[]`.
- Post-sync full validation:
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260621_122732/summary.json`,
  `14/64 = 21.875%`, `battle_replay_final_status=trusted_for_strategy_learning`,
  `mandatory_gate_divergences=[]`.
- Local SQLite post-sync focused check:
  `Brainstone=1`, no `Generous Gift` row in `deck_id=6`, and Brainstone's
  curated rule is `verified/auto`.

## Replay Excerpt

Seed `63212316`, post-sync full validation
`/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260621_122732/seed_63212316/replay.txt`:

- Turn 4: Lorehold casts Brainstone as `topdeck_manipulation`, rule
  `curated/verified`.
- Turn 10: Lorehold activates Brainstone with
  `kind=brainstone_draw_three_put_two_back_for_miracle`.
- Turn 11: Lorehold wins by elimination.
- Seed gates: strategy `usable_for_strategy_learning`, table-intent `pass`,
  target-pressure `pass`.
