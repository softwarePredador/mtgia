# PG413 XMage Batch PostgreSQL Package

Status: `prepared_read_only_pending_apply_approval`.

This package was generated from XMage batch proposals. No SQL was executed by the builder.

- Generated at: `2026-07-04T16:01:42+00:00`
- Selected cards: `["Death Speakers", "Galina's Knight", "Goblin Outlander", "Guma", "Ihsan's Shade", "Karoo Meerkat", "Llanowar Knight", "Nacatl Outlander", "Oraxid", "Oversoul of Dusk", "Repentant Blacksmith", "Scalebane's Elite", "Shivan Zombie", "Valeron Outlander", "Vedalken Outlander", "Vodalian Zombie", "Vulshok Refugee", "Yavimaya Barbarian", "Zombie Outlander"]`
- Families: `{"xmage_static_self_protection_from_colors_creature": 19}`

Files:

- precheck: `docs/hermes-analysis/master_optimizer_reports/pg413_static_protection_colors_new_server_package_precheck.sql`
- apply: `docs/hermes-analysis/master_optimizer_reports/pg413_static_protection_colors_new_server_package_apply.sql`
- rollback: `docs/hermes-analysis/master_optimizer_reports/pg413_static_protection_colors_new_server_package_rollback.sql`
- postcheck: `docs/hermes-analysis/master_optimizer_reports/pg413_static_protection_colors_new_server_package_postcheck.sql`
- manifest: `docs/hermes-analysis/master_optimizer_reports/pg413_static_protection_colors_new_server_package_manifest.json`
- package: `docs/hermes-analysis/master_optimizer_reports/pg413_static_protection_colors_new_server_package_package.md`

Apply gate:

- Do not run apply SQL without explicit approval for the exact command.
- Required sequence after approval: precheck, apply, postcheck, PG -> SQLite sync, focused/family tests, affected deck coherence audit.
