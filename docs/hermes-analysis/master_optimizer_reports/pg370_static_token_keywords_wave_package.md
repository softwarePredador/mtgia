# PG370 XMage Batch PostgreSQL Package

Status: `prepared_read_only_pending_apply_approval`.

This package was generated from XMage batch proposals. No SQL was executed by the builder.

- Generated at: `2026-07-02T10:29:50+00:00`
- Selected cards: `["Advent of the Wurm", "Call the Cavalry", "Call to the Feast", "Jungleborn Pioneer", "Knight Watch", "Paladin of the Bloodstained", "Queen's Commission", "Sworn Companions"]`
- Families: `{"xmage_creature_etb_create_tokens": 2, "xmage_fixed_create_creature_tokens_spell": 6}`

Files:

- precheck: `docs/hermes-analysis/master_optimizer_reports/pg370_static_token_keywords_wave_precheck.sql`
- apply: `docs/hermes-analysis/master_optimizer_reports/pg370_static_token_keywords_wave_apply.sql`
- rollback: `docs/hermes-analysis/master_optimizer_reports/pg370_static_token_keywords_wave_rollback.sql`
- postcheck: `docs/hermes-analysis/master_optimizer_reports/pg370_static_token_keywords_wave_postcheck.sql`
- manifest: `docs/hermes-analysis/master_optimizer_reports/pg370_static_token_keywords_wave_manifest.json`
- package: `docs/hermes-analysis/master_optimizer_reports/pg370_static_token_keywords_wave_package.md`

Apply gate:

- Do not run apply SQL without explicit approval for the exact command.
- Required sequence after approval: precheck, apply, postcheck, PG -> SQLite sync, focused/family tests, affected deck coherence audit.
