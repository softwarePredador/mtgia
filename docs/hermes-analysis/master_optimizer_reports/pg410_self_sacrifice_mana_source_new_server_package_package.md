# pg410_self_sacrifice_mana_source_new_server XMage Batch PostgreSQL Package

Status: `prepared_read_only_pending_apply_approval`.

This package was generated from XMage batch proposals. No SQL was executed by the builder.

- Generated at: `2026-07-04T14:51:17+00:00`
- Selected cards: `["Basal Thrull", "Blood Pet", "Blood Vassal", "Catalyst Elemental", "Coal Golem", "Composite Golem", "Crosis's Attendant", "Darigaaz's Attendant", "Dromar's Attendant", "Morgue Toad", "Rith's Attendant", "Satyr Hedonist", "Treva's Attendant"]`
- Families: `{"xmage_self_sacrifice_mana_source_permanent": 13}`

Files:

- precheck: `docs/hermes-analysis/master_optimizer_reports/pg410_self_sacrifice_mana_source_new_server_package_precheck.sql`
- apply: `docs/hermes-analysis/master_optimizer_reports/pg410_self_sacrifice_mana_source_new_server_package_apply.sql`
- rollback: `docs/hermes-analysis/master_optimizer_reports/pg410_self_sacrifice_mana_source_new_server_package_rollback.sql`
- postcheck: `docs/hermes-analysis/master_optimizer_reports/pg410_self_sacrifice_mana_source_new_server_package_postcheck.sql`
- manifest: `docs/hermes-analysis/master_optimizer_reports/pg410_self_sacrifice_mana_source_new_server_package_manifest.json`
- package: `docs/hermes-analysis/master_optimizer_reports/pg410_self_sacrifice_mana_source_new_server_package_package.md`

Apply gate:

- Do not run apply SQL without explicit approval for the exact command.
- Required sequence after approval: precheck, apply, postcheck, PG -> SQLite sync, focused/family tests, affected deck coherence audit.
