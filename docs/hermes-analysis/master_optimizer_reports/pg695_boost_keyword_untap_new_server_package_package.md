# PG695 XMage Batch PostgreSQL Package

Status: `prepared_read_only_pending_apply_approval`.

This package was generated from XMage batch proposals. No SQL was executed by the builder.

- Generated at: `2026-07-09T06:27:16+00:00`
- Selected cards: `["Acrobatic Leap", "Aim High", "Arachnoid Adaptation", "Bull's Strength", "Escape from Orthanc", "High Stride", "Leaping Ambush", "Magic Damper", "Octopus Form", "Pillar Launch", "Riverguard's Reflexes", "Spidery Grasp", "Steady Aim", "Vines of the Recluse", "Wings of the Cosmos", "Witch's Web"]`
- Families: `{"xmage_boost_keyword_untap_target_creature_until_eot_spell": 16}`

Files:

- precheck: `docs/hermes-analysis/master_optimizer_reports/pg695_boost_keyword_untap_new_server_package_precheck.sql`
- apply: `docs/hermes-analysis/master_optimizer_reports/pg695_boost_keyword_untap_new_server_package_apply.sql`
- rollback: `docs/hermes-analysis/master_optimizer_reports/pg695_boost_keyword_untap_new_server_package_rollback.sql`
- postcheck: `docs/hermes-analysis/master_optimizer_reports/pg695_boost_keyword_untap_new_server_package_postcheck.sql`
- manifest: `docs/hermes-analysis/master_optimizer_reports/pg695_boost_keyword_untap_new_server_package_manifest.json`
- package: `docs/hermes-analysis/master_optimizer_reports/pg695_boost_keyword_untap_new_server_package_package.md`

Apply gate:

- Do not run apply SQL without explicit approval for the exact command.
- Required sequence after approval: precheck, apply, postcheck, PG -> SQLite sync, focused/family tests, affected deck coherence audit.
