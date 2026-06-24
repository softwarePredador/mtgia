# PG131 XMage Batch PostgreSQL Package

Status: `applied_postchecked_synced_validated`.

This package was generated from XMage batch proposals and then applied through
the standard PostgreSQL -> Hermes validation loop.

- Generated at: `2026-06-24T00:43:27+00:00`
- Selected cards: `["Wan Shi Tong, Librarian", "Hullbreaker Horror", "Teferi, Time Raveler"]`
- Families: `{"manual_model": 3}`

Files:

- precheck: `docs/hermes-analysis/master_optimizer_reports/pg131_current_replay_precision_scope_runtime_restore_precheck.sql`
- apply: `docs/hermes-analysis/master_optimizer_reports/pg131_current_replay_precision_scope_runtime_restore_apply.sql`
- rollback: `docs/hermes-analysis/master_optimizer_reports/pg131_current_replay_precision_scope_runtime_restore_rollback.sql`
- postcheck: `docs/hermes-analysis/master_optimizer_reports/pg131_current_replay_precision_scope_runtime_restore_postcheck.sql`
- manifest: `docs/hermes-analysis/master_optimizer_reports/pg131_current_replay_precision_scope_runtime_restore_manifest.json`
- package: `docs/hermes-analysis/master_optimizer_reports/pg131_current_replay_precision_scope_runtime_restore_package.md`

Apply gate:

- Do not run apply SQL without explicit approval for the exact command.
- Required sequence after approval: precheck, apply, postcheck, PG -> SQLite sync, focused/family tests, affected deck coherence audit.

Validation evidence:

- Precheck found all 3 targets present in `canonical_cards`; broad active rows
  would be deprecated as shadow rows (`6` total).
- Apply inserted `upserted_rows=3`, deprecated `6` shadow rows, and committed.
- Postcheck confirmed `promoted_rule_rows=1`,
  `promoted_verified_auto_rows=1`, and `promoted_oracle_hash_rows=1` for all
  three cards.
- SQLite/Hermes targeted sync report:
  `docs/hermes-analysis/master_optimizer_reports/battle_card_rules_sqlite_from_pg_pg131_current_replay_precision_scope_20260624_0044.json`
  with `pg_rows_loaded=9`, `sqlite_inserted_or_updated=9`, and
  `canonical_snapshot_rows_exported=3209`.
- Post-sync replay-batch pipeline:
  `docs/hermes-analysis/master_optimizer_reports/xmage_current_replay_batch_pipeline_20260624_pg131_postsync_real_manifest.json`
  with `severity_counts={"critical":1,"high":248,"medium":43,"pass":249}` and
  `proposal_status_counts={"blocked_missing_xmage_source":4,"mapper_metadata_or_test_scenario_required":247,"runtime_family_implementation_required":25,"split_family_scope_review_required":16}`.
