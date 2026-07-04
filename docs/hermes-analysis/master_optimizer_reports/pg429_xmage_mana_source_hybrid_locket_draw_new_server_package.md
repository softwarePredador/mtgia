# pg429 XMage Batch PostgreSQL Package

Status: `prepared_read_only_pending_apply_approval`.

This package was generated from XMage batch proposals. No SQL was executed by the builder.

- Generated at: `2026-07-04T20:26:01+00:00`
- Selected cards: `["Azorius Locket", "Boros Locket", "Dimir Locket", "Golgari Locket", "Gruul Locket", "Izzet Locket", "Orzhov Locket", "Rakdos Locket", "Selesnya Locket", "Simic Locket"]`
- Families: `{"xmage_simple_mana_source_with_activated_draw": 10}`

Files:

- precheck: `docs/hermes-analysis/master_optimizer_reports/pg429_xmage_mana_source_hybrid_locket_draw_new_server_precheck.sql`
- apply: `docs/hermes-analysis/master_optimizer_reports/pg429_xmage_mana_source_hybrid_locket_draw_new_server_apply.sql`
- rollback: `docs/hermes-analysis/master_optimizer_reports/pg429_xmage_mana_source_hybrid_locket_draw_new_server_rollback.sql`
- postcheck: `docs/hermes-analysis/master_optimizer_reports/pg429_xmage_mana_source_hybrid_locket_draw_new_server_postcheck.sql`
- manifest: `docs/hermes-analysis/master_optimizer_reports/pg429_xmage_mana_source_hybrid_locket_draw_new_server_manifest.json`
- package: `docs/hermes-analysis/master_optimizer_reports/pg429_xmage_mana_source_hybrid_locket_draw_new_server_package.md`

Apply gate:

- Do not run apply SQL without explicit approval for the exact command.
- Required sequence after approval: precheck, apply, postcheck, PG -> SQLite sync, focused/family tests, affected deck coherence audit.
