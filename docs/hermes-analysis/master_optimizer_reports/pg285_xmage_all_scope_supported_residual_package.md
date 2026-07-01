# PG285 XMage Batch PostgreSQL Package

Status: `prepared_read_only_pending_apply_approval`.

This package was generated from XMage batch proposals. No SQL was executed by the builder.

- Generated at: `2026-07-01T08:02:40+00:00`
- Selected cards: `["Cruel Cut", "Lava, Axe", "Mox Emerald", "Mox Jet", "Mox Pearl", "Mox Ruby", "Mox Sapphire", "Smelt // Herd // Saw"]`
- Families: `{"xmage_destroy_target_spell": 2, "xmage_fixed_damage_spell": 1, "xmage_simple_mana_source_permanent": 5}`

Files:

- precheck: `../../master_optimizer_reports/pg285_xmage_all_scope_supported_residual_precheck.sql`
- apply: `../../master_optimizer_reports/pg285_xmage_all_scope_supported_residual_apply.sql`
- rollback: `../../master_optimizer_reports/pg285_xmage_all_scope_supported_residual_rollback.sql`
- postcheck: `../../master_optimizer_reports/pg285_xmage_all_scope_supported_residual_postcheck.sql`
- manifest: `../../master_optimizer_reports/pg285_xmage_all_scope_supported_residual_manifest.json`
- package: `../../master_optimizer_reports/pg285_xmage_all_scope_supported_residual_package.md`

Apply gate:

- Do not run apply SQL without explicit approval for the exact command.
- Required sequence after approval: precheck, apply, postcheck, PG -> SQLite sync, focused/family tests, affected deck coherence audit.
