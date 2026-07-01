# PG330 XMage Batch PostgreSQL Package

Status: `applied_synced_validated`.

This package was generated from XMage batch proposals. The builder itself did
not execute SQL; the package was later applied through the PG330
precheck/apply/postcheck path and validated through PostgreSQL -> Hermes/SQLite
sync and E2E package validation.

- Generated at: `2026-07-01T20:45:00+00:00`
- Selected cards: `["Barrow Witches", "Disciple of the Sun", "Leonin Squire", "Pillardrop Rescuer", "Ragamuffin Raptor", "Scholar of the Ages", "Strongarm Thug"]`
- Families: `{"xmage_creature_etb_graveyard_to_hand": 7}`

Files:

- precheck: `docs/hermes-analysis/master_optimizer_reports/pg330_xmage_creature_etb_recursion_extended_wave_precheck.sql`
- apply: `docs/hermes-analysis/master_optimizer_reports/pg330_xmage_creature_etb_recursion_extended_wave_apply.sql`
- rollback: `docs/hermes-analysis/master_optimizer_reports/pg330_xmage_creature_etb_recursion_extended_wave_rollback.sql`
- postcheck: `docs/hermes-analysis/master_optimizer_reports/pg330_xmage_creature_etb_recursion_extended_wave_postcheck.sql`
- manifest: `docs/hermes-analysis/master_optimizer_reports/pg330_xmage_creature_etb_recursion_extended_wave_manifest.json`
- package: `docs/hermes-analysis/master_optimizer_reports/pg330_xmage_creature_etb_recursion_extended_wave_package.md`

Apply and validation result:

- PostgreSQL package rows promoted: `7/7`.
- Promoted rows verified/auto: `7/7`.
- Promoted rows with matching Oracle hash: `7/7`.
- PG -> Hermes/SQLite sync loaded `7224` PostgreSQL rules,
  inserted/updated `7018` SQLite rows, and exported `4815` canonical snapshot
  rows.
- E2E package validation: PostgreSQL `7/7`, SQLite `7/7`, canonical snapshot
  `7/7`, runtime `get_card_effect` `7/7`.
- Evidence: `docs/hermes-analysis/master_optimizer_reports/pg330_xmage_creature_etb_recursion_extended_wave_pg_apply_evidence.md`.
