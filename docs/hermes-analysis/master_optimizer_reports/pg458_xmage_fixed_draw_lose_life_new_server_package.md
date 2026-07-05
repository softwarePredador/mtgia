# pg458 XMage Batch PostgreSQL Package

Status: `prepared_read_only_pending_apply_approval`.

This package was generated from XMage batch proposals. No SQL was executed by the builder.

- Generated at: `2026-07-05T00:31:36+00:00`
- Selected cards: `["Ambition's Cost", "Ancient Craving", "Blood Pact", "Harrowing Journey", "Night's Whisper", "Painful Lesson", "Sign in Blood", "Succumb to Temptation"]`
- Families: `{"xmage_fixed_draw_lose_life_spell": 8}`

Files:

- precheck: `../../master_optimizer_reports/pg458_xmage_fixed_draw_lose_life_new_server_precheck.sql`
- apply: `../../master_optimizer_reports/pg458_xmage_fixed_draw_lose_life_new_server_apply.sql`
- rollback: `../../master_optimizer_reports/pg458_xmage_fixed_draw_lose_life_new_server_rollback.sql`
- postcheck: `../../master_optimizer_reports/pg458_xmage_fixed_draw_lose_life_new_server_postcheck.sql`
- manifest: `../../master_optimizer_reports/pg458_xmage_fixed_draw_lose_life_new_server_manifest.json`
- package: `../../master_optimizer_reports/pg458_xmage_fixed_draw_lose_life_new_server_package.md`

Apply gate:

- Do not run apply SQL without explicit approval for the exact command.
- Required sequence after approval: precheck, apply, postcheck, PG -> SQLite sync, focused/family tests, affected deck coherence audit.
