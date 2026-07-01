# PG299 XMage Batch PostgreSQL Package

Status: `applied_synced_e2e_passed`.

This package was generated from XMage batch proposals, applied to PostgreSQL,
synced to Hermes SQLite, and validated end to end.

- Generated at: `2026-07-01T11:09:09+00:00`
- Selected cards: `["Cadaver Imp", "Griffin Dreamfinder", "Mnemonic Wall", "Sanctum Gargoyle"]`
- Families: `{"xmage_creature_etb_graveyard_to_hand": 4}`

Files:

- precheck: `docs/hermes-analysis/master_optimizer_reports/pg299_xmage_creature_etb_recursion_keyword_wave_precheck.sql`
- apply: `docs/hermes-analysis/master_optimizer_reports/pg299_xmage_creature_etb_recursion_keyword_wave_apply.sql`
- rollback: `docs/hermes-analysis/master_optimizer_reports/pg299_xmage_creature_etb_recursion_keyword_wave_rollback.sql`
- postcheck: `docs/hermes-analysis/master_optimizer_reports/pg299_xmage_creature_etb_recursion_keyword_wave_postcheck.sql`
- manifest: `docs/hermes-analysis/master_optimizer_reports/pg299_xmage_creature_etb_recursion_keyword_wave_manifest.json`
- package: `docs/hermes-analysis/master_optimizer_reports/pg299_xmage_creature_etb_recursion_keyword_wave_package.md`

Apply/sync/E2E result:

- PostgreSQL precheck: `4/4` target rows found, `0` expected rows already
  present, and `0` shadow rows scheduled for deprecation.
- PostgreSQL postcheck: `4/4` promoted rows, `4/4` verified/auto,
  `4/4` matching Oracle hash, and `0` backup rows.
- PG -> Hermes/SQLite sync: `6724` PostgreSQL rows loaded, `6518` SQLite rows
  inserted/updated, and `4337` canonical snapshot rows exported.
- E2E validation: PostgreSQL `4/4`, SQLite `4/4`, canonical snapshot `4/4`,
  and runtime `get_card_effect` `4/4`.
