# pg271 XMage Batch PostgreSQL Package

Status: `applied_synced`.

This package was generated from XMage batch proposals, then applied to PostgreSQL and synced to Hermes/SQLite on 2026-06-30.

- Generated at: `2026-06-30T08:55:10+00:00`
- Selected cards: `["Hidden Retreat"]`
- Families: `{"damage_prevention_shield": 1}`

Files:

- precheck: `docs/hermes-analysis/master_optimizer_reports/pg271_hidden_retreat_damage_prevention_20260630_precheck.sql`
- apply: `docs/hermes-analysis/master_optimizer_reports/pg271_hidden_retreat_damage_prevention_20260630_apply.sql`
- rollback: `docs/hermes-analysis/master_optimizer_reports/pg271_hidden_retreat_damage_prevention_20260630_rollback.sql`
- postcheck: `docs/hermes-analysis/master_optimizer_reports/pg271_hidden_retreat_damage_prevention_20260630_postcheck.sql`
- manifest: `docs/hermes-analysis/master_optimizer_reports/pg271_hidden_retreat_damage_prevention_20260630_manifest.json`
- package: `docs/hermes-analysis/master_optimizer_reports/pg271_hidden_retreat_damage_prevention_20260630_package.md`

Apply gate:

- Completed sequence: precheck, apply, postcheck, PG -> SQLite sync, focused/family tests, affected deck coherence audit.
- Apply result: `deprecated_shadow_rows=2`, `upserted_rows=1`.
- Postcheck result: promoted Hidden Retreat row `1/1`, verified/auto `1/1`, oracle hash `1/1`, backup rows `2`.
- Sync result: `pg_rows_loaded=1`, `sqlite_inserted_or_updated=1`, canonical snapshot rows `3284`.
