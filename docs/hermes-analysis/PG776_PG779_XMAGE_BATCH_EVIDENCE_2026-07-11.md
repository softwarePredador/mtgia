# PG776-PG779 XMage Batch Evidence - 2026-07-11

Status: applied on new-server PostgreSQL target via `server/bin/with_new_server_pg.sh`.

Database target reported by sync/E2E: `127.0.0.1:15432/halder`.

## Applied Packages

| Package | Cards/Rows | Scope | Apply Evidence |
| --- | ---: | --- | --- |
| PG776 | 4 | `xmage_destroy_target_and_dynamic_controller_gain_life_spell_v1` | `pg776_destroy_dynamic_gain_life_new_server_*` |
| PG777B | 55 rule rows | trusted `oracle_hash` backfill | `pg777b_trusted_rule_oracle_hash_backfill_new_server_*` |
| PG778 | 1 | Aerial Assault dynamic flying-count life gain | `pg778_aerial_assault_dynamic_flying_life_gain_new_server_*` |
| PG779 | 1 | Shower of Arrows destroy + scry | `pg779_shower_of_arrows_destroy_scry_new_server_*` |

## Current Global Counts

Source: `docs/hermes-analysis/master_optimizer_reports/global_card_oracle_battle_readiness_20260711_post_pg779_shower_of_arrows_new_server.json`.

- `battle_and_oracle_ready`: 6526
- `battle_family_mapper_required`: 27350
- `snapshot_has_verified_rule`: 6551
- `snapshot_has_any_rule`: 7717

Source: `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_adaptation_queue_20260711_post_pg779_shower_of_arrows_new_server.json`.

- `xmage_authoritative_adapter_required_count`: 24114
- `xmage_authoritative_parser_gap_count`: 0
- `xmage_missing_source_exception_count`: 313

## Validation Evidence

Focused tests:

```text
python3 -m py_compile xmage_authoritative_exact_scope_split.py xmage_batch_pg_package_builder.py battle_package_end_to_end_validation.py battle_analyst_v9.py global_card_oracle_battle_readiness.py xmage_authoritative_adaptation_queue.py
python3 -m unittest test_xmage_authoritative_exact_scope_split.py test_battle_runtime_surface_manifest.py test_runtime_pg_rule_fallback_for_promoted_hotfixes.py
```

Result: `1061 tests`, `OK`, `3 skipped`.

PG778 E2E:

- PostgreSQL source of truth: pass
- SQLite Hermes cache: pass
- Canonical snapshot fallback: pass
- Runtime `get_card_effect`: pass
- Battle execution: pass
- Scenario result: legal tapped creature removed, illegal untapped creature preserved, controller gained 3 life from three flying creatures.

PG779 E2E:

- PostgreSQL source of truth: pass
- SQLite Hermes cache: pass
- Canonical snapshot fallback: pass
- Runtime `get_card_effect`: pass
- Battle execution: pass
- Scenario result: legal artifact removed, illegal land preserved, `scry_resolved` count 1 emitted.

Final audits:

- `xmage_strategy_consistency_audit_20260711_post_pg779_shower_of_arrows_new_server_final`: pass, 26/26
- `pg_hermes_sqlite_contract_audit_20260711_post_pg779_shower_of_arrows_new_server_final`: pass, 51/51
- `operational_surface_alignment_audit_20260711_post_pg779_shower_of_arrows_new_server_final`: pass
- `legacy_contamination_audit_20260711_post_pg779_shower_of_arrows_new_server_final`: pass

## Residual Work

The goal remains active. The post-PG779 splitter reports no safe batch PostgreSQL package and only three partial mana proposals:

- Codie, Vociferous Codex
- Sage of the Maze
- Strixhaven Stadium

Those are intentionally not promoted as mana-only because each has unmodeled auxiliary behavior requiring family/card runtime before executable truth.
