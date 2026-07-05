# PG484 XMage Batch PostgreSQL Package

Status: `prepared_read_only_pending_apply_approval`.

This package was generated from XMage batch proposals. No SQL was executed by the builder.

- Generated at: `2026-07-05T05:31:36+00:00`
- Selected cards: `["Acid Rain", "Anarchy", "Boil", "Boiling Seas", "Citywide Bust", "Flashfires", "Gale Force", "Guan Yu's 1,000-Li March", "Marrow Shards", "Mass Calcify", "Nature's Ruin", "Perish", "Plague Wind", "Planar Cleansing", "Rain of Blades", "Retribution of the Meek", "Ritual of Soot", "Ruination", "Sandstorm", "Shatterstorm", "Soulscour", "Squall", "Their Name Is Death", "Tsunami", "Virtue's Ruin", "Whipflare"]`
- Families: `{"xmage_damage_all_spell": 6, "xmage_destroy_all_spell": 20}`

Files:

- precheck: `docs/hermes-analysis/master_optimizer_reports/xmage_pg484_board_wipe_extended_new_server_precheck.sql`
- apply: `docs/hermes-analysis/master_optimizer_reports/xmage_pg484_board_wipe_extended_new_server_apply.sql`
- rollback: `docs/hermes-analysis/master_optimizer_reports/xmage_pg484_board_wipe_extended_new_server_rollback.sql`
- postcheck: `docs/hermes-analysis/master_optimizer_reports/xmage_pg484_board_wipe_extended_new_server_postcheck.sql`
- manifest: `docs/hermes-analysis/master_optimizer_reports/xmage_pg484_board_wipe_extended_new_server_manifest.json`
- package: `docs/hermes-analysis/master_optimizer_reports/xmage_pg484_board_wipe_extended_new_server_package.md`

Apply gate:

- Do not run apply SQL without explicit approval for the exact command.
- Required sequence after approval: precheck, apply, postcheck, PG -> SQLite sync, focused/family tests, affected deck coherence audit.
