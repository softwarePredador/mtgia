# xmage_pg497_etb_counter_target_constraints_new_server XMage Batch PostgreSQL Package

Status: `prepared_read_only_pending_apply_approval`.

This package was generated from XMage batch proposals. No SQL was executed by the builder.

- Generated at: `2026-07-05T09:26:18+00:00`
- Selected cards: `["Aeronaut Cavalry", "Basri's Acolyte", "Earth Kingdom Soldier", "Felidar Savior", "Gavony Silversmith", "Jade Bearer", "Keen-Eyed Raven", "Pileated Provisioner", "Sanguine Glorifier", "Skinrender", "Sterling Supplier", "Stromkirk Mentor", "Timberland Guide", "Vineshaper Mystic"]`
- Families: `{"xmage_creature_etb_add_counters_target_creature": 14}`

Files:

- precheck: `docs/hermes-analysis/master_optimizer_reports/xmage_pg497_etb_counter_target_constraints_new_server_precheck.sql`
- apply: `docs/hermes-analysis/master_optimizer_reports/xmage_pg497_etb_counter_target_constraints_new_server_apply.sql`
- rollback: `docs/hermes-analysis/master_optimizer_reports/xmage_pg497_etb_counter_target_constraints_new_server_rollback.sql`
- postcheck: `docs/hermes-analysis/master_optimizer_reports/xmage_pg497_etb_counter_target_constraints_new_server_postcheck.sql`
- manifest: `docs/hermes-analysis/master_optimizer_reports/xmage_pg497_etb_counter_target_constraints_new_server_manifest.json`
- package: `docs/hermes-analysis/master_optimizer_reports/xmage_pg497_etb_counter_target_constraints_new_server_package.md`

Apply gate:

- Do not run apply SQL without explicit approval for the exact command.
- Required sequence after approval: precheck, apply, postcheck, PG -> SQLite sync, focused/family tests, affected deck coherence audit.
