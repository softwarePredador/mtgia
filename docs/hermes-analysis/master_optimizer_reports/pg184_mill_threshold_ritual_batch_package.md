# PG184 XMage Batch PostgreSQL Package

Status: `applied_postchecked_synced`.

This package was generated from XMage batch proposals. The builder did not execute SQL; the approved sequence was executed afterward and its outputs are recorded below.

- Generated at: `2026-06-24T19:25:04+00:00`
- Selected cards: `["Brain Freeze", "Cabal Ritual"]`
- Families: `{"mill_spell": 1, "ramp_ritual": 1}`

Files:

- precheck: `docs/hermes-analysis/master_optimizer_reports/pg184_mill_threshold_ritual_batch_precheck.sql`
- apply: `docs/hermes-analysis/master_optimizer_reports/pg184_mill_threshold_ritual_batch_apply.sql`
- rollback: `docs/hermes-analysis/master_optimizer_reports/pg184_mill_threshold_ritual_batch_rollback.sql`
- postcheck: `docs/hermes-analysis/master_optimizer_reports/pg184_mill_threshold_ritual_batch_postcheck.sql`
- manifest: `docs/hermes-analysis/master_optimizer_reports/pg184_mill_threshold_ritual_batch_manifest.json`
- package: `docs/hermes-analysis/master_optimizer_reports/pg184_mill_threshold_ritual_batch_package.md`

Apply gate:

- Do not run apply SQL without explicit approval for the exact command.
- Required sequence after approval: precheck, apply, postcheck, PG -> SQLite sync, focused/family tests, affected deck coherence audit.

Executed evidence:

- precheck output: `docs/hermes-analysis/master_optimizer_reports/pg184_mill_threshold_ritual_batch_precheck_current_20260624.tsv`
- apply output: `docs/hermes-analysis/master_optimizer_reports/pg184_mill_threshold_ritual_batch_apply_current_20260624.out`
- postcheck output: `docs/hermes-analysis/master_optimizer_reports/pg184_mill_threshold_ritual_batch_postcheck_current_20260624.tsv`
- PG -> SQLite sync report: `docs/hermes-analysis/master_optimizer_reports/battle_card_rules_sqlite_from_pg_pg184_mill_threshold_ritual_20260624.json`
- postcheck result: `Brain Freeze` and `Cabal Ritual` each have one promoted rule row, one verified/auto row, one oracle-hash row, and four backup rows.
