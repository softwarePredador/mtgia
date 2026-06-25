# pg206 XMage Batch PostgreSQL Package

Status: `prepared_read_only_pending_apply_approval`.

This package was generated from XMage batch proposals. No SQL was executed by the builder.

- Generated at: `2026-06-25T06:32:22+00:00`
- Selected cards: `["Boltwave"]`
- Families: `{"opponent_damage_spell": 1}`

Files:

- precheck: `docs/hermes-analysis/master_optimizer_reports/pg206_damage_each_opponent_precheck.sql`
- apply: `docs/hermes-analysis/master_optimizer_reports/pg206_damage_each_opponent_apply.sql`
- rollback: `docs/hermes-analysis/master_optimizer_reports/pg206_damage_each_opponent_rollback.sql`
- postcheck: `docs/hermes-analysis/master_optimizer_reports/pg206_damage_each_opponent_postcheck.sql`
- manifest: `docs/hermes-analysis/master_optimizer_reports/pg206_damage_each_opponent_manifest.json`
- package: `docs/hermes-analysis/master_optimizer_reports/pg206_damage_each_opponent_package.md`

Apply gate:

- Do not run apply SQL without explicit approval for the exact command.
- Required sequence after approval: precheck, apply, postcheck, PG -> SQLite sync, focused/family tests, affected deck coherence audit.
