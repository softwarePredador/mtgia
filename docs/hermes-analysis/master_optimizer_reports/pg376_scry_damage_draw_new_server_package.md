# PG376 XMage Batch PostgreSQL Package

Status: `prepared_read_only_pending_apply_approval`.

This package was generated from XMage batch proposals. No SQL was executed by the builder.

- Generated at: `2026-07-04T01:16:04+00:00`
- Selected cards: `["Behold the Multiverse", "Deliberate", "Ember Shot", "Foresee", "Introduction to Prophecy", "Opt", "Playful Shove", "Preordain", "Scour All Possibilities", "Serum Visions", "Tamiyo's Epiphany", "Zap"]`
- Families: `{"xmage_fixed_damage_draw_card_spell": 3, "xmage_fixed_scry_draw_card_spell": 9}`

Files:

- precheck: `docs/hermes-analysis/master_optimizer_reports/pg376_scry_damage_draw_new_server_precheck.sql`
- apply: `docs/hermes-analysis/master_optimizer_reports/pg376_scry_damage_draw_new_server_apply.sql`
- rollback: `docs/hermes-analysis/master_optimizer_reports/pg376_scry_damage_draw_new_server_rollback.sql`
- postcheck: `docs/hermes-analysis/master_optimizer_reports/pg376_scry_damage_draw_new_server_postcheck.sql`
- manifest: `docs/hermes-analysis/master_optimizer_reports/pg376_scry_damage_draw_new_server_manifest.json`
- package: `docs/hermes-analysis/master_optimizer_reports/pg376_scry_damage_draw_new_server_package.md`

Apply gate:

- Do not run apply SQL without explicit approval for the exact command.
- Required sequence after approval: precheck, apply, postcheck, PG -> SQLite sync, focused/family tests, affected deck coherence audit.
