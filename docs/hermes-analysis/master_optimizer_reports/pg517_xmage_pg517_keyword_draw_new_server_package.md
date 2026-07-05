# xmage_pg517_keyword_draw_new_server XMage Batch PostgreSQL Package

Status: `prepared_read_only_pending_apply_approval`.

This package was generated from XMage batch proposals. No SQL was executed by the builder.

- Generated at: `2026-07-05T16:34:07+00:00`
- Selected cards: `["Accelerate", "Bladebrand", "Cloak of Feathers", "Lace with Moonglove", "Leap"]`
- Families: `{"xmage_fixed_keyword_draw_card_spell": 5}`

Files:

- precheck: `docs/hermes-analysis/master_optimizer_reports/pg517_xmage_pg517_keyword_draw_new_server_precheck.sql`
- apply: `docs/hermes-analysis/master_optimizer_reports/pg517_xmage_pg517_keyword_draw_new_server_apply.sql`
- rollback: `docs/hermes-analysis/master_optimizer_reports/pg517_xmage_pg517_keyword_draw_new_server_rollback.sql`
- postcheck: `docs/hermes-analysis/master_optimizer_reports/pg517_xmage_pg517_keyword_draw_new_server_postcheck.sql`
- manifest: `docs/hermes-analysis/master_optimizer_reports/pg517_xmage_pg517_keyword_draw_new_server_manifest.json`
- package: `docs/hermes-analysis/master_optimizer_reports/pg517_xmage_pg517_keyword_draw_new_server_package.md`

Apply gate:

- Do not run apply SQL without explicit approval for the exact command.
- Required sequence after approval: precheck, apply, postcheck, PG -> SQLite sync, focused/family tests, affected deck coherence audit.
