# PG025 The One Ring and Orim's Chant Deploy Validation - 2026-06-22 15:29 UTC

## Scope

- Promote `The One Ring` runtime-correct semantics into PostgreSQL
  `card_battle_rules`.
- Promote `Orim's Chant` kicked attack-prevention semantics into PostgreSQL
  `card_battle_rules`.
- Sync the durable rules into local Hermes SQLite/cache and verify battle
  artifacts after the sync.

## PostgreSQL Evidence

Package files:

- `one_ring_orims_battle_rules_pg025_precheck_20260622_152115.sql`
- `one_ring_orims_battle_rules_pg025_apply_20260622_152115.sql`
- `one_ring_orims_battle_rules_pg025_postcheck_20260622_152115.sql`
- `one_ring_orims_battle_rules_pg025_rollback_20260622_152115.sql`

Precheck result:

- `one_ring_card_rows=1`
- `one_ring_expected_oracle_hash_rows=1`
- `one_ring_exact_rule_rows=0`
- `one_ring_legacy_draw_engine_rows=1`
- `orims_chant_card_rows=1`
- `orims_chant_expected_oracle_hash_rows=1`
- `orims_chant_exact_rule_rows=0`
- `orims_chant_legacy_silence_rows=2`

Apply result:

- Inserted/updated `The One Ring` curated verified/auto rule
  `battle_rule_v1:a71907ee296b5801e92e8d7f1940dba1`.
- Inserted/updated `Orim's Chant` curated verified/auto rule
  `battle_rule_v1:2332a82b6395a065b6516702d3e326c7`.
- Disabled the old `The One Ring` broad `draw_engine` row
  `battle_rule_v1:f696a2929247bdfb69bb7a4dd9c068b0`.
- Disabled the old `Orim's Chant` broad rows
  `battle_rule_v1:d3367950588008088c6a73c604765da0` and
  `battle_rule_v1:8b27af907705709f0b9065304d5ea68e`.

Postcheck result:

- `one_ring_exact_executable_rule_rows=1`
- `one_ring_legacy_enabled_draw_engine_rows=0`
- `orims_chant_exact_executable_rule_rows=1`
- `orims_chant_legacy_enabled_silence_rows=0`
- `card_intelligence_snapshot` reflects the new exact rules first and the old
  broad rules as `deprecated`/`disabled`.

## SQLite/Hermes Sync

Command:

```bash
python3 docs/hermes-analysis/manaloom-knowledge/scripts/sync_battle_card_rules_pg.py --apply-sqlite-from-pg --include-needs-review --only-card "The One Ring" --only-card "Orim's Chant" --report docs/hermes-analysis/master_optimizer_reports/battle_card_rules_sqlite_from_pg_pg025_one_ring_orims_20260622_152500.json
```

Sync result:

- `pg_rows_loaded=6`
- `sqlite_inserted_or_updated=6`
- `canonical_snapshot_rows_exported=3193`

Runtime check:

- `The One Ring` resolves from SQLite/PG with
  `_rule_logical_key=battle_rule_v1:a71907ee296b5801e92e8d7f1940dba1`,
  `_rule_source=curated`, `_rule_review_status=verified`,
  `_rule_execution_status=auto`,
  `protection_from_everything_on_enter=true`, `draw_on_enter=false`,
  `activated_burden_draw=true`, and `activation_requires_tap=true`.
- `Orim's Chant` resolves from SQLite/PG with
  `_rule_logical_key=battle_rule_v1:2332a82b6395a065b6516702d3e326c7`,
  `_rule_source=curated`, `_rule_review_status=verified`,
  `_rule_execution_status=auto`, `kicker_prevent_attacks=true`,
  `prevent_attacks_if_kicked=true`, and `kicker_cost={W}`.

## Test Evidence

- `python3 -m py_compile docs/hermes-analysis/manaloom-knowledge/scripts/battle_analyst_v9.py docs/hermes-analysis/manaloom-knowledge/scripts/battle_action_critic.py docs/hermes-analysis/manaloom-knowledge/scripts/battle_replay_v10_3.py docs/hermes-analysis/manaloom-knowledge/scripts/battle_stack_casting_tests.py docs/hermes-analysis/manaloom-knowledge/scripts/battle_card_specific_tests.py docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_replay_v10_3_renderer.py`
  passed.
- `PYTHONPATH=docs/hermes-analysis/manaloom-knowledge/scripts python3 docs/hermes-analysis/manaloom-knowledge/scripts/battle_stack_casting_tests.py`
  passed.
- `PYTHONPATH=docs/hermes-analysis/manaloom-knowledge/scripts python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_replay_v10_3_renderer.py`
  passed, including `test_final_player_summary_includes_hand_card_names` and
  `test_renderer_explains_kicked_orims_chant_attack_prevention`.
- `PYTHONPATH=docs/hermes-analysis/manaloom-knowledge/scripts python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_event_contract_static_audit.py`
  passed, `7 tests passed`.
- `PYTHONPATH=docs/hermes-analysis/manaloom-knowledge/scripts python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_decision_trace_taxonomy_audit.py`
  passed, `3 tests passed`.
- `PYTHONPATH=docs/hermes-analysis/manaloom-knowledge/scripts python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_runtime_pg_rule_fallback_for_promoted_hotfixes.py`
  passed, `3 tests`.

## Battle Evidence

Recurring post-sync run:

- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260622_152408/summary.json`
- `run_profile=recurring_16_seed`
- `battle_replay_final_status=trusted_for_strategy_learning`
- `mandatory_gate_divergences=[]`
- `seeds_completed=16`
- tests `pass=18`
- Lorehold `2/16`, opponents `14/16`
- opponent combat pressure to Lorehold `214`, to other players `7`

Controlled comparable run:

- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260622_152901/summary.json`
- `run_profile=pg025_one_ring_orims_official_16_seed`
- `invocation_kind=codex_pg025_one_ring_orims_official_16_seed`
- `battle_replay_final_status=trusted_for_strategy_learning`
- `mandatory_gate_divergences=[]`
- `seeds_completed=16`
- tests `pass=18`
- Lorehold `0/16`, opponents `16/16`
- opponent combat pressure to Lorehold `296`, to other players `4`
- low-confidence seeds remain `63231318` and `63231327`

Replay proof:

- `20260622_152901/seed_63231322/replay.txt` lines `239-244` show Lorehold
  casting/resolving `The One Ring`, then activating burden draw. Line `293`
  shows `one_ring_burden_life_loss`. Final lines `329-332` include
  `HandCards=[...]`.
- `20260622_152901/seed_63231322/replay.events.jsonl` lines `453-461` show
  `The One Ring` using
  `rule_logical_key=battle_rule_v1:a71907ee296b5801e92e8d7f1940dba1` and
  granting protection from everything.
- `20260622_152901/seed_63231314/replay.txt` lines `243-247` show Lorehold
  casting kicked `Orim's Chant` against Dargo and preventing 3 attackers before
  declare attackers. Lines `261-265` show Dargo using the same rule against
  Lorehold.
- `20260622_152901/seed_63231314/replay.events.jsonl` lines `533-537` show
  `Orim's Chant` using
  `rule_logical_key=battle_rule_v1:2332a82b6395a065b6516702d3e326c7` with
  `additional_costs=["{W}"]`, `modes=["kicker:{W}"]`, and
  `attack_prevented_by_orims_chant`.

## Current Reading

- PG025 is applied, postchecked, synced to SQLite/Hermes, and validated in
  trusted battle artifacts.
- The rule/data issue is closed for `The One Ring` and `Orim's Chant`.
- The deck issue remains open: the comparable 16-seed window remains `0/16`
  for Lorehold after the durable rule sync.
- The recurring post-sync run reached `2/16`, but that uses a different seed
  window and is not a direct before/after comparison.
- Next work should be deck-quality analysis under table focus, using the
  controlled `20260622_152901` artifact plus the prior gate-clean Magus+Sphere
  candidate `20260622_142625`.

## Rollback

- Rollback SQL exists and restores the captured pre-apply `card_battle_rules`
  rows from
  `manaloom_deploy_audit.pg025_one_ring_orims_battle_rules_20260622_152115`.
- Rollback was not executed because precheck, apply, postcheck, SQLite sync,
  runtime check, tests, and post-sync battle artifacts passed.
