# PG480 XMage Batch PostgreSQL Package

Status: `prepared_read_only_pending_apply_approval`.

This package was generated from XMage batch proposals. No SQL was executed by the builder.

- Generated at: `2026-07-05T04:04:40+00:00`
- Selected cards: `["Neurok Commando", "Nine-Tail White Fox", "Scroll Thief", "Soulknife Spy", "Stealer of Secrets"]`
- Families: `{"xmage_creature_combat_damage_draw_cards": 5}`

Files:

- precheck: `docs/hermes-analysis/master_optimizer_reports/xmage_pg480_combat_damage_draw_precheck.sql`
- apply: `docs/hermes-analysis/master_optimizer_reports/xmage_pg480_combat_damage_draw_apply.sql`
- rollback: `docs/hermes-analysis/master_optimizer_reports/xmage_pg480_combat_damage_draw_rollback.sql`
- postcheck: `docs/hermes-analysis/master_optimizer_reports/xmage_pg480_combat_damage_draw_postcheck.sql`
- manifest: `docs/hermes-analysis/master_optimizer_reports/xmage_pg480_combat_damage_draw_manifest.json`
- package: `docs/hermes-analysis/master_optimizer_reports/xmage_pg480_combat_damage_draw_package.md`

Apply gate:

- Do not run apply SQL without explicit approval for the exact command.
- Required sequence after approval: precheck, apply, postcheck, PG -> SQLite sync, focused/family tests, affected deck coherence audit.
