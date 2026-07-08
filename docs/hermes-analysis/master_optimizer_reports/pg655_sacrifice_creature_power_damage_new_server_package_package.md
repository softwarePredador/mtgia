# PG655 XMage Batch PostgreSQL Package

Status: `applied_postchecked_synced_validated`.

This package was generated from XMage batch proposals and was applied against
the new-server PostgreSQL target after precheck approval.

- Generated at: `2026-07-08T12:22:28+00:00`
- Selected cards: `["Final Strike", "Fling", "Thud"]`
- Families: `{"xmage_sacrifice_creature_power_damage_spell": 3}`

Files:

- precheck: `docs/hermes-analysis/master_optimizer_reports/pg655_sacrifice_creature_power_damage_new_server_package_precheck.sql`
- apply: `docs/hermes-analysis/master_optimizer_reports/pg655_sacrifice_creature_power_damage_new_server_package_apply.sql`
- rollback: `docs/hermes-analysis/master_optimizer_reports/pg655_sacrifice_creature_power_damage_new_server_package_rollback.sql`
- postcheck: `docs/hermes-analysis/master_optimizer_reports/pg655_sacrifice_creature_power_damage_new_server_package_postcheck.sql`
- manifest: `docs/hermes-analysis/master_optimizer_reports/pg655_sacrifice_creature_power_damage_new_server_package_manifest.json`
- package: `docs/hermes-analysis/master_optimizer_reports/pg655_sacrifice_creature_power_damage_new_server_package_package.md`

Apply gate:

- Apply completed on `2026-07-08`; do not rerun apply SQL unless a fresh
  precheck justifies it.
- Precheck found `3` target rows, including `2` existing shadow rows for
  `Fling`.
- Apply committed `3` promoted rule rows and deprecated `2` shadow rows.
- Postcheck confirmed `3` promoted verified/auto rows with matching
  `oracle_hash`.
- PG -> Hermes/SQLite sync loaded `5930` PostgreSQL rows, wrote `5916` SQLite
  rows, and exported `5893` canonical snapshot rows.
- E2E package validation passed PostgreSQL, SQLite, canonical snapshot, and
  `runtime_get_card_effect` for all `3` selected cards.
