# PG355 XMage Batch PostgreSQL Package

Status: `prepared_read_only_pending_apply_approval`.

This package was generated from XMage batch proposals. No SQL was executed by the builder.

- Generated at: `2026-07-02T05:41:38+00:00`
- Selected cards: `["Bramblecrush", "Crush", "Dark Banishing", "Dark Betrayal", "Deathmark", "Exorcist", "Go for the Throat", "Hero's Demise", "Joven", "Saltblast", "Terror // Terror", "Ultimate Price"]`
- Families: `{"xmage_destroy_target_spell": 10, "xmage_permanent_simple_activated_destroy_target": 2}`

Files:

- precheck: `docs/hermes-analysis/master_optimizer_reports/pg355_xmage_destroy_restricted_target_wave_precheck.sql`
- apply: `docs/hermes-analysis/master_optimizer_reports/pg355_xmage_destroy_restricted_target_wave_apply.sql`
- rollback: `docs/hermes-analysis/master_optimizer_reports/pg355_xmage_destroy_restricted_target_wave_rollback.sql`
- postcheck: `docs/hermes-analysis/master_optimizer_reports/pg355_xmage_destroy_restricted_target_wave_postcheck.sql`
- manifest: `docs/hermes-analysis/master_optimizer_reports/pg355_xmage_destroy_restricted_target_wave_manifest.json`
- package: `docs/hermes-analysis/master_optimizer_reports/pg355_xmage_destroy_restricted_target_wave_package.md`

Apply gate:

- Do not run apply SQL without explicit approval for the exact command.
- Required sequence after approval: precheck, apply, postcheck, PG -> SQLite sync, focused/family tests, affected deck coherence audit.
