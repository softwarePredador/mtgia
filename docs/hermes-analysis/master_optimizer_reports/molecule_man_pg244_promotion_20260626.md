# Molecule Man PG-244 Promotion

- generated_at: `2026-06-26T18:56:00Z`
- card: `Molecule Man`
- scope: promote reviewed runtime rule from local Hermes SQLite into PostgreSQL, then mirror PostgreSQL back into local Hermes SQLite cache.
- postgres_writes: `true`
- source_db_mutated: `true` for local Hermes SQLite cache only through PG mirror.

## Rule Promoted

- logical_rule_key: `battle_rule_v1:752f8cfd0a44d1889ffdb40610847374`
- source: `curated`
- review_status: `verified`
- execution_status: `auto`
- oracle_hash: `35e82bd52776c455745138b048ccc116`
- battle_model_scope: `nonland_hand_miracle_zero_static_v1`
- runtime scope: grants miracle cost `0` to nonland cards in controller hand.

## Apply Evidence

- precheck PostgreSQL rows before apply: `0`
- `molecule_man_pg244_apply_20260626.json`: `pg_inserted_or_updated=1`, `curated_rows=1`, `input_rows=1`, `selected_cards=["Molecule Man"]`.
- `molecule_man_pg244_sqlite_sync_20260626.json`: `pg_rows_loaded=1`, `sqlite_inserted_or_updated=1`, `canonical_snapshot_rows_exported=3257` to `/tmp/molecule_man_pg244_canonical_snapshot_20260626.json`.
- PostgreSQL verification after apply: exactly `1` row for `normalized_name='molecule man'`, `source=curated`, `review_status=verified`, `execution_status=auto`.
- SQLite verification after sync: exactly `1` row for `normalized_name='molecule man'`, `source=curated`, `review_status=verified`, `execution_status=auto`.

## Runtime And Gate Evidence

- `lorehold_gate_timeout_checkpoint_smoke_20260626.json`: gate smoke completed with `game_timeout_seconds=30.0`.
- `lorehold_gate_timeout_checkpoint_smoke_20260626_checkpoint.json`: per-game checkpoint completed `1/1` game and recorded latest result.
- `lorehold_registry_candidate_runner_20260626_smoke.json`: registry runner read the queue and blocked `candidate_607_reprieve_v1` because its same-function cut is still `TBD`.

## Validation

- `python3 -m py_compile` for touched gate, runner, reviewed-rule, and sync modules: pass.
- `PYTHONPATH=docs/hermes-analysis/manaloom-knowledge/scripts python3 -m unittest docs/hermes-analysis/manaloom-knowledge/scripts/test_lorehold_variant_battle_gate.py docs/hermes-analysis/manaloom-knowledge/scripts/test_lorehold_registry_candidate_runner.py docs/hermes-analysis/manaloom-knowledge/scripts/test_reviewed_battle_card_rules.py`: `35` tests pass.
- Direct runtime test: `PASS test_molecule_man_grants_zero_miracle_to_nonland_first_draw`.
