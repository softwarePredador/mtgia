# pg552_activated_tap_target_creature_new_server XMage Batch PostgreSQL Package

Status: `prepared_read_only_pending_apply_approval`.

This package was generated from XMage batch proposals. No SQL was executed by the builder.

- Generated at: `2026-07-06T05:21:55+00:00`
- Selected cards: `["Akroan Jailer", "Akroan Mastiff", "Blinding Mage", "Checkpoint Officer", "Elite Arrester", "Fan Bearer", "Frostbridge Guard", "Gavony Trapper", "Goldmeadow Harrier", "Nebelgast Beguiler", "Rathi Trapper", "Trip Noose", "Tyrant's Machine"]`
- Families: `{"xmage_permanent_simple_activated_tap_target": 13}`

Files:

- precheck: `docs/hermes-analysis/master_optimizer_reports/pg552_activated_tap_target_creature_new_server_package_precheck.sql`
- apply: `docs/hermes-analysis/master_optimizer_reports/pg552_activated_tap_target_creature_new_server_package_apply.sql`
- rollback: `docs/hermes-analysis/master_optimizer_reports/pg552_activated_tap_target_creature_new_server_package_rollback.sql`
- postcheck: `docs/hermes-analysis/master_optimizer_reports/pg552_activated_tap_target_creature_new_server_package_postcheck.sql`
- manifest: `docs/hermes-analysis/master_optimizer_reports/pg552_activated_tap_target_creature_new_server_package_manifest.json`
- package: `docs/hermes-analysis/master_optimizer_reports/pg552_activated_tap_target_creature_new_server_package_package.md`

Apply gate:

- Do not run apply SQL without explicit approval for the exact command.
- Required sequence after approval: precheck, apply, postcheck, PG -> SQLite sync, focused/family tests, affected deck coherence audit.
