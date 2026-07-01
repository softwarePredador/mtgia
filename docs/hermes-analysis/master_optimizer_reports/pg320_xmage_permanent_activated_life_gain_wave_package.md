# PG320 XMage Batch PostgreSQL Package

Status: `applied_synced_validated`.

This package was generated from XMage batch proposals, applied through the
standard evidence runner, synced to Hermes/SQLite, and validated E2E.

- Generated at: `2026-07-01T17:51:32+00:00`
- Selected cards: `["Bottle Gnomes", "Braidwood Cup", "Brindle Boar", "Dedicated Martyr", "Font of Vigor", "Fountain of Youth", "Marble Chalice", "Silent Attendant", "Soulmender", "Starlight Invoker", "Stone Haven Medic", "Tanglebloom", "Tower of Eons", "Zarichi Tiger"]`
- Families: `{"xmage_permanent_simple_activated_life_gain": 14}`

Files:

- precheck: `docs/hermes-analysis/master_optimizer_reports/pg320_xmage_permanent_activated_life_gain_wave_precheck.sql`
- apply: `docs/hermes-analysis/master_optimizer_reports/pg320_xmage_permanent_activated_life_gain_wave_apply.sql`
- rollback: `docs/hermes-analysis/master_optimizer_reports/pg320_xmage_permanent_activated_life_gain_wave_rollback.sql`
- postcheck: `docs/hermes-analysis/master_optimizer_reports/pg320_xmage_permanent_activated_life_gain_wave_postcheck.sql`
- manifest: `docs/hermes-analysis/master_optimizer_reports/pg320_xmage_permanent_activated_life_gain_wave_manifest.json`
- package: `docs/hermes-analysis/master_optimizer_reports/pg320_xmage_permanent_activated_life_gain_wave_package.md`

Apply gate:

- Approval source: active global XMage -> ManaLoom goal.
- PostgreSQL apply evidence:
  `docs/hermes-analysis/master_optimizer_reports/pg320_xmage_permanent_activated_life_gain_wave_pg_apply_evidence.md`
- PG -> Hermes/SQLite battle-rules sync:
  `docs/hermes-analysis/master_optimizer_reports/pg320_xmage_permanent_activated_life_gain_wave_battle_rules_pg_to_sqlite_sync.json`
- PG card metadata sync:
  `docs/hermes-analysis/master_optimizer_reports/pg320_xmage_permanent_activated_life_gain_wave_pg_to_sqlite_sync.json`
- E2E validation:
  `docs/hermes-analysis/master_optimizer_reports/pg320_xmage_permanent_activated_life_gain_wave_e2e_validation.md`

Measured result:

- PostgreSQL postcheck: `14/14` promoted rows, `14/14` verified/auto rows,
  `14/14` matching Oracle hash rows, and `0` backup rows.
- Sync: battle rules loaded `3512` PostgreSQL rows, inserted/updated `3511`
  SQLite rows, and exported `4707` canonical snapshot rows.
- E2E: PostgreSQL source of truth, SQLite Hermes cache, canonical snapshot
  fallback, and runtime `get_card_effect` all passed for `14/14`.
