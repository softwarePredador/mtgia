# PG296 XMage Batch PostgreSQL Package

Status: `applied_synced_e2e_passed`.

This package was generated from XMage batch proposals, applied to PostgreSQL,
synced to Hermes SQLite, and validated end to end.

- Generated at: `2026-07-01T10:30:16+00:00`
- Selected cards: `["Prodigal Pyromancer", "Prodigal Sorcerer", "Razorfin Hunter", "Rootwater Hunter", "Viashino Fangtail", "Zuran Spellcaster"]`
- Families: `{"xmage_creature_tap_fixed_damage": 6}`

Files:

- precheck: `docs/hermes-analysis/master_optimizer_reports/pg296_xmage_creature_tap_damage_wave_precheck.sql`
- apply: `docs/hermes-analysis/master_optimizer_reports/pg296_xmage_creature_tap_damage_wave_apply.sql`
- rollback: `docs/hermes-analysis/master_optimizer_reports/pg296_xmage_creature_tap_damage_wave_rollback.sql`
- postcheck: `docs/hermes-analysis/master_optimizer_reports/pg296_xmage_creature_tap_damage_wave_postcheck.sql`
- manifest: `docs/hermes-analysis/master_optimizer_reports/pg296_xmage_creature_tap_damage_wave_manifest.json`
- package: `docs/hermes-analysis/master_optimizer_reports/pg296_xmage_creature_tap_damage_wave_package.md`

Apply/sync/E2E result:

- PostgreSQL precheck: `6/6` target rows found, `0` expected rows already
  present, `0` shadow rows scheduled for deprecation.
- PostgreSQL postcheck: `6/6` promoted rows, `6/6` verified/auto,
  `6/6` matching Oracle hash, and `0` backup rows.
- PG -> Hermes/SQLite sync: `6` PostgreSQL rows loaded, `6` SQLite rows
  inserted/updated, and `4286` canonical snapshot rows exported.
- E2E validation: PostgreSQL `6/6`, SQLite `6/6`, canonical snapshot `6/6`,
  and runtime `get_card_effect` `6/6`.
