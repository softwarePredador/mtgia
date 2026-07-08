# PG669 XMage Batch PostgreSQL Package

Status: `prepared_read_only_pending_apply_approval`.

This package was generated from XMage batch proposals. No SQL was executed by the builder.

- Generated at: `2026-07-08T19:19:07+00:00`
- Selected cards: `["Dual Shot", "Furious Reprisal", "Jagged Lightning", "Pinnacle of Rage", "Storm of Steel", "Swelter"]`
- Families: `{"xmage_fixed_damage_each_target_spell": 6}`

Files:

- precheck: `docs/hermes-analysis/master_optimizer_reports/pg669_damage_each_target_package_precheck.sql`
- apply: `docs/hermes-analysis/master_optimizer_reports/pg669_damage_each_target_package_apply.sql`
- rollback: `docs/hermes-analysis/master_optimizer_reports/pg669_damage_each_target_package_rollback.sql`
- postcheck: `docs/hermes-analysis/master_optimizer_reports/pg669_damage_each_target_package_postcheck.sql`
- manifest: `docs/hermes-analysis/master_optimizer_reports/pg669_damage_each_target_package_manifest.json`
- package: `docs/hermes-analysis/master_optimizer_reports/pg669_damage_each_target_package_package.md`

Apply gate:

- Do not run apply SQL without explicit approval for the exact command.
- Required sequence after approval: precheck, apply, postcheck, PG -> SQLite sync, focused/family tests, affected deck coherence audit.
