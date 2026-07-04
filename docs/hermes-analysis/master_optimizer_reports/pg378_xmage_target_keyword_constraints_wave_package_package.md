# pg378 XMage Batch PostgreSQL Package

Status: `prepared_read_only_pending_apply_approval`.

This package was generated from XMage batch proposals. No SQL was executed by the builder.

- Generated at: `2026-07-04T02:04:37+00:00`
- Selected cards: `["Accursed Horde", "Air Marshal", "Beacon Behemoth", "Bloodthorn Taunter", "Hotfoot Gnome", "Jawbone Skulkin", "Kelsinko Ranger", "Krosan Groundshaker", "Might Weaver", "Mosstodon", "Rage Weaver", "Rakeclaw Gargantuan", "Sky Weaver", "Sootstoke Kindler", "Spearbreaker Behemoth", "Whalebone Glider"]`
- Families: `{"xmage_permanent_simple_activated_target_keyword_until_eot": 16}`

Files:

- precheck: `docs/hermes-analysis/master_optimizer_reports/pg378_xmage_target_keyword_constraints_wave_package_precheck.sql`
- apply: `docs/hermes-analysis/master_optimizer_reports/pg378_xmage_target_keyword_constraints_wave_package_apply.sql`
- rollback: `docs/hermes-analysis/master_optimizer_reports/pg378_xmage_target_keyword_constraints_wave_package_rollback.sql`
- postcheck: `docs/hermes-analysis/master_optimizer_reports/pg378_xmage_target_keyword_constraints_wave_package_postcheck.sql`
- manifest: `docs/hermes-analysis/master_optimizer_reports/pg378_xmage_target_keyword_constraints_wave_package_manifest.json`
- package: `docs/hermes-analysis/master_optimizer_reports/pg378_xmage_target_keyword_constraints_wave_package_package.md`

Apply gate:

- Do not run apply SQL without explicit approval for the exact command.
- Required sequence after approval: precheck, apply, postcheck, PG -> SQLite sync, focused/family tests, affected deck coherence audit.
