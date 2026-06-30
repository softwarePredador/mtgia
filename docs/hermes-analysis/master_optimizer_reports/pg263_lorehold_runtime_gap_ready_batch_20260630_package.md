# pg263 XMage Batch PostgreSQL Package

Status: `applied_and_synced_2026-06-30`.

This package was generated from XMage batch proposals. No SQL was executed by the builder.

- Generated at: `2026-06-30T05:30:53+00:00`
- Selected cards: `["Goliath Daydreamer", "Twinflame Tyrant", "Verge Rangers", "Boros Reckoner", "Terror of the Peaks", "Balefire Liege", "Firesong and Sunspeaker", "Repercussion"]`
- Families: `{"free_cast": 1, "static_damage_modifier": 1, "targeted_interaction": 5, "topdeck_play": 1}`

Files:

- precheck: `docs/hermes-analysis/master_optimizer_reports/pg263_lorehold_runtime_gap_ready_batch_20260630_precheck.sql`
- apply: `docs/hermes-analysis/master_optimizer_reports/pg263_lorehold_runtime_gap_ready_batch_20260630_apply.sql`
- rollback: `docs/hermes-analysis/master_optimizer_reports/pg263_lorehold_runtime_gap_ready_batch_20260630_rollback.sql`
- postcheck: `docs/hermes-analysis/master_optimizer_reports/pg263_lorehold_runtime_gap_ready_batch_20260630_postcheck.sql`
- manifest: `docs/hermes-analysis/master_optimizer_reports/pg263_lorehold_runtime_gap_ready_batch_20260630_manifest.json`
- package: `docs/hermes-analysis/master_optimizer_reports/pg263_lorehold_runtime_gap_ready_batch_20260630_package.md`

Apply gate:

- Completed sequence: precheck, apply, postcheck, PG -> SQLite sync, focused/family tests, E2E validation.
- Precheck output: `docs/hermes-analysis/master_optimizer_reports/pg263_lorehold_runtime_gap_ready_batch_20260630_precheck.out`.
- Apply output: `docs/hermes-analysis/master_optimizer_reports/pg263_lorehold_runtime_gap_ready_batch_20260630_apply.out`; backup rows `17`, deprecated shadow rows `12`, upserted rows `8`.
- Postcheck output: `docs/hermes-analysis/master_optimizer_reports/pg263_lorehold_runtime_gap_ready_batch_20260630_postcheck.out`; every selected card has one promoted `verified/auto` Oracle-hash row.
- PG -> SQLite sync report: `docs/hermes-analysis/master_optimizer_reports/battle_card_rules_sqlite_from_pg_pg263_lorehold_runtime_gap_ready_batch_20260630.json`.
- E2E report: `docs/hermes-analysis/master_optimizer_reports/pg263_lorehold_runtime_gap_ready_batch_20260630_e2e_validation.md`; PostgreSQL `8/8`, SQLite `8/8`, canonical snapshot `8/8`, runtime `get_card_effect` `8/8`.
