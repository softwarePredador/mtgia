# PG245 XMage Batch PostgreSQL Package

Status: `prepared_read_only_pending_apply_approval`.

This package was generated from XMage batch proposals. No SQL was executed by the builder.

- Generated at: `2026-06-28T01:53:59+00:00`
- Selected cards: `["Twinflame Tyrant", "Verge Rangers"]`
- Families: `{"static_damage_modifier": 1, "topdeck_play": 1}`

Files:

- precheck: `docs/hermes-analysis/master_optimizer_reports/pg245_lorehold_topdeck_damage_runtime_20260628_precheck.sql`
- apply: `docs/hermes-analysis/master_optimizer_reports/pg245_lorehold_topdeck_damage_runtime_20260628_apply.sql`
- rollback: `docs/hermes-analysis/master_optimizer_reports/pg245_lorehold_topdeck_damage_runtime_20260628_rollback.sql`
- postcheck: `docs/hermes-analysis/master_optimizer_reports/pg245_lorehold_topdeck_damage_runtime_20260628_postcheck.sql`
- manifest: `docs/hermes-analysis/master_optimizer_reports/pg245_lorehold_topdeck_damage_runtime_20260628_manifest.json`
- package: `docs/hermes-analysis/master_optimizer_reports/pg245_lorehold_topdeck_damage_runtime_20260628_package.md`

Apply gate:

- Do not run apply SQL without explicit approval for the exact command.
- Required sequence after approval: precheck, apply, postcheck, PG -> SQLite sync, focused/family tests, affected deck coherence audit.
