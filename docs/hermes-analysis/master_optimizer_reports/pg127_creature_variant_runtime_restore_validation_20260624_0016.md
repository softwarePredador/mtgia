# PG127 Creature Variant Runtime Restore Validation - 2026-06-24 00:16 UTC

## Scope

- Promote three XMage-backed exact creature scopes into PostgreSQL
  `card_battle_rules`:
  - `Colossal Skyturtle`
  - `Abigale, Eloquent First-Year`
  - `Glen Elendra Archmage`
- Sync the promoted rules into local Hermes SQLite/cache.
- Re-run focused tests and the XMage replay-batch pipeline to confirm the
  residual queue moved in the expected direction.

## PostgreSQL Evidence

Package files:

- `docs/hermes-analysis/master_optimizer_reports/pg127_creature_variant_runtime_restore_precheck.sql`
- `docs/hermes-analysis/master_optimizer_reports/pg127_creature_variant_runtime_restore_apply.sql`
- `docs/hermes-analysis/master_optimizer_reports/pg127_creature_variant_runtime_restore_postcheck.sql`
- `docs/hermes-analysis/master_optimizer_reports/pg127_creature_variant_runtime_restore_rollback.sql`

Precheck result:

- `Colossal Skyturtle`: `target_card_rows=1`, `existing_rule_rows=0`,
  `would_deprecate_shadow_rows=0`
- `Abigale, Eloquent First-Year`: `target_card_rows=1`,
  `existing_rule_rows=0`, `would_deprecate_shadow_rows=0`
- `Glen Elendra Archmage`: `target_card_rows=1`, `existing_rule_rows=0`,
  `would_deprecate_shadow_rows=0`

Apply result:

- `deprecated_shadow_rows=0`
- `upserted_rows=3`
- transaction committed successfully

Postcheck result:

- all three cards have `promoted_rule_rows=1`
- all three cards have `promoted_verified_auto_rows=1`
- all three cards have `promoted_oracle_hash_rows=1`
- all three cards have `backup_rows=0`

Promoted scopes:

- `Colossal Skyturtle` ->
  `flying_ward_channel_regrowth_or_bounce_creature_v1`
- `Abigale, Eloquent First-Year` ->
  `etb_strip_other_creature_abilities_and_grant_keyword_counters_v1`
- `Glen Elendra Archmage` ->
  `flying_persist_sacrifice_self_counter_noncreature_spell_v1`

## SQLite/Hermes Sync

Command:

```bash
python3 docs/hermes-analysis/manaloom-knowledge/scripts/sync_battle_card_rules_pg.py --apply-sqlite-from-pg --include-needs-review --only-card "Colossal Skyturtle" --only-card "Abigale, Eloquent First-Year" --only-card "Glen Elendra Archmage" --report docs/hermes-analysis/master_optimizer_reports/battle_card_rules_sqlite_from_pg_pg127_creature_variant_20260624_0016.json
```

Sync result:

- `selected_card_count=3`
- `pg_rows_loaded=3`
- `sqlite_inserted_or_updated=3`
- `canonical_snapshot_rows_exported=3209`

## Test Evidence

- `python3 -m py_compile docs/hermes-analysis/manaloom-knowledge/scripts/xmage_to_manaloom_effect_hints.py docs/hermes-analysis/manaloom-knowledge/scripts/xmage_semantic_family_classifier.py docs/hermes-analysis/manaloom-knowledge/scripts/test_xmage_to_manaloom_effect_hints.py docs/hermes-analysis/manaloom-knowledge/scripts/test_xmage_semantic_family_batch_pipeline.py`
  passed.
- `PYTHONPATH=docs/hermes-analysis/manaloom-knowledge/scripts python3 -m unittest docs.hermes-analysis.manaloom-knowledge.scripts.test_xmage_to_manaloom_effect_hints docs.hermes-analysis.manaloom-knowledge.scripts.test_xmage_semantic_family_batch_pipeline`
  passed, `58 tests`.
- `PYTHONPATH=docs/hermes-analysis/manaloom-knowledge/scripts python3 -m unittest docs.hermes-analysis.manaloom-knowledge.scripts.test_battle_forensic_audit_supported_effects docs.hermes-analysis.manaloom-knowledge.scripts.test_runtime_pg_rule_fallback_for_promoted_hotfixes`
  passed, `3 tests`.

## Replay-Batch Evidence

Seed pipeline before PG apply:

- `docs/hermes-analysis/master_optimizer_reports/xmage_current_replay_batch_pipeline_20260624_pg127_seed_manifest.json`
- `proposal_status_counts={"batch_pg_candidate_after_precheck":3,"blocked_missing_xmage_source":4,"mapper_metadata_or_test_scenario_required":247,"runtime_family_implementation_required":25,"split_family_scope_review_required":28}`

Post-sync pipeline:

- `docs/hermes-analysis/master_optimizer_reports/xmage_current_replay_batch_pipeline_20260624_pg127_postsync_real_manifest.json`
- `severity_counts={"critical":1,"high":260,"medium":43,"pass":237}`
- `validity_status_counts={"blocked_missing_xmage_class":4,"ready_for_structured_xmage_pull_review_required":53,"xmage_source_valid_mapper_required":247}`
- `proposal_status_counts={"blocked_missing_xmage_source":4,"mapper_metadata_or_test_scenario_required":247,"runtime_family_implementation_required":25,"split_family_scope_review_required":28}`

Observed delta versus the PG126 post-sync baseline:

- `pass`: `234 -> 237`
- `high`: `263 -> 260`
- `ready_for_structured_xmage_pull_review_required`: `56 -> 53`
- `batch_pg_candidate_after_precheck`: `3 -> 0`

## Current Reading

- PG127 is closed as applied, postchecked, synced to Hermes, and validated by
  tests plus replay-batch residual movement.
- `Emperor of Bones` remains intentionally outside this lot; it still lands in
  `split_family_scope_review_required` under
  `targeted_exile_variant_v1`.
- The next queue should stay focused on real residual families now that this
  creature trio is out of the backlog:
  `source_controller_draw_variant_v1`,
  `targeted_return_to_hand_variant_v1`,
  `targeted_exile_variant_v1`,
  `targeted_damage_variant_v1`,
  `targeted_add_counters_variant_v1`.

## Rollback

- Rollback SQL exists at
  `docs/hermes-analysis/master_optimizer_reports/pg127_creature_variant_runtime_restore_rollback.sql`
  and restores the captured rows from
  `manaloom_deploy_audit.pg127_creature_variant_runtime_restore_20260624_001336`.
- Rollback was not executed because precheck, apply, postcheck, SQLite sync,
  tests, and post-sync replay-batch validation all passed.
