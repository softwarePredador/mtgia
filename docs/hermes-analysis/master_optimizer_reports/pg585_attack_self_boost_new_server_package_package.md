# PG585 XMage Batch PostgreSQL Package

Status: `prepared_read_only_pending_apply_approval`.

This package was generated from XMage batch proposals. No SQL was executed by the builder.

- Generated at: `2026-07-07T01:49:26+00:00`
- Selected cards: `["Benalish Veteran", "Borderland Marauder", "Bramble Creeper", "Brazen Wolves", "Charging Bandits", "Charging Paladin", "Flowstone Charger", "Graceful Cat", "Hollow Dogs", "Jumbo Cactuar", "Kiln Walker", "Lurking Nightstalker", "Reckless Pangolin", "Steadfast Cathar", "Vicious Kavu", "Wei Ambush Force"]`
- Families: `{"xmage_creature_attack_self_boost_until_eot": 16}`

Files:

- precheck: `docs/hermes-analysis/master_optimizer_reports/pg585_attack_self_boost_new_server_package_precheck.sql`
- apply: `docs/hermes-analysis/master_optimizer_reports/pg585_attack_self_boost_new_server_package_apply.sql`
- rollback: `docs/hermes-analysis/master_optimizer_reports/pg585_attack_self_boost_new_server_package_rollback.sql`
- postcheck: `docs/hermes-analysis/master_optimizer_reports/pg585_attack_self_boost_new_server_package_postcheck.sql`
- manifest: `docs/hermes-analysis/master_optimizer_reports/pg585_attack_self_boost_new_server_package_manifest.json`
- package: `docs/hermes-analysis/master_optimizer_reports/pg585_attack_self_boost_new_server_package_package.md`

Apply gate:

- Do not run apply SQL without explicit approval for the exact command.
- Required sequence after approval: precheck, apply, postcheck, PG -> SQLite sync, focused/family tests, affected deck coherence audit.
