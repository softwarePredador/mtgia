# PG658 XMage Batch PostgreSQL Package

Status: `prepared_read_only_pending_apply_approval`.

This package was generated from XMage batch proposals. No SQL was executed by the builder.

- Generated at: `2026-07-08T13:51:46+00:00`
- Selected cards: `["Accursed Spirit", "Bladetusk Boar", "Crowd of Cinders", "Dross Prowler", "Gluttonous Zombie", "Highborn Ghoul", "Krenko's Enforcer", "Prickly Boggart", "Razortooth Rats", "Severed Legion", "Shadowmage Infiltrator", "Spectral Rider", "Squirming Mass", "Undercity Shade", "Woebearer"]`
- Families: `{"xmage_creature_combat_damage_draw_cards": 1, "xmage_creature_combat_damage_graveyard_to_hand": 1, "xmage_permanent_simple_activated_self_boost_until_eot": 1, "xmage_static_self_combat_keyword_creature": 11, "xmage_static_source_power_toughness_equal_count": 1}`

Files:

- precheck: `docs/hermes-analysis/master_optimizer_reports/pg658_static_fear_intimidate_new_server_package_precheck.sql`
- apply: `docs/hermes-analysis/master_optimizer_reports/pg658_static_fear_intimidate_new_server_package_apply.sql`
- rollback: `docs/hermes-analysis/master_optimizer_reports/pg658_static_fear_intimidate_new_server_package_rollback.sql`
- postcheck: `docs/hermes-analysis/master_optimizer_reports/pg658_static_fear_intimidate_new_server_package_postcheck.sql`
- manifest: `docs/hermes-analysis/master_optimizer_reports/pg658_static_fear_intimidate_new_server_package_manifest.json`
- package: `docs/hermes-analysis/master_optimizer_reports/pg658_static_fear_intimidate_new_server_package_package.md`

Apply gate:

- Do not run apply SQL without explicit approval for the exact command.
- Required sequence after approval: precheck, apply, postcheck, PG -> SQLite sync, focused/family tests, affected deck coherence audit.
