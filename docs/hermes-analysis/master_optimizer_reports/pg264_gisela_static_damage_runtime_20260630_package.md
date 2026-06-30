# pg264 XMage Batch PostgreSQL Package

Status: `applied_and_synced_2026-06-30`.

This package was generated from XMage batch proposals. No SQL was executed by the builder.

- Generated at: `2026-06-30T05:40:23+00:00`
- Selected cards: `["Gisela, Blade of Goldnight"]`
- Families: `{"static_damage_modifier": 1}`

Files:

- precheck: `docs/hermes-analysis/master_optimizer_reports/pg264_gisela_static_damage_runtime_20260630_precheck.sql`
- apply: `docs/hermes-analysis/master_optimizer_reports/pg264_gisela_static_damage_runtime_20260630_apply.sql`
- rollback: `docs/hermes-analysis/master_optimizer_reports/pg264_gisela_static_damage_runtime_20260630_rollback.sql`
- postcheck: `docs/hermes-analysis/master_optimizer_reports/pg264_gisela_static_damage_runtime_20260630_postcheck.sql`
- manifest: `docs/hermes-analysis/master_optimizer_reports/pg264_gisela_static_damage_runtime_20260630_manifest.json`
- package: `docs/hermes-analysis/master_optimizer_reports/pg264_gisela_static_damage_runtime_20260630_package.md`

Apply gate:

- Completed sequence: precheck, apply, postcheck, PG -> SQLite sync, focused runtime tests, E2E validation.
- Precheck output: `docs/hermes-analysis/master_optimizer_reports/pg264_gisela_static_damage_runtime_20260630_precheck.out`; one Oracle-hash-matched card row and two stale shadow rows identified.
- Apply output: `docs/hermes-analysis/master_optimizer_reports/pg264_gisela_static_damage_runtime_20260630_apply.out`; backup rows `2`, deprecated shadow rows `2`, upserted rows `1`.
- Postcheck output: `docs/hermes-analysis/master_optimizer_reports/pg264_gisela_static_damage_runtime_20260630_postcheck.out`; Gisela has one promoted `verified/auto` Oracle-hash row.
- PG -> SQLite sync report: `docs/hermes-analysis/master_optimizer_reports/battle_card_rules_sqlite_from_pg_pg264_gisela_static_damage_runtime_20260630.json`.
- E2E report: `docs/hermes-analysis/master_optimizer_reports/pg264_gisela_static_damage_runtime_20260630_e2e_validation.md`; PostgreSQL `1/1`, SQLite `1/1`, canonical snapshot `1/1`, runtime `get_card_effect` `1/1`.
- Runtime scope: `opponent_or_opponent_permanent_damage_doubled_self_damage_halved_v1`.
