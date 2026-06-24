# PG131 Current Replay Precision Scope Runtime Restore Validation - 2026-06-24 00:44 UTC

## Scope

- Promote exact XMage-backed scopes for three cards still exposed in the current
  replay surface:
  - `Wan Shi Tong, Librarian`
  - `Hullbreaker Horror`
  - `Teferi, Time Raveler`
- Deprecate the broad shadow rules those cards still resolved through.
- Sync the exact rules into Hermes SQLite/cache.
- Re-measure the replay-batch residual after the promotion.

## PostgreSQL Evidence

Package files:

- `docs/hermes-analysis/master_optimizer_reports/pg131_current_replay_precision_scope_runtime_restore_precheck.sql`
- `docs/hermes-analysis/master_optimizer_reports/pg131_current_replay_precision_scope_runtime_restore_apply.sql`
- `docs/hermes-analysis/master_optimizer_reports/pg131_current_replay_precision_scope_runtime_restore_postcheck.sql`
- `docs/hermes-analysis/master_optimizer_reports/pg131_current_replay_precision_scope_runtime_restore_rollback.sql`

Precheck result:

- `Hullbreaker Horror`: `existing_rule_rows=2`,
  `would_deprecate_shadow_rows=2`
- `Teferi, Time Raveler`: `existing_rule_rows=2`,
  `would_deprecate_shadow_rows=2`
- `Wan Shi Tong, Librarian`: `existing_rule_rows=2`,
  `would_deprecate_shadow_rows=2`

Apply result:

- backup snapshot rows captured: `6`
- `deprecated_shadow_rows=6`
- `upserted_rows=3`

Postcheck result:

- all three cards have `promoted_rule_rows=1`
- all three cards have `promoted_verified_auto_rows=1`
- all three cards have `promoted_oracle_hash_rows=1`
- backup table retained `6` captured rows

Promoted scopes:

- `Wan Shi Tong, Librarian` ->
  `flash_flying_vigilance_etb_x_counters_draw_half_x_opponent_search_growth_v1`
- `Hullbreaker Horror` ->
  `flash_cant_be_countered_cast_spell_bounce_spell_or_nonland_v1`
- `Teferi, Time Raveler` ->
  `opponents_sorcery_speed_only_plus1_sorcery_flash_minus3_bounce_draw_v1`

## SQLite/Hermes Sync

Command:

```bash
python3 docs/hermes-analysis/manaloom-knowledge/scripts/sync_battle_card_rules_pg.py --apply-sqlite-from-pg --include-needs-review --only-card "Wan Shi Tong, Librarian" --only-card "Hullbreaker Horror" --only-card "Teferi, Time Raveler" --report docs/hermes-analysis/master_optimizer_reports/battle_card_rules_sqlite_from_pg_pg131_current_replay_precision_scope_20260624_0044.json
```

Sync result:

- `selected_card_count=3`
- `pg_rows_loaded=9`
- `sqlite_inserted_or_updated=9`
- `generated_rows=3`
- `canonical_snapshot_rows_exported=3209`

## Test Evidence

- `python3 -m py_compile ...xmage_to_manaloom_effect_hints.py ...xmage_semantic_family_classifier.py ...test_xmage_to_manaloom_effect_hints.py ...test_xmage_semantic_family_batch_pipeline.py`
  passed.
- `PYTHONPATH=docs/hermes-analysis/manaloom-knowledge/scripts python3 -m unittest docs.hermes-analysis.manaloom-knowledge.scripts.test_xmage_to_manaloom_effect_hints docs.hermes-analysis.manaloom-knowledge.scripts.test_xmage_semantic_family_batch_pipeline`
  passed, `82 tests`.
- `PYTHONPATH=docs/hermes-analysis/manaloom-knowledge/scripts python3 -m unittest docs.hermes-analysis.manaloom-knowledge.scripts.test_battle_forensic_audit_supported_effects docs.hermes-analysis.manaloom-knowledge.scripts.test_runtime_pg_rule_fallback_for_promoted_hotfixes`
  passed, `3 tests`.

## Replay-Batch Evidence

Seed pipeline before PG131 apply:

- `docs/hermes-analysis/master_optimizer_reports/xmage_current_replay_batch_pipeline_20260624_pg131_seed_manifest.json`
- `proposal_status_counts={"batch_pg_candidate_after_precheck":3,"blocked_missing_xmage_source":4,"mapper_metadata_or_test_scenario_required":247,"runtime_family_implementation_required":25,"split_family_scope_review_required":16}`

Post-sync pipeline:

- `docs/hermes-analysis/master_optimizer_reports/xmage_current_replay_batch_pipeline_20260624_pg131_postsync_real_manifest.json`
- `severity_counts={"critical":1,"high":248,"medium":43,"pass":249}`
- `validity_status_counts={"blocked_missing_xmage_class":4,"ready_for_structured_xmage_pull_review_required":41,"xmage_source_valid_mapper_required":247}`
- `proposal_status_counts={"blocked_missing_xmage_source":4,"mapper_metadata_or_test_scenario_required":247,"runtime_family_implementation_required":25,"split_family_scope_review_required":16}`

Observed delta versus PG130 post-sync:

- `pass`: `246 -> 249`
- `high`: `251 -> 248`
- `ready_for_structured_xmage_pull_review_required`: `44 -> 41`

## Current Reading

- PG131 is closed as applied, postchecked, synced, and validated.
- The replay-surface residual shrank by three more exact cards with XMage local
  source.
- The remaining split-family queue is now smaller and more concentrated in the
  harder local-XMage/manual cases.

## Rollback

- Rollback SQL exists at
  `docs/hermes-analysis/master_optimizer_reports/pg131_current_replay_precision_scope_runtime_restore_rollback.sql`
  and restores the captured rows from
  `manaloom_deploy_audit.pg131_current_replay_precision_scope_runtime_restore_20260624_004327`.
- Rollback was not executed because precheck, apply, postcheck, SQLite sync,
  tests, and post-sync replay-batch validation all passed.
