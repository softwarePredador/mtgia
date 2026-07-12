# PG824 XMage Batch PostgreSQL Package

Status: `prepared_read_only_pending_apply_approval`.

This package was generated from XMage batch proposals. No SQL was executed by the builder.

- Generated at: `2026-07-12T09:56:50+00:00`
- Selected cards: `["Bloodfire Expert", "Dragon Bell Monk", "Dragon-Style Twins", "Elementalist Adept", "Iguana Parrot", "Jeskai Brushmaster", "Jeskai Student", "Jeskai Windscout", "Lightning Visionary", "Lotus Path Djinn", "Mistral Singer", "Monastery Swiftspear", "Niblis of Dusk", "Nimble-Blade Khenra", "Ringwarden Owl", "Riverwheel Aerialists", "Sanguinary Mage", "Stormchaser Mage", "Thor Odinson", "Umara Entangler", "Vedalken Blademaster", "Whirlwind Adept", "Wing Commando"]`
- Families: `{"xmage_static_self_prowess_creature": 23}`

Files:

- precheck: `docs/hermes-analysis/master_optimizer_reports/pg824_static_self_prowess_creature_new_server_package_precheck.sql`
- apply: `docs/hermes-analysis/master_optimizer_reports/pg824_static_self_prowess_creature_new_server_package_apply.sql`
- rollback: `docs/hermes-analysis/master_optimizer_reports/pg824_static_self_prowess_creature_new_server_package_rollback.sql`
- postcheck: `docs/hermes-analysis/master_optimizer_reports/pg824_static_self_prowess_creature_new_server_package_postcheck.sql`
- manifest: `docs/hermes-analysis/master_optimizer_reports/pg824_static_self_prowess_creature_new_server_package_manifest.json`
- package: `docs/hermes-analysis/master_optimizer_reports/pg824_static_self_prowess_creature_new_server_package_package.md`

Apply gate:

- Do not run apply SQL without explicit approval for the exact command.
- Required sequence after approval: precheck, apply, postcheck, PG -> SQLite sync, focused/family tests, affected deck coherence audit.
