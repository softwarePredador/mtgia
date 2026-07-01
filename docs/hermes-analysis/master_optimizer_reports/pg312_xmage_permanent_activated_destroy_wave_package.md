# PG312 XMage Batch PostgreSQL Package

Status: `prepared_read_only_pending_apply_approval`.

This package was generated from XMage batch proposals. No SQL was executed by the builder.

- Generated at: `2026-07-01T15:05:22+00:00`
- Selected cards: `["Ark of Blight", "Barbarian Riftcutter", "Druid Lyrist", "Elf Replica", "Elvish Lyrist", "Elvish Scrapper", "Executioner's Capsule", "Felidar Cub", "Kami of Ancient Law", "Keening Apparition", "Mine Bearer", "Priest of Iroas", "Reckless Reveler", "Ronom Unicorn", "Royal Assassin", "Ruinous Gremlin", "Scavenger Folk", "Torch Fiend", "Universal Solvent"]`
- Families: `{"xmage_permanent_simple_activated_destroy_target": 19}`

Files:

- precheck: `docs/hermes-analysis/master_optimizer_reports/pg312_xmage_permanent_activated_destroy_wave_precheck.sql`
- apply: `docs/hermes-analysis/master_optimizer_reports/pg312_xmage_permanent_activated_destroy_wave_apply.sql`
- rollback: `docs/hermes-analysis/master_optimizer_reports/pg312_xmage_permanent_activated_destroy_wave_rollback.sql`
- postcheck: `docs/hermes-analysis/master_optimizer_reports/pg312_xmage_permanent_activated_destroy_wave_postcheck.sql`
- manifest: `docs/hermes-analysis/master_optimizer_reports/pg312_xmage_permanent_activated_destroy_wave_manifest.json`
- package: `docs/hermes-analysis/master_optimizer_reports/pg312_xmage_permanent_activated_destroy_wave_package.md`

Apply gate:

- Do not run apply SQL without explicit approval for the exact command.
- Required sequence after approval: precheck, apply, postcheck, PG -> SQLite sync, focused/family tests, affected deck coherence audit.
