# PG481 XMage Batch PostgreSQL Package

Status: `prepared_read_only_pending_apply_approval`.

This package was generated from XMage batch proposals. No SQL was executed by the builder.

- Generated at: `2026-07-05T04:26:34+00:00`
- Selected cards: `["Armorcraft Judge", "Discerning Peddler", "Earthshaker Dreadmaw", "Fissure Wizard", "Immersturm Raider", "Keldon Raider", "Plundering Predator", "Prophet of the Scarab", "Regal Force", "Shinestriker", "Viashino Racketeer", "Yuyan Archers"]`
- Families: `{"xmage_creature_etb_dynamic_draw_cards": 5, "xmage_creature_etb_optional_discard_draw_cards": 7}`

Files:

- precheck: `docs/hermes-analysis/master_optimizer_reports/xmage_pg481_etb_draw_patterns_new_server_precheck.sql`
- apply: `docs/hermes-analysis/master_optimizer_reports/xmage_pg481_etb_draw_patterns_new_server_apply.sql`
- rollback: `docs/hermes-analysis/master_optimizer_reports/xmage_pg481_etb_draw_patterns_new_server_rollback.sql`
- postcheck: `docs/hermes-analysis/master_optimizer_reports/xmage_pg481_etb_draw_patterns_new_server_postcheck.sql`
- manifest: `docs/hermes-analysis/master_optimizer_reports/xmage_pg481_etb_draw_patterns_new_server_manifest.json`
- package: `docs/hermes-analysis/master_optimizer_reports/xmage_pg481_etb_draw_patterns_new_server_package.md`

Apply gate:

- Do not run apply SQL without explicit approval for the exact command.
- Required sequence after approval: precheck, apply, postcheck, PG -> SQLite sync, focused/family tests, affected deck coherence audit.
