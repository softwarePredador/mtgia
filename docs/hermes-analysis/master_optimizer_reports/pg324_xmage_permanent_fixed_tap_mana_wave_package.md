# PG324 XMage Batch PostgreSQL Package

Status: `applied_pg324_with_evidence`.

This package was generated from XMage batch proposals. The builder itself did
not execute SQL; the package was later applied through the documented
precheck/apply/postcheck/sync flow.

- Generated at: `2026-07-01T19:24:42+00:00`
- Selected cards: `["Apprentice Wizard", "Fyndhorn Elder", "Golgari Signet", "Greenweaver Druid", "Gruul Signet", "Gyre Engineer", "Knotvine Mystic", "Kozilek's Channeler", "Llanowar Tribe", "Nantuko Elder", "Orzhov Signet", "Palladium Myr", "Rakdos Signet", "Selesnya Signet", "Sunastian Falconer", "Weaver of Currents"]`
- Families: `{"xmage_simple_mana_source_permanent": 16}`

Files:

- precheck: `docs/hermes-analysis/master_optimizer_reports/pg324_xmage_permanent_fixed_tap_mana_wave_precheck.sql`
- apply: `docs/hermes-analysis/master_optimizer_reports/pg324_xmage_permanent_fixed_tap_mana_wave_apply.sql`
- rollback: `docs/hermes-analysis/master_optimizer_reports/pg324_xmage_permanent_fixed_tap_mana_wave_rollback.sql`
- postcheck: `docs/hermes-analysis/master_optimizer_reports/pg324_xmage_permanent_fixed_tap_mana_wave_postcheck.sql`
- manifest: `docs/hermes-analysis/master_optimizer_reports/pg324_xmage_permanent_fixed_tap_mana_wave_manifest.json`
- package: `docs/hermes-analysis/master_optimizer_reports/pg324_xmage_permanent_fixed_tap_mana_wave_package.md`
- apply evidence: `docs/hermes-analysis/master_optimizer_reports/pg324_xmage_permanent_fixed_tap_mana_wave_pg_apply_evidence.md`

Apply history:

- PostgreSQL precheck found `16/16` target card rows.
- PostgreSQL apply promoted `16` verified/auto executable rows and deprecated
  `14` stale shadow rows.
- PostgreSQL postcheck, PG -> Hermes/SQLite sync, focused tests, and E2E
  validation are recorded in the apply evidence artifact.
