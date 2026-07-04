# pg447 XMage Batch PostgreSQL Package

Status: `prepared_read_only_pending_apply_approval`.

This package was generated from XMage batch proposals. No SQL was executed by the builder.

- Generated at: `2026-07-04T23:06:57+00:00`
- Selected cards: `["Basal Thrull", "Blood Pet", "Blood Vassal", "Catalyst Elemental", "Coal Golem", "Composite Golem", "Crosis's Attendant", "Darigaaz's Attendant", "Dromar's Attendant", "Morgue Toad", "Rith's Attendant", "Satyr Hedonist", "Treva's Attendant"]`
- Families: `{"xmage_self_sacrifice_mana_source_permanent": 13}`

Files:

- precheck: `../../master_optimizer_reports/pg447_xmage_self_sacrifice_mana_source_new_server_precheck.sql`
- apply: `../../master_optimizer_reports/pg447_xmage_self_sacrifice_mana_source_new_server_apply.sql`
- rollback: `../../master_optimizer_reports/pg447_xmage_self_sacrifice_mana_source_new_server_rollback.sql`
- postcheck: `../../master_optimizer_reports/pg447_xmage_self_sacrifice_mana_source_new_server_postcheck.sql`
- manifest: `../../master_optimizer_reports/pg447_xmage_self_sacrifice_mana_source_new_server_manifest.json`
- package: `../../master_optimizer_reports/pg447_xmage_self_sacrifice_mana_source_new_server_package.md`

Apply gate:

- Do not run apply SQL without explicit approval for the exact command.
- Required sequence after approval: precheck, apply, postcheck, PG -> SQLite sync, focused/family tests, affected deck coherence audit.
