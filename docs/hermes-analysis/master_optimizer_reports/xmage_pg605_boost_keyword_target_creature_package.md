# PG605 XMage Batch PostgreSQL Package

Status: `prepared_read_only_pending_apply_approval`.

This package was generated from XMage batch proposals. No SQL was executed by the builder.

- Generated at: `2026-07-07T08:58:25+00:00`
- Selected cards: `["Armor of Shadows", "Blitzball Shot", "Massive Might", "Masterful Flourish"]`
- Families: `{"xmage_boost_keyword_target_creature_until_eot_spell": 4}`

Files:

- precheck: `docs/hermes-analysis/master_optimizer_reports/xmage_pg605_boost_keyword_target_creature_precheck.sql`
- apply: `docs/hermes-analysis/master_optimizer_reports/xmage_pg605_boost_keyword_target_creature_apply.sql`
- rollback: `docs/hermes-analysis/master_optimizer_reports/xmage_pg605_boost_keyword_target_creature_rollback.sql`
- postcheck: `docs/hermes-analysis/master_optimizer_reports/xmage_pg605_boost_keyword_target_creature_postcheck.sql`
- manifest: `docs/hermes-analysis/master_optimizer_reports/xmage_pg605_boost_keyword_target_creature_manifest.json`
- package: `docs/hermes-analysis/master_optimizer_reports/xmage_pg605_boost_keyword_target_creature_package.md`

Apply gate:

- Do not run apply SQL without explicit approval for the exact command.
- Required sequence after approval: precheck, apply, postcheck, PG -> SQLite sync, focused/family tests, affected deck coherence audit.
