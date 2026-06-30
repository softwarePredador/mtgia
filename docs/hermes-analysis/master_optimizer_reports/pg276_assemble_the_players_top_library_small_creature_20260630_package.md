# PG276 XMage Batch PostgreSQL Package

Status: `applied_synced`.

This package was generated from an exact XMage-reviewed proposal and then applied
to PostgreSQL and synced to SQLite/Hermes.

- Generated at: `2026-06-30T10:51:23+00:00`
- Selected cards: `["Assemble the Players"]`
- Families: `{"topdeck_play": 1}`

Files:

- precheck: `docs/hermes-analysis/master_optimizer_reports/pg276_assemble_the_players_top_library_small_creature_20260630_precheck.sql`
- apply: `docs/hermes-analysis/master_optimizer_reports/pg276_assemble_the_players_top_library_small_creature_20260630_apply.sql`
- rollback: `docs/hermes-analysis/master_optimizer_reports/pg276_assemble_the_players_top_library_small_creature_20260630_rollback.sql`
- postcheck: `docs/hermes-analysis/master_optimizer_reports/pg276_assemble_the_players_top_library_small_creature_20260630_postcheck.sql`
- manifest: `docs/hermes-analysis/master_optimizer_reports/pg276_assemble_the_players_top_library_small_creature_20260630_manifest.json`
- package: `docs/hermes-analysis/master_optimizer_reports/pg276_assemble_the_players_top_library_small_creature_20260630_package.md`
- sync: `docs/hermes-analysis/master_optimizer_reports/pg276_assemble_the_players_top_library_small_creature_20260630_sync.json`

Apply evidence:

- Precheck: `target_card_rows=1`, `existing_rule_rows=0`,
  `expected_rule_rows_before=0`, `would_deprecate_shadow_rows=0`.
- Apply: `upserted_rows=1`, `deprecated_shadow_rows=0`, backup rows `0`.
- Postcheck: `promoted_rule_rows=1`,
  `promoted_verified_auto_rows=1`, `promoted_oracle_hash_rows=1`.
- Sync: `pg_rows_loaded=1`, `sqlite_inserted_or_updated=1`,
  `canonical_snapshot_rows_exported=3287`.
- Runtime lookup:
  `top_library_look_any_time_cast_creature_power_2_or_less_once_each_turn_pay_cost_v1`
  from curated verified/auto rule
  `battle_rule_v1:692dcb8d1b5149bfef05a32ceb217882`.
