# PG130 XMage Batch PostgreSQL Package

Status: `applied_postchecked_synced_validated`.

This package was generated from XMage batch proposals and then applied through
the standard PostgreSQL -> Hermes validation loop.

- Generated at: `2026-06-24T00:36:05+00:00`
- Selected cards: `["Goblin Bombardment"]`
- Families: `{"targeted_interaction": 1}`

Files:

- precheck: `docs/hermes-analysis/master_optimizer_reports/pg130_goblin_bombardment_exact_runtime_restore_precheck.sql`
- apply: `docs/hermes-analysis/master_optimizer_reports/pg130_goblin_bombardment_exact_runtime_restore_apply.sql`
- rollback: `docs/hermes-analysis/master_optimizer_reports/pg130_goblin_bombardment_exact_runtime_restore_rollback.sql`
- postcheck: `docs/hermes-analysis/master_optimizer_reports/pg130_goblin_bombardment_exact_runtime_restore_postcheck.sql`
- manifest: `docs/hermes-analysis/master_optimizer_reports/pg130_goblin_bombardment_exact_runtime_restore_manifest.json`
- package: `docs/hermes-analysis/master_optimizer_reports/pg130_goblin_bombardment_exact_runtime_restore_package.md`

Apply gate:

- Do not run apply SQL without explicit approval for the exact command.
- Required sequence after approval: precheck, apply, postcheck, PG -> SQLite sync, focused/family tests, affected deck coherence audit.

Validation evidence:

- Precheck found `Goblin Bombardment` with active broad rows already present and
  `would_deprecate_shadow_rows=3`.
- Apply inserted `upserted_rows=1`, deprecated `3` shadow rows, and committed.
- Postcheck confirmed `promoted_rule_rows=1`,
  `promoted_verified_auto_rows=1`, and `promoted_oracle_hash_rows=1`.
- SQLite/Hermes targeted sync report:
  `docs/hermes-analysis/master_optimizer_reports/battle_card_rules_sqlite_from_pg_pg130_goblin_bombardment_20260624_0036.json`
  with `pg_rows_loaded=4`, `sqlite_inserted_or_updated=4`, and
  `canonical_snapshot_rows_exported=3209`.
- Post-sync replay-batch pipeline:
  `docs/hermes-analysis/master_optimizer_reports/xmage_current_replay_batch_pipeline_20260624_pg130_postsync_real_manifest.json`
  with `severity_counts={"critical":1,"high":251,"medium":43,"pass":246}` and
  `proposal_status_counts={"blocked_missing_xmage_source":4,"mapper_metadata_or_test_scenario_required":247,"runtime_family_implementation_required":25,"split_family_scope_review_required":19}`.
