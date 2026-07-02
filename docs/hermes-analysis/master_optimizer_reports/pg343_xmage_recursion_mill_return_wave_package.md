# PG343 XMage Batch PostgreSQL Package

Status: `prepared_read_only_pending_apply_approval`.

This package was generated from XMage batch proposals. No SQL was executed by the builder.

- Generated at: `2026-07-02T01:26:03+00:00`
- Selected cards: `["Acolyte of Affliction", "Corpse Churn", "Eccentric Farmer", "Grapple with the Past", "Pothole Mole"]`
- Families: `{"xmage_creature_etb_mill_then_return_graveyard_to_hand": 3, "xmage_mill_then_return_graveyard_to_hand_spell": 2}`

Files:

- precheck: `docs/hermes-analysis/master_optimizer_reports/pg343_xmage_recursion_mill_return_wave_precheck.sql`
- apply: `docs/hermes-analysis/master_optimizer_reports/pg343_xmage_recursion_mill_return_wave_apply.sql`
- rollback: `docs/hermes-analysis/master_optimizer_reports/pg343_xmage_recursion_mill_return_wave_rollback.sql`
- postcheck: `docs/hermes-analysis/master_optimizer_reports/pg343_xmage_recursion_mill_return_wave_postcheck.sql`
- manifest: `docs/hermes-analysis/master_optimizer_reports/pg343_xmage_recursion_mill_return_wave_manifest.json`
- package: `docs/hermes-analysis/master_optimizer_reports/pg343_xmage_recursion_mill_return_wave_package.md`

Apply gate:

- Do not run apply SQL without explicit approval for the exact command.
- Required sequence after approval: precheck, apply, postcheck, PG -> SQLite sync, focused/family tests, affected deck coherence audit.
