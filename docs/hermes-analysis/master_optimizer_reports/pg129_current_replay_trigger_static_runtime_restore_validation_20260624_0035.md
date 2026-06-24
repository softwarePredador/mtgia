# PG129 Current Replay Trigger Static Runtime Restore Validation - 2026-06-24 00:35 UTC

## Scope

- Promote exact XMage-backed scopes for three cards still exposed in the current
  replay surface:
  - `Faerie Mastermind`
  - `Vexing Bauble`
  - `Nezahal, Primal Tide`
- Deprecate the broad shadow rules these cards were still using.
- Sync the exact rules into Hermes SQLite/cache.
- Re-measure the replay-batch residual after the promotion.

## PostgreSQL Evidence

Package files:

- `docs/hermes-analysis/master_optimizer_reports/pg129_current_replay_trigger_static_runtime_restore_precheck.sql`
- `docs/hermes-analysis/master_optimizer_reports/pg129_current_replay_trigger_static_runtime_restore_apply.sql`
- `docs/hermes-analysis/master_optimizer_reports/pg129_current_replay_trigger_static_runtime_restore_postcheck.sql`
- `docs/hermes-analysis/master_optimizer_reports/pg129_current_replay_trigger_static_runtime_restore_rollback.sql`

Precheck result:

- `Faerie Mastermind`: `existing_rule_rows=2`,
  `would_deprecate_shadow_rows=2`
- `Nezahal, Primal Tide`: `existing_rule_rows=2`,
  `would_deprecate_shadow_rows=2`
- `Vexing Bauble`: `existing_rule_rows=3`,
  `would_deprecate_shadow_rows=3`

Apply result:

- backup snapshot rows captured: `7`
- `deprecated_shadow_rows=7`
- `upserted_rows=3`

Postcheck result:

- all three cards have `promoted_rule_rows=1`
- all three cards have `promoted_verified_auto_rows=1`
- all three cards have `promoted_oracle_hash_rows=1`
- backup table retained `7` captured rows

Promoted scopes:

- `Faerie Mastermind` ->
  `flash_flying_second_opponent_draw_draw_one_and_activated_each_player_draw_v1`
- `Vexing Bauble` ->
  `counter_no_mana_spent_spells_and_cantrip_sacrifice_v1`
- `Nezahal, Primal Tide` ->
  `cant_be_countered_no_max_hand_opponent_noncreature_cast_draw_exile_blink_v1`

## SQLite/Hermes Sync

Command:

```bash
python3 docs/hermes-analysis/manaloom-knowledge/scripts/sync_battle_card_rules_pg.py --apply-sqlite-from-pg --include-needs-review --only-card "Faerie Mastermind" --only-card "Vexing Bauble" --only-card "Nezahal, Primal Tide" --report docs/hermes-analysis/master_optimizer_reports/battle_card_rules_sqlite_from_pg_pg129_current_replay_trigger_static_20260624_0035.json
```

Sync result:

- `selected_card_count=3`
- `pg_rows_loaded=10`
- `sqlite_inserted_or_updated=9`
- `generated_rows=3`
- `curated_rows=1`
- `canonical_snapshot_rows_exported=3209`

## Test Evidence

- `python3 -m py_compile ...xmage_to_manaloom_effect_hints.py ...xmage_semantic_family_classifier.py ...test_xmage_to_manaloom_effect_hints.py ...test_xmage_semantic_family_batch_pipeline.py`
  passed.
- `PYTHONPATH=docs/hermes-analysis/manaloom-knowledge/scripts python3 -m unittest docs.hermes-analysis.manaloom-knowledge.scripts.test_xmage_to_manaloom_effect_hints docs.hermes-analysis.manaloom-knowledge.scripts.test_xmage_semantic_family_batch_pipeline`
  passed, `76 tests`.
- `PYTHONPATH=docs/hermes-analysis/manaloom-knowledge/scripts python3 -m unittest docs.hermes-analysis.manaloom-knowledge.scripts.test_battle_forensic_audit_supported_effects docs.hermes-analysis.manaloom-knowledge.scripts.test_runtime_pg_rule_fallback_for_promoted_hotfixes`
  passed, `3 tests`.

## Replay-Batch Evidence

Seed pipeline before PG129 apply:

- `docs/hermes-analysis/master_optimizer_reports/xmage_current_replay_batch_pipeline_20260624_pg129_seed_manifest.json`
- `proposal_status_counts={"batch_pg_candidate_after_precheck":4,"blocked_missing_xmage_source":4,"mapper_metadata_or_test_scenario_required":247,"runtime_family_implementation_required":25,"split_family_scope_review_required":19}`

Post-sync pipeline:

- `docs/hermes-analysis/master_optimizer_reports/xmage_current_replay_batch_pipeline_20260624_pg129_postsync_real_manifest.json`
- `severity_counts={"critical":1,"high":252,"medium":43,"pass":245}`
- `validity_status_counts={"blocked_missing_xmage_class":4,"ready_for_structured_xmage_pull_review_required":45,"xmage_source_valid_mapper_required":247}`
- `proposal_status_counts={"batch_pg_candidate_after_precheck":1,"blocked_missing_xmage_source":4,"mapper_metadata_or_test_scenario_required":247,"runtime_family_implementation_required":25,"split_family_scope_review_required":19}`

Observed delta versus PG128 post-sync:

- `pass`: `242 -> 245`
- `high`: `255 -> 252`
- `ready_for_structured_xmage_pull_review_required`: `48 -> 45`

## Current Reading

- PG129 is closed as applied, postchecked, synced, and validated.
- The only remaining batch-safe card after PG129 was `Goblin Bombardment`,
  which remained outside the current replay-surface subset but still inside the
  audited deck queue.

## Rollback

- Rollback SQL exists at
  `docs/hermes-analysis/master_optimizer_reports/pg129_current_replay_trigger_static_runtime_restore_rollback.sql`
  and restores the captured rows from
  `manaloom_deploy_audit.pg129_current_replay_trigger_static_runtime_restore_2026`.
- Rollback was not executed because precheck, apply, postcheck, SQLite sync,
  tests, and post-sync replay-batch validation all passed.
