# PG850 Graveyard Self-Exile Activate-As-Sorcery Token Evidence

- Generated at: `2026-07-12T23:07:09Z`
- Database target: `127.0.0.1:15432/halder`
- Package: `pg850_graveyard_self_exile_activate_as_sorcery_token_new_server_package`
- Scope: `xmage_graveyard_self_exile_activated_create_token_v1`
- Cards: `Dauntless Cathar`, `Fairgrounds Patrol`, `Ghoulcaller's Accomplice`, `Goldmeadow Nomad`, `Mother Bear`, `Stoic Grove-Guide`, `Suspicious Shambler`

## PostgreSQL

- Precheck: 7 target rows, 0 existing matching rule rows, 0 shadow rows to deprecate.
- Apply: `upserted_rows=7`, `deprecated_shadow_rows=0`, transaction committed.
- Postcheck: each target has `promoted_rule_rows=1`, `promoted_verified_auto_rows=1`, and `promoted_oracle_hash_rows=1`.

## Sync

- Metadata sync report: `pg850_graveyard_self_exile_activate_as_sorcery_token_new_server_metadata_sync.json`
  - requested unique names: `8555`
  - PostgreSQL cards matched: `8746`
  - SQLite cache alias rows: `8685`
  - deck_cards matched: `2699/2699`
- PG -> SQLite battle-rule sync report: `pg850_graveyard_self_exile_activate_as_sorcery_token_new_server_pg_sqlite_sync.json`
  - PG rows loaded: `10545`
  - SQLite inserted/updated: `10323`
  - canonical snapshot rows exported: `7809`

## Validation

- Package E2E: `pg850_graveyard_self_exile_activate_as_sorcery_token_new_server_e2e.md`
  - status: `pass`
  - PostgreSQL source of truth: `pass`
  - SQLite/Hermes cache: `pass`
  - canonical snapshot fallback: `pass`
  - runtime lookup: `pass`
  - battle execution: `pass`
- Battle execution proved graveyard self-exile and token creation:
  - `Dauntless Cathar`: 1 `Spirit Token`
  - `Fairgrounds Patrol`: 1 `Thopter Token`
  - `Ghoulcaller's Accomplice`: 1 `Zombie Token`
  - `Goldmeadow Nomad`: 1 `Kithkin Token`
  - `Mother Bear`: 2 `Bear Token`
  - `Stoic Grove-Guide`: 1 `Elf Token`
  - `Suspicious Shambler`: 2 `Zombie Token`
- Focused tests:
  - `test_xmage_authoritative_exact_scope_split.py -k activated_create_token`: passed
  - `test_xmage_batch_pg_package_builder.py -k activated_create_token`: passed
  - `test_xmage_exact_scope_runtime.py -k activated_create_token`: passed
  - `py_compile` for modified runtime/package/splitter scripts: passed

## Post-PG850 Global Counts

- `battle_and_oracle_ready`: `6758` (`+7` from PG849)
- `snapshot_has_verified_rule`: `6865`
- `battle_family_mapper_required`: `27036`
- `xmage_authoritative_adapter_required_count`: `23812`
- `xmage_authoritative_parser_gap_count`: `0`
- `xmage_missing_source_exception_count`: `313`
- Post-PG850 exact split recheck: `proposal_count=0`, `safe_for_batch_pg_package_count=0`

## Governance Audits

- `xmage_strategy_consistency_audit_20260712_post_pg850_graveyard_self_exile_activate_as_sorcery_token_new_server`: `pass` (`26/26`)
- `pg_hermes_sqlite_contract_audit_20260712_post_pg850_graveyard_self_exile_activate_as_sorcery_token_new_server`: `pass` (`51/51`)
- `operational_surface_alignment_audit_20260712_post_pg850_graveyard_self_exile_activate_as_sorcery_token_new_server`: `pass`
