# PG024 Mental Misstep Deploy Validation - 2026-06-22 13:07 UTC

## Scope

- Promote `Mental Misstep` target legality from temporary runtime waiver to PostgreSQL `card_battle_rules`.
- Sync the durable rule back into the local SQLite/Hermes runtime cache.
- Remove `Mental Misstep` from `HANDCRAFTED_KNOWN_CARD_RULES` and `MANUAL_RULE_RUNTIME_WAIVERS` so battle runtime resolves it from the registry.

## PostgreSQL Evidence

Package files:

- `mental_misstep_target_rule_pg024_precheck_20260622_130251.sql`
- `mental_misstep_target_rule_pg024_apply_20260622_130251.sql`
- `mental_misstep_target_rule_pg024_postcheck_20260622_130251.sql`
- `mental_misstep_target_rule_pg024_rollback_20260622_130251.sql`

Precheck result:

- `card_rows=1`
- `expected_oracle_hash_rows=1`
- `exact_target_rule_rows=0`
- `broad_enabled_counter_rows=2`

Apply result:

- Inserted/updated curated verified rule
  `battle_rule_v1:da6a568dbdfeda5d4009574d953db55e`.
- New `effect_json`:
  `{"effect":"counter","instant":true,"counter_target_cmc":1,"battle_model_scope":"mental_misstep_mana_value_one_counter_v1"}`.
- Disabled the two broad counter approximations:
  `battle_rule_v1:62ec2df5de2fe17782f94df13896b536` and
  `battle_rule_v1:d47cbde8d1dc5678060e25ea1b620a82`.

Postcheck result:

- `exact_executable_rule_rows=1`
- `broad_enabled_counter_rows=0`
- `card_intelligence_snapshot` shows the restricted rule first and the broad rows as `deprecated`/`disabled`.

## SQLite/Hermes Sync

Command:

```bash
python3 docs/hermes-analysis/manaloom-knowledge/scripts/sync_battle_card_rules_pg.py --apply-sqlite-from-pg --include-needs-review --only-card "Mental Misstep" --report docs/hermes-analysis/master_optimizer_reports/battle_card_rules_sqlite_from_pg_pg024_mental_misstep_20260622_130535.json
```

Sync result:

- `pg_rows_loaded=3`
- `sqlite_inserted_or_updated=3`
- `canonical_snapshot_rows_exported=3193`

Runtime check:

- `Mental Misstep` is no longer in `MANUAL_RULE_RUNTIME_WAIVERS`.
- `get_card_effect({"name":"Mental Misstep"})` resolves from SQLite/PG with
  `_rule_source=curated`, `_rule_review_status=verified`,
  `_rule_execution_status=auto`, and
  `_rule_logical_key=battle_rule_v1:da6a568dbdfeda5d4009574d953db55e`.

## Test Evidence

- `python3 -m py_compile docs/hermes-analysis/manaloom-knowledge/scripts/battle_analyst_v9.py docs/hermes-analysis/manaloom-knowledge/scripts/battle_stack_casting_tests.py docs/hermes-analysis/manaloom-knowledge/scripts/test_runtime_pg_rule_fallback_for_promoted_hotfixes.py`
  passed.
- `python3 docs/hermes-analysis/manaloom-knowledge/scripts/battle_stack_casting_tests.py`
  passed.
- `python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_replay_v10_3_renderer.py`
  passed.
- `python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_runtime_pg_rule_fallback_for_promoted_hotfixes.py`
  passed, `3` tests in `15.999s`.

## Battle Evidence

Focused proof:

- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260622_130646/summary.json`
- `battle_replay_final_status=trusted_for_strategy_learning`
- `mandatory_gate_divergences=[]`
- `test_results_status_counts={"pass":18}`

Full proof:

- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260622_130732/summary.json`
- `run_profile=full_after_pg024_mental_misstep_registry_16_seed`
- `invocation_kind=codex_full_after_pg024_mental_misstep_registry`
- `battle_replay_final_status=trusted_for_strategy_learning`
- `mandatory_gate_divergences=[]`
- `seeds_completed=16/16`
- `test_results_status_counts={"pass":18}`
- Lorehold `2/16`, opponents `13/16`
- Opponent combat pressure to Lorehold `316`, to other players `13`

Replay proof:

- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260622_130732/seed_63231114/replay.txt`
- Turn 7: Lorehold casts and resolves `Windborn Muse`.
- Thrasios still has `Mental Misstep` in `HandCards=[...]` after `Windborn Muse` resolves.
- Thrasios and Sisay damage to Lorehold is `0`; Lorehold still dies later to Rograkh for `2`, confirming the remaining loss is deck/board-state pressure, not the old invalid counter.

## Current Reading

- PG024 is applied and validated.
- The temporary runtime waiver for `Mental Misstep` is closed.
- The deck remains unresolved: durable rule promotion did not change the full 16-seed result, which stays `2/16`.
- Next work should target Lorehold deck/strategy under table focus, not more `Mental Misstep` runtime repair.
