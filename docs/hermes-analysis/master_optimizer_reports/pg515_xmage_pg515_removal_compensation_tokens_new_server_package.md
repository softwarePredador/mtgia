# PG515 XMage Batch PostgreSQL Package

Status: `prepared_read_only_pending_apply_approval`.

This package was generated from XMage batch proposals. No SQL was executed by the builder.

- Generated at: `2026-07-05T15:50:01+00:00`
- Selected cards: `["Afterlife", "Angelic Ascension", "Beast Within", "Bovine Intervention", "Harsh Annotation", "Reduce to Memory", "Secure the Scene"]`
- Families: `{"xmage_destroy_target_controller_creature_token_compensation_spell": 4, "xmage_exile_target_controller_creature_token_compensation_spell": 3}`

Files:

- precheck: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/pg515_xmage_pg515_removal_compensation_tokens_new_server_precheck.sql`
- apply: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/pg515_xmage_pg515_removal_compensation_tokens_new_server_apply.sql`
- rollback: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/pg515_xmage_pg515_removal_compensation_tokens_new_server_rollback.sql`
- postcheck: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/pg515_xmage_pg515_removal_compensation_tokens_new_server_postcheck.sql`
- manifest: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/pg515_xmage_pg515_removal_compensation_tokens_new_server_manifest.json`
- package: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/pg515_xmage_pg515_removal_compensation_tokens_new_server_package.md`

Apply gate:

- Do not run apply SQL without explicit approval for the exact command.
- Required sequence after approval: precheck, apply, postcheck, PG -> SQLite sync, focused/family tests, affected deck coherence audit.
