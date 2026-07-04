# pg408_mana_etb_draw_new_server XMage Batch PostgreSQL Package

Status: `prepared_read_only_pending_apply_approval`.

This package was generated from XMage batch proposals. No SQL was executed by the builder.

- Generated at: `2026-07-04T13:54:27+00:00`
- Selected cards: `["Agent of Stromgald", "Arcum's Astrolabe", "Bog Initiate", "Energy Refractor", "Helionaut", "Llanowar Envoy", "Llanowar Visionary", "Nomadic Elf", "Orochi Leafcaller", "Prismite", "Prophetic Prism", "Signpost Scarecrow", "Viridian Acolyte"]`
- Families: `{"xmage_simple_mana_source_permanent": 9, "xmage_simple_mana_source_with_etb_draw": 4}`

Files:

- precheck: `docs/hermes-analysis/master_optimizer_reports/pg408_mana_etb_draw_new_server_package_precheck.sql`
- apply: `docs/hermes-analysis/master_optimizer_reports/pg408_mana_etb_draw_new_server_package_apply.sql`
- rollback: `docs/hermes-analysis/master_optimizer_reports/pg408_mana_etb_draw_new_server_package_rollback.sql`
- postcheck: `docs/hermes-analysis/master_optimizer_reports/pg408_mana_etb_draw_new_server_package_postcheck.sql`
- manifest: `docs/hermes-analysis/master_optimizer_reports/pg408_mana_etb_draw_new_server_package_manifest.json`
- package: `docs/hermes-analysis/master_optimizer_reports/pg408_mana_etb_draw_new_server_package_package.md`

Apply gate:

- Do not run apply SQL without explicit approval for the exact command.
- Required sequence after approval: precheck, apply, postcheck, PG -> SQLite sync, focused/family tests, affected deck coherence audit.
