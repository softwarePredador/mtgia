# PG593 Multi-Target Damage Apply Evidence

Generated UTC: 2026-07-07

## Scope

PG593 promoted the XMage-authoritative fixed multi-target damage spell scope:

- Runtime scope: `xmage_fixed_multi_target_damage_spell_v1`
- Effect: `multi_target_damage`
- XMage effect class: `DamageMultiEffect`
- Selected cards: `15`
- Cards: Aerial Volley; Arc Lightning; Boulderfall; Chandra's Pyrohelix; Deft Dismissal; Fire at Will; Flames of the Firebrand; Forked Bolt; Forked Lightning; Ignite Disorder; Magic Missile; Pyrotechnics; Roil's Retribution; Spreading Flames; Twin Bolt.

## Runtime And Splitter

- `xmage_authoritative_exact_scope_split.py` now splits fixed `DamageMultiEffect` spells only when Oracle and XMage agree on fixed amount, target family, target count, and `up_to_count`.
- X damage, unsupported target phrases, composite effect classes, and unsupported additional costs remain blocked.
- `battle_analyst_v9.py` now executes `multi_target_damage` by selecting legal targets, assigning divided damage, applying damage replacement hooks per target, resolving creature death, planeswalker loyalty loss, battle defense loss, player damage, and lifelink.
- `xmage_batch_pg_package_builder.py` and `battle_package_end_to_end_validation.py` now build and execute focused `multi_target_damage` scenarios.

## Tests

Focused tests passed before apply:

- `python3 -m py_compile` for the splitter, package builder, E2E validator, and battle runtime.
- `python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_xmage_authoritative_exact_scope_split.py`: 716 tests passed.
- `python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_xmage_batch_pg_package_builder.py`: passed.
- `python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_xmage_exact_scope_runtime.py`: 367 tests passed.

## PostgreSQL Apply

Target: `127.0.0.1:15432/halder`

- Package: `docs/hermes-analysis/master_optimizer_reports/pg593_multi_target_damage_new_server_package_manifest.json`
- Precheck: 15 target card rows, 0 existing expected executable rows, 0 shadow rows to deprecate.
- Apply: 15 rows upserted, 0 shadow rows deprecated.
- Re-run postcheck on 2026-07-07:
  - 15/15 promoted rule rows.
  - 15/15 `review_status='verified'` and `execution_status='auto'`.
  - 15/15 matching `oracle_hash`.
  - 0 backup rows.

## Sync And E2E

- PG -> SQLite sync: `docs/hermes-analysis/master_optimizer_reports/pg593_multi_target_damage_new_server_pg_to_sqlite_sync.json`
  - `pg_rows_loaded`: 9343
  - `sqlite_inserted_or_updated`: 9107
  - `canonical_snapshot_rows_exported`: 6787
- Metadata sync: `docs/hermes-analysis/master_optimizer_reports/pg593_multi_target_damage_new_server_metadata_sync.json`
  - `deck_cards` matched: 2699/2699
  - `card_id_rows_updated`: 108
- E2E: `docs/hermes-analysis/master_optimizer_reports/pg593_multi_target_damage_new_server_e2e.md`
  - Status: `pass`
  - PostgreSQL rows: 15
  - SQLite rows: 15
  - Snapshot cards: 15
  - Runtime lookup cards: 15
  - Battle execution: 15 scenarios, 74 events

## Queue And Audits

- Queue after PG593: `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_adaptation_queue_20260707_post_pg593_multi_target_damage_new_server_commander_legal.md`
  - `target_identity_count`: 25198
  - `xmage_authoritative_source_count`: 24884
  - `xmage_missing_source_exception_count`: 314
  - `xmage_authoritative_parser_gap_count`: 0
  - `xmage_authoritative_adapter_required_count`: 24884
  - `multi_target_damage::xmage_multi_target_damage_variant_review_v1`: 46
- Probe after PG593: `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_exact_scope_split_20260707_probe_post_pg593_new_server.md`
  - `proposal_count`: 0
  - `safe_for_batch_pg_package_count`: 0
- Final audits:
  - XMage strategy consistency: 26/26 pass.
  - Operational surface alignment: pass.
  - Legacy contamination audit: pass.
  - PG/Hermes/SQLite contract: 51/51 pass.
  - `./scripts/quality_gate.sh server-target`: pass.
