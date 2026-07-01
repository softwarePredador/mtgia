# PG300 XMage Batch PostgreSQL Package

Status: `applied_synced_e2e_passed`.

This package was generated from XMage batch proposals, applied to PostgreSQL,
synced to Hermes SQLite, and validated end to end.

- Generated at: `2026-07-01T11:20:12+00:00`
- Selected cards: `["Argivian Restoration", "Breath of Life", "False Defeat", "Obzedat's Aid", "Refurbish", "Resurrection", "Rise Again", "Zombify"]`
- Families: `{"xmage_graveyard_to_battlefield_spell": 8}`

Files:

- precheck: `docs/hermes-analysis/master_optimizer_reports/pg300_xmage_recursion_battlefield_spell_wave_precheck.sql`
- apply: `docs/hermes-analysis/master_optimizer_reports/pg300_xmage_recursion_battlefield_spell_wave_apply.sql`
- rollback: `docs/hermes-analysis/master_optimizer_reports/pg300_xmage_recursion_battlefield_spell_wave_rollback.sql`
- postcheck: `docs/hermes-analysis/master_optimizer_reports/pg300_xmage_recursion_battlefield_spell_wave_postcheck.sql`
- manifest: `docs/hermes-analysis/master_optimizer_reports/pg300_xmage_recursion_battlefield_spell_wave_manifest.json`
- package: `docs/hermes-analysis/master_optimizer_reports/pg300_xmage_recursion_battlefield_spell_wave_package.md`

Apply/sync/E2E result:

- PostgreSQL precheck: `8/8` target rows found, `0` expected rows already
  present, and `0` shadow rows scheduled for deprecation.
- PostgreSQL postcheck: `8/8` promoted rows, `8/8` verified/auto,
  `8/8` matching Oracle hash, and `0` backup rows.
- PG -> Hermes/SQLite sync: `6732` PostgreSQL rows loaded, `6526` SQLite rows
  inserted/updated, and `4345` canonical snapshot rows exported.
- E2E validation: PostgreSQL `8/8`, SQLite `8/8`, canonical snapshot `8/8`,
  and runtime `get_card_effect` `8/8`.
