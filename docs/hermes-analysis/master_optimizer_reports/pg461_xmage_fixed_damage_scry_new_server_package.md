# pg461 XMage Batch PostgreSQL Package

Status: `prepared_read_only_pending_apply_approval`.

This package was generated from XMage batch proposals. No SQL was executed by the builder.

- Generated at: `2026-07-05T00:55:58+00:00`
- Selected cards: `["Bolt of Keranos", "Fateful End", "Jaya's Firenado", "Jaya's Greeting", "Lightning Javelin", "Magma Jet", "Piercing Light", "Spark Jolt"]`
- Families: `{"xmage_fixed_damage_scry_spell": 8}`

Files:

- precheck: `../../master_optimizer_reports/pg461_xmage_fixed_damage_scry_new_server_precheck.sql`
- apply: `../../master_optimizer_reports/pg461_xmage_fixed_damage_scry_new_server_apply.sql`
- rollback: `../../master_optimizer_reports/pg461_xmage_fixed_damage_scry_new_server_rollback.sql`
- postcheck: `../../master_optimizer_reports/pg461_xmage_fixed_damage_scry_new_server_postcheck.sql`
- manifest: `../../master_optimizer_reports/pg461_xmage_fixed_damage_scry_new_server_manifest.json`
- package: `../../master_optimizer_reports/pg461_xmage_fixed_damage_scry_new_server_package.md`

Apply gate:

- Do not run apply SQL without explicit approval for the exact command.
- Required sequence after approval: precheck, apply, postcheck, PG -> SQLite sync, focused/family tests, affected deck coherence audit.
