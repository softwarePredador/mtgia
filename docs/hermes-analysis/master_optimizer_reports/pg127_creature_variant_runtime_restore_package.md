# PG127 XMage Batch PostgreSQL Package

Status: `applied_postchecked_synced_validated`.

This package was generated from XMage batch proposals and then applied through
the standard PostgreSQL -> Hermes validation loop.

- Generated at: `2026-06-24T00:13:36+00:00`
- Selected cards: `["Colossal Skyturtle", "Abigale, Eloquent First-Year", "Glen Elendra Archmage"]`
- Families: `{"manual_model": 3}`

Files:

- precheck: `docs/hermes-analysis/master_optimizer_reports/pg127_creature_variant_runtime_restore_precheck.sql`
- apply: `docs/hermes-analysis/master_optimizer_reports/pg127_creature_variant_runtime_restore_apply.sql`
- rollback: `docs/hermes-analysis/master_optimizer_reports/pg127_creature_variant_runtime_restore_rollback.sql`
- postcheck: `docs/hermes-analysis/master_optimizer_reports/pg127_creature_variant_runtime_restore_postcheck.sql`
- manifest: `docs/hermes-analysis/master_optimizer_reports/pg127_creature_variant_runtime_restore_manifest.json`
- package: `docs/hermes-analysis/master_optimizer_reports/pg127_creature_variant_runtime_restore_package.md`

Apply gate:

- Do not run apply SQL without explicit approval for the exact command.
- Required sequence after approval: precheck, apply, postcheck, PG -> SQLite sync, focused/family tests, affected deck coherence audit.

Validation evidence:

- Precheck confirmed all 3 cards existed in `canonical_cards`, with
  `existing_rule_rows=0` and `would_deprecate_shadow_rows=0` for each target.
- Apply inserted `upserted_rows=3`, with `deprecated_shadow_rows=0`, and
  committed successfully.
- Postcheck confirmed `promoted_rule_rows=1`,
  `promoted_verified_auto_rows=1`, and `promoted_oracle_hash_rows=1` for all
  three cards.
- SQLite/Hermes targeted sync report:
  `docs/hermes-analysis/master_optimizer_reports/battle_card_rules_sqlite_from_pg_pg127_creature_variant_20260624_0016.json`
  with `pg_rows_loaded=3`, `sqlite_inserted_or_updated=3`, and
  `canonical_snapshot_rows_exported=3209`.
- Post-sync replay-batch pipeline:
  `docs/hermes-analysis/master_optimizer_reports/xmage_current_replay_batch_pipeline_20260624_pg127_postsync_real_manifest.json`
  with `severity_counts={"critical":1,"high":260,"medium":43,"pass":237}` and
  `proposal_status_counts={"blocked_missing_xmage_source":4,"mapper_metadata_or_test_scenario_required":247,"runtime_family_implementation_required":25,"split_family_scope_review_required":28}`.
