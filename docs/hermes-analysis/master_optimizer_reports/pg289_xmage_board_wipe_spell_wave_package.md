# PG289 XMage Batch PostgreSQL Package

Status: `prepared_read_only_pending_apply_approval`.

This package was generated from XMage batch proposals. No SQL was executed by the builder.

- Generated at: `2026-07-01T08:42:07+00:00`
- Selected cards: `["Back to Nature", "Blazing Volley", "Cleanfall", "Creeping Corrosion", "Damnation", "Day of Judgment", "Desert Sandstorm", "Devastation", "Purify", "Pyroclasm", "Storm's Wrath", "Tempest of Light", "Tranquility"]`
- Families: `{"xmage_damage_all_spell": 4, "xmage_destroy_all_spell": 9}`

Files:

- precheck: `docs/hermes-analysis/master_optimizer_reports/pg289_xmage_board_wipe_spell_wave_precheck.sql`
- apply: `docs/hermes-analysis/master_optimizer_reports/pg289_xmage_board_wipe_spell_wave_apply.sql`
- rollback: `docs/hermes-analysis/master_optimizer_reports/pg289_xmage_board_wipe_spell_wave_rollback.sql`
- postcheck: `docs/hermes-analysis/master_optimizer_reports/pg289_xmage_board_wipe_spell_wave_postcheck.sql`
- manifest: `docs/hermes-analysis/master_optimizer_reports/pg289_xmage_board_wipe_spell_wave_manifest.json`
- package: `docs/hermes-analysis/master_optimizer_reports/pg289_xmage_board_wipe_spell_wave_package.md`

Apply gate:

- Do not run apply SQL without explicit approval for the exact command.
- Required sequence after approval: precheck, apply, postcheck, PG -> SQLite sync, focused/family tests, affected deck coherence audit.
