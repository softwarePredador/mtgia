# PG656 XMage Batch PostgreSQL Package

Status: `applied_postchecked_synced_validated`.

This package was generated from XMage batch proposals and was applied against
the new-server PostgreSQL target after precheck approval.

- Generated at: `2026-07-08T12:43:41+00:00`
- Selected cards: `["Goblin Grenade", "Shrapnel Blast"]`
- Families: `{"xmage_fixed_damage_spell": 2}`

Files:

- precheck: `docs/hermes-analysis/master_optimizer_reports/pg656_damage_sacrifice_artifact_goblin_new_server_package_precheck.sql`
- apply: `docs/hermes-analysis/master_optimizer_reports/pg656_damage_sacrifice_artifact_goblin_new_server_package_apply.sql`
- rollback: `docs/hermes-analysis/master_optimizer_reports/pg656_damage_sacrifice_artifact_goblin_new_server_package_rollback.sql`
- postcheck: `docs/hermes-analysis/master_optimizer_reports/pg656_damage_sacrifice_artifact_goblin_new_server_package_postcheck.sql`
- manifest: `docs/hermes-analysis/master_optimizer_reports/pg656_damage_sacrifice_artifact_goblin_new_server_package_manifest.json`
- package: `docs/hermes-analysis/master_optimizer_reports/pg656_damage_sacrifice_artifact_goblin_new_server_package_package.md`

Apply gate:

- Apply completed on `2026-07-08`; do not rerun apply SQL unless a fresh
  precheck justifies it.
- Precheck found `2` target rows and no existing rule rows.
- Apply committed `2` promoted rule rows and deprecated `0` shadow rows.
- Postcheck confirmed `2` promoted verified/auto rows with matching
  `oracle_hash`.
- PG -> Hermes/SQLite sync loaded `5932` PostgreSQL rows, wrote `5918` SQLite
  rows, and exported `5895` canonical snapshot rows.
- E2E package validation passed PostgreSQL, SQLite, canonical snapshot, and
  `runtime_get_card_effect` for both selected cards.
