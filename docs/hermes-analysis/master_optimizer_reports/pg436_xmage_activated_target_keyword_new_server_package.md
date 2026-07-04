# pg436 XMage Batch PostgreSQL Package

Status: `prepared_read_only_pending_apply_approval`.

This package was generated from XMage batch proposals. No SQL was executed by the builder.

- Generated at: `2026-07-04T21:40:25+00:00`
- Selected cards: `["Accursed Horde", "Air Marshal", "Alabaster Mage", "Axgard Cavalry", "Beacon Behemoth", "Bloodlust Inciter", "Bloodthorn Taunter", "Crimson Mage", "Goblin Motivator", "Hotfoot Gnome", "Jawbone Skulkin", "Kelsinko Ranger", "Krosan Groundshaker", "Might Weaver", "Mosstodon", "Onyx Mage", "Rage Weaver", "Rakeclaw Gargantuan", "Sky Weaver", "Sootstoke Kindler", "Spearbreaker Behemoth", "Trailblazing Historian", "Whalebone Glider", "Whip Sergeant"]`
- Families: `{"xmage_permanent_simple_activated_target_keyword_until_eot": 24}`

Files:

- precheck: `../../master_optimizer_reports/pg436_xmage_activated_target_keyword_new_server_precheck.sql`
- apply: `../../master_optimizer_reports/pg436_xmage_activated_target_keyword_new_server_apply.sql`
- rollback: `../../master_optimizer_reports/pg436_xmage_activated_target_keyword_new_server_rollback.sql`
- postcheck: `../../master_optimizer_reports/pg436_xmage_activated_target_keyword_new_server_postcheck.sql`
- manifest: `../../master_optimizer_reports/pg436_xmage_activated_target_keyword_new_server_manifest.json`
- package: `../../master_optimizer_reports/pg436_xmage_activated_target_keyword_new_server_package.md`

Apply gate:

- Do not run apply SQL without explicit approval for the exact command.
- Required sequence after approval: precheck, apply, postcheck, PG -> SQLite sync, focused/family tests, affected deck coherence audit.
