# PG133 XMage Batch PostgreSQL Package

Status: `applied_postchecked_synced_validated`.

This package was generated from XMage batch proposals and then applied through
the standard PostgreSQL -> Hermes validation loop.

- Generated at: `2026-06-24T01:02:13+00:00`
- Selected cards: `["Into the Flood Maw", "Snap", "Walking Ballista", "Everflowing Chalice", "Manamorphose", "Tinder Wall"]`
- Families: `{"manual_model": 3, "targeted_interaction": 3}`

Files:

- precheck: `docs/hermes-analysis/master_optimizer_reports/pg133_current_replay_exact_scope_batch_one_precheck.sql`
- apply: `docs/hermes-analysis/master_optimizer_reports/pg133_current_replay_exact_scope_batch_one_apply.sql`
- rollback: `docs/hermes-analysis/master_optimizer_reports/pg133_current_replay_exact_scope_batch_one_rollback.sql`
- postcheck: `docs/hermes-analysis/master_optimizer_reports/pg133_current_replay_exact_scope_batch_one_postcheck.sql`
- manifest: `docs/hermes-analysis/master_optimizer_reports/pg133_current_replay_exact_scope_batch_one_manifest.json`
- package: `docs/hermes-analysis/master_optimizer_reports/pg133_current_replay_exact_scope_batch_one_package.md`

Apply gate:

- Do not run apply SQL without explicit approval for the exact command.
- Required sequence after approval: precheck, apply, postcheck, PG -> SQLite sync, focused/family tests, affected deck coherence audit.

Validation evidence:

- Precheck found all six targets present in `canonical_cards`; broad active rows
  would be deprecated as shadow rows (`11` total).
- Apply inserted `upserted_rows=6`, deprecated `11` shadow rows, and committed.
- Postcheck confirmed `promoted_rule_rows=1`,
  `promoted_verified_auto_rows=1`, and `promoted_oracle_hash_rows=1` for all
  six cards.
- SQLite/Hermes targeted sync report:
  `docs/hermes-analysis/master_optimizer_reports/battle_card_rules_sqlite_from_pg_pg133_current_replay_exact_scope_batch_one_20260624_0103.json`
  with `pg_rows_loaded=17`, `sqlite_inserted_or_updated=16`, and
  `canonical_snapshot_rows_exported=3209`.
- Post-sync replay-batch pipeline:
  `docs/hermes-analysis/master_optimizer_reports/xmage_current_replay_batch_pipeline_20260624_pg133_postsync_real_manifest.json`
  with `severity_counts={"critical":1,"high":242,"medium":41,"pass":257}` and
  `proposal_status_counts={"blocked_missing_xmage_source":4,"mapper_metadata_or_test_scenario_required":247,"runtime_family_implementation_required":25,"split_family_scope_review_required":8}`.
