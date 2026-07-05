# pg478 XMage Batch PostgreSQL Package

Status: `prepared_read_only_pending_apply_approval`.

This package was generated from XMage batch proposals. No SQL was executed by the builder.

- Generated at: `2026-07-05T03:15:47+00:00`
- Selected cards: `["Badlands Revival", "Bonecaller Cleric", "Crucible of Worlds", "Elvish Hexhunter", "Eternal Taskmaster", "Festive Funeral", "Ghoul's Feast", "Hana Kami", "Pillardrop Warden", "Pull Through the Weft", "Ramunap Excavator", "Select for Inspection", "The Unspeakable", "Valgavoth's Faithful", "Voyage's End"]`
- Families: `{"xmage_bounce_scry_spell": 2, "xmage_creature_combat_damage_graveyard_to_hand": 1, "xmage_dynamic_graveyard_count_boost_target_creature_until_eot_spell": 2, "xmage_graveyard_multi_zone_recursion_spell": 2, "xmage_permanent_attack_graveyard_to_hand": 1, "xmage_permanent_simple_activated_destroy_target": 1, "xmage_permanent_simple_activated_graveyard_to_battlefield": 2, "xmage_permanent_simple_activated_graveyard_to_hand": 2, "xmage_static_play_lands_from_graveyard": 2}`

Files:

- precheck: `../../master_optimizer_reports/pg478_xmage_residual_exact_safe_sweep_new_server_precheck.sql`
- apply: `../../master_optimizer_reports/pg478_xmage_residual_exact_safe_sweep_new_server_apply.sql`
- rollback: `../../master_optimizer_reports/pg478_xmage_residual_exact_safe_sweep_new_server_rollback.sql`
- postcheck: `../../master_optimizer_reports/pg478_xmage_residual_exact_safe_sweep_new_server_postcheck.sql`
- manifest: `../../master_optimizer_reports/pg478_xmage_residual_exact_safe_sweep_new_server_manifest.json`
- package: `../../master_optimizer_reports/pg478_xmage_residual_exact_safe_sweep_new_server_package.md`

Apply gate:

- Do not run apply SQL without explicit approval for the exact command.
- Required sequence after approval: precheck, apply, postcheck, PG -> SQLite sync, focused/family tests, affected deck coherence audit.
