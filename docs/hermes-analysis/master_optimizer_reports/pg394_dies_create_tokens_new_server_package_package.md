# PG394 XMage Batch PostgreSQL Package

Status: `prepared_read_only_pending_apply_approval`.

This package was generated from XMage batch proposals. No SQL was executed by the builder.

- Generated at: `2026-07-04T08:36:51+00:00`
- Selected cards: `["Beskir Shieldmate", "Brindle Shoat", "Brood Weaver", "Conscripted Infantry", "Deathbloom Thallid", "Discordant Piper", "Doomed Dissenter", "Doomed Traveler", "Dwarven Castle Guard", "Elgaud Inquisitor", "Filigree Crawler", "Garrison Cat", "Hunted Witness", "Infestation Sage", "Maalfeld Twins", "Martyr of Dusk", "Myr Sire", "Penumbra Bobcat", "Penumbra Kavu", "Penumbra Spider", "Penumbra Wurm", "Pretending Poxbearers", "Tukatongue Thallid", "Wriggling Grub"]`
- Families: `{"xmage_creature_dies_create_tokens": 24}`

Files:

- precheck: `docs/hermes-analysis/master_optimizer_reports/pg394_dies_create_tokens_new_server_package_precheck.sql`
- apply: `docs/hermes-analysis/master_optimizer_reports/pg394_dies_create_tokens_new_server_package_apply.sql`
- rollback: `docs/hermes-analysis/master_optimizer_reports/pg394_dies_create_tokens_new_server_package_rollback.sql`
- postcheck: `docs/hermes-analysis/master_optimizer_reports/pg394_dies_create_tokens_new_server_package_postcheck.sql`
- manifest: `docs/hermes-analysis/master_optimizer_reports/pg394_dies_create_tokens_new_server_package_manifest.json`
- package: `docs/hermes-analysis/master_optimizer_reports/pg394_dies_create_tokens_new_server_package_package.md`

Apply gate:

- Do not run apply SQL without explicit approval for the exact command.
- Required sequence after approval: precheck, apply, postcheck, PG -> SQLite sync, focused/family tests, affected deck coherence audit.
