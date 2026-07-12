# PG851 Activated Target-Player Mill Evidence - 2026-07-12

Scope: promote the XMage-backed permanent activated target-player mill family
into ManaLoom runtime and PostgreSQL, then clear residual trusted executable
rules missing `oracle_hash`.

## Runtime And Mapper

- Added exact scope:
  `xmage_permanent_simple_activated_target_player_mill_v1`.
- Added source split/parser support for simple activated permanents using
  `MillCardsTargetEffect`, `SimpleActivatedAbility`, fixed mana/tap costs,
  source tap, and tap-target costs.
- Added battle runtime execution for:
  - fixed target-player mill count;
  - activation mana cost;
  - source tap;
  - tap-cost targets such as "tap an untapped Merfolk you control";
  - mill event evidence.
- Added package E2E scenario generation and runner:
  `simple_activated_target_player_mill`.

## PG851 Package

Files:

- `docs/hermes-analysis/master_optimizer_reports/pg851_activated_target_player_mill_new_server_precheck.sql`
- `docs/hermes-analysis/master_optimizer_reports/pg851_activated_target_player_mill_new_server_apply.sql`
- `docs/hermes-analysis/master_optimizer_reports/pg851_activated_target_player_mill_new_server_postcheck.sql`
- `docs/hermes-analysis/master_optimizer_reports/pg851_activated_target_player_mill_new_server_rollback.sql`
- `docs/hermes-analysis/master_optimizer_reports/pg851_activated_target_player_mill_new_server_manifest.json`
- `docs/hermes-analysis/master_optimizer_reports/pg851_activated_target_player_mill_new_server_package.md`

Promoted cards:

- Ambassador Laquatus
- Cathartic Adept
- Drowner of Secrets
- Hair-Strung Koto
- Merfolk Mesmerist
- Millstone
- Tower of Murmurs
- Vedalken Entrancer

SQL evidence:

- Precheck: `8/8` target cards resolved, `0` shadow rows.
- Apply: `upserted_rows=8`, `deprecated_shadow_rows=0`.
- Postcheck: every promoted row has `review_status=verified`,
  `execution_status=auto`, and matching `oracle_hash`.

## PG851B Hash Backfill

Files:

- `docs/hermes-analysis/master_optimizer_reports/pg851b_trusted_rule_oracle_hash_backfill_new_server_precheck.sql`
- `docs/hermes-analysis/master_optimizer_reports/pg851b_trusted_rule_oracle_hash_backfill_new_server_apply.sql`
- `docs/hermes-analysis/master_optimizer_reports/pg851b_trusted_rule_oracle_hash_backfill_new_server_postcheck.sql`
- `docs/hermes-analysis/master_optimizer_reports/pg851b_trusted_rule_oracle_hash_backfill_new_server_rollback.sql`
- `docs/hermes-analysis/master_optimizer_reports/pg851b_trusted_rule_oracle_hash_backfill_new_server_package.md`

SQL evidence:

- Precheck: `32` verified executable rows missing `oracle_hash`,
  `32` uniquely matchable with Oracle text, `0` unsafe rows.
- Apply: `backup_rows=32`, `updated_rows=32`.
- Postcheck: `verified_executable_rules_missing_oracle_hash=0`.

## Sync And Validation

- Battle-rule sync:
  `docs/hermes-analysis/master_optimizer_reports/pg851b_trusted_rule_oracle_hash_backfill_new_server_sync_battle_rules_report.json`
  - PostgreSQL target: `127.0.0.1:15432/halder`
  - `pg_rows_loaded=10553`
  - `sqlite_inserted_or_updated=10331`
  - canonical snapshot exported rows: `7817`
- Metadata sync:
  `docs/hermes-analysis/master_optimizer_reports/pg851_activated_target_player_mill_new_server_metadata_sync_report.json`
  - PostgreSQL target: `127.0.0.1:15432/halder`
  - deck-card backfill matched: `2699/2699`

Validation evidence:

- E2E:
  `docs/hermes-analysis/master_optimizer_reports/pg851_activated_target_player_mill_new_server_e2e_after_pg851b.md`
  - status: `pass`
  - scenarios: `8`
  - events: `16`
  - Drowner of Secrets and Hair-Strung Koto tapped separate cost targets.
- XMage strategy audit:
  `docs/hermes-analysis/master_optimizer_reports/xmage_strategy_consistency_audit_20260712_pg851_activated_target_player_mill_new_server.md`
  - status: `pass`
  - checks: `26/26`
- PG/Hermes/SQLite contract audit:
  `docs/hermes-analysis/master_optimizer_reports/pg_hermes_sqlite_contract_audit_20260712_post_pg851b_activated_target_player_mill_new_server_final.md`
  - status: `pass`
  - checks: `51/51`
  - PG and SQLite trusted executable rules missing `oracle_hash`: `0`

## Global Queue Impact

Readiness:

- Report:
  `docs/hermes-analysis/master_optimizer_reports/global_card_oracle_battle_readiness_20260712_post_pg851b_activated_target_player_mill_new_server_final.md`
- `battle_and_oracle_ready`: `6766`
- `battle_family_mapper_required`: `27028`
- `trusted_rule_oracle_hash_backfill`: removed from active lane counts.

XMage authoritative queue:

- Report:
  `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_adaptation_queue_20260712_post_pg851b_activated_target_player_mill_commander_legal.md`
- `target_identity_count`: `24117`
- `xmage_authoritative_source_count`: `23804`
- `xmage_authoritative_adapter_required_count`: `23804`
- `xmage_authoritative_parser_gap_count`: `0`
- `xmage_missing_source_exception_count`: `313`
