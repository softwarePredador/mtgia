# PG311 XMage Batch PostgreSQL Package

Status: `prepared_read_only_pending_apply_approval`.

This package was generated from XMage batch proposals. No SQL was executed by the builder.

- Generated at: `2026-07-01T14:42:48+00:00`
- Selected cards: `["Adun Oakenshield", "Argivian Archaeologist", "Corpse Hauler", "Dowsing Shaman", "Font of Return", "Groundskeeper", "Hanna, Ship's Navigator", "Rootwater Diver", "Salvage Scout", "Skull of Orm", "Spellkeeper Weird"]`
- Families: `{"xmage_permanent_simple_activated_graveyard_to_hand": 11}`

Files:

- precheck: `docs/hermes-analysis/master_optimizer_reports/pg311_xmage_permanent_activated_recursion_to_hand_wave_precheck.sql`
- apply: `docs/hermes-analysis/master_optimizer_reports/pg311_xmage_permanent_activated_recursion_to_hand_wave_apply.sql`
- rollback: `docs/hermes-analysis/master_optimizer_reports/pg311_xmage_permanent_activated_recursion_to_hand_wave_rollback.sql`
- postcheck: `docs/hermes-analysis/master_optimizer_reports/pg311_xmage_permanent_activated_recursion_to_hand_wave_postcheck.sql`
- manifest: `docs/hermes-analysis/master_optimizer_reports/pg311_xmage_permanent_activated_recursion_to_hand_wave_manifest.json`
- package: `docs/hermes-analysis/master_optimizer_reports/pg311_xmage_permanent_activated_recursion_to_hand_wave_package.md`

Apply gate:

- Do not run apply SQL without explicit approval for the exact command.
- Required sequence after approval: precheck, apply, postcheck, PG -> SQLite sync, focused/family tests, affected deck coherence audit.
