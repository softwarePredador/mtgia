# pg411_triggered_recursion_to_hand_new_server XMage Batch PostgreSQL Package

Status: `prepared_read_only_pending_apply_approval`.

This package was generated from XMage batch proposals. No SQL was executed by the builder.

- Generated at: `2026-07-04T15:20:10+00:00`
- Selected cards: `["Eternal Taskmaster", "Pillardrop Warden", "The Unspeakable"]`
- Families: `{"xmage_creature_combat_damage_graveyard_to_hand": 1, "xmage_permanent_attack_graveyard_to_hand": 1, "xmage_permanent_simple_activated_graveyard_to_hand": 1}`

Files:

- precheck: `docs/hermes-analysis/master_optimizer_reports/pg411_triggered_recursion_to_hand_new_server_package_precheck.sql`
- apply: `docs/hermes-analysis/master_optimizer_reports/pg411_triggered_recursion_to_hand_new_server_package_apply.sql`
- rollback: `docs/hermes-analysis/master_optimizer_reports/pg411_triggered_recursion_to_hand_new_server_package_rollback.sql`
- postcheck: `docs/hermes-analysis/master_optimizer_reports/pg411_triggered_recursion_to_hand_new_server_package_postcheck.sql`
- manifest: `docs/hermes-analysis/master_optimizer_reports/pg411_triggered_recursion_to_hand_new_server_package_manifest.json`
- package: `docs/hermes-analysis/master_optimizer_reports/pg411_triggered_recursion_to_hand_new_server_package_package.md`

Apply gate:

- Do not run apply SQL without explicit approval for the exact command.
- Required sequence after approval: precheck, apply, postcheck, PG -> SQLite sync, focused/family tests, affected deck coherence audit.
