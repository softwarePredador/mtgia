# PG133 Current Replay Exact Scope Batch One Validation - 2026-06-24 01:03 UTC

## Scope

- Promote exact XMage-backed scopes for six cards still exposed in the current
  `Lorehold + oponentes materializados` replay surface:
  - `Into the Flood Maw`
  - `Snap`
  - `Walking Ballista`
  - `Everflowing Chalice`
  - `Manamorphose`
  - `Tinder Wall`
- Deprecate the broad shadow rules these cards still resolved through.
- Sync the exact rules into Hermes SQLite/cache.
- Re-measure the replay-batch residual after the promotion.

## PostgreSQL Evidence

Package files:

- `docs/hermes-analysis/master_optimizer_reports/pg133_current_replay_exact_scope_batch_one_precheck.sql`
- `docs/hermes-analysis/master_optimizer_reports/pg133_current_replay_exact_scope_batch_one_apply.sql`
- `docs/hermes-analysis/master_optimizer_reports/pg133_current_replay_exact_scope_batch_one_postcheck.sql`
- `docs/hermes-analysis/master_optimizer_reports/pg133_current_replay_exact_scope_batch_one_rollback.sql`

Precheck result:

- `Everflowing Chalice`: `existing_rule_rows=3`,
  `would_deprecate_shadow_rows=3`
- `Into the Flood Maw`: `existing_rule_rows=2`,
  `would_deprecate_shadow_rows=2`
- `Manamorphose`: `existing_rule_rows=1`,
  `would_deprecate_shadow_rows=1`
- `Snap`: `existing_rule_rows=2`,
  `would_deprecate_shadow_rows=2`
- `Tinder Wall`: `existing_rule_rows=1`,
  `would_deprecate_shadow_rows=1`
- `Walking Ballista`: `existing_rule_rows=2`,
  `would_deprecate_shadow_rows=2`

Apply result:

- backup snapshot rows captured: `11`
- `deprecated_shadow_rows=11`
- `upserted_rows=6`

Postcheck result:

- all six cards have `promoted_rule_rows=1`
- all six cards have `promoted_verified_auto_rows=1`
- all six cards have `promoted_oracle_hash_rows=1`
- backup table retained `11` captured rows

Promoted scopes:

- `Into the Flood Maw` ->
  `gift_bounce_opponent_creature_or_nonland_v1`
- `Snap` ->
  `return_target_creature_then_untap_up_to_two_lands_v1`
- `Walking Ballista` ->
  `x_etb_counters_add_counter_or_remove_counter_ping_v1`
- `Everflowing Chalice` ->
  `multikicker_charge_counter_mana_rock_v1`
- `Manamorphose` ->
  `add_two_mana_any_combination_then_draw_v1`
- `Tinder Wall` ->
  `defender_sacrifice_for_rr_or_blocking_damage_v1`

## SQLite/Hermes Sync

Command:

```bash
python3 docs/hermes-analysis/manaloom-knowledge/scripts/sync_battle_card_rules_pg.py --apply-sqlite-from-pg --include-needs-review --only-card "Into the Flood Maw" --only-card "Snap" --only-card "Walking Ballista" --only-card "Everflowing Chalice" --only-card "Manamorphose" --only-card "Tinder Wall" --report docs/hermes-analysis/master_optimizer_reports/battle_card_rules_sqlite_from_pg_pg133_current_replay_exact_scope_batch_one_20260624_0103.json
```

Sync result:

- `selected_card_count=6`
- `pg_rows_loaded=17`
- `sqlite_inserted_or_updated=16`
- `generated_rows=4`
- `oracle_normalized_rows=2`
- `canonical_snapshot_rows_exported=3209`

## Test Evidence

- `python3 -m py_compile ...xmage_to_manaloom_effect_hints.py ...xmage_semantic_family_classifier.py ...test_xmage_to_manaloom_effect_hints.py ...test_xmage_semantic_family_batch_pipeline.py`
  passed.
- `PYTHONPATH=docs/hermes-analysis/manaloom-knowledge/scripts python3 -m unittest docs.hermes-analysis.manaloom-knowledge.scripts.test_xmage_to_manaloom_effect_hints docs.hermes-analysis.manaloom-knowledge.scripts.test_xmage_semantic_family_batch_pipeline`
  passed, `98 tests`.
- `PYTHONPATH=docs/hermes-analysis/manaloom-knowledge/scripts python3 -m unittest docs.hermes-analysis.manaloom-knowledge.scripts.test_battle_forensic_audit_supported_effects docs.hermes-analysis.manaloom-knowledge.scripts.test_runtime_pg_rule_fallback_for_promoted_hotfixes`
  passed, `3 tests`.

## Replay-Batch Evidence

Seed pipeline before PG133 apply:

- `docs/hermes-analysis/master_optimizer_reports/xmage_current_replay_batch_pipeline_20260624_pg133_seed_v2_manifest.json`
- `proposal_status_counts={"batch_pg_candidate_after_precheck":6,"blocked_missing_xmage_source":4,"mapper_metadata_or_test_scenario_required":247,"runtime_family_implementation_required":25,"split_family_scope_review_required":8}`

Post-sync pipeline:

- `docs/hermes-analysis/master_optimizer_reports/xmage_current_replay_batch_pipeline_20260624_pg133_postsync_real_manifest.json`
- `severity_counts={"critical":1,"high":242,"medium":41,"pass":257}`
- `validity_status_counts={"blocked_missing_xmage_class":4,"ready_for_structured_xmage_pull_review_required":33,"xmage_source_valid_mapper_required":247}`
- `proposal_status_counts={"blocked_missing_xmage_source":4,"mapper_metadata_or_test_scenario_required":247,"runtime_family_implementation_required":25,"split_family_scope_review_required":8}`

Observed delta versus PG132 post-sync:

- `pass`: `251 -> 257`
- `high`: `246 -> 242`
- `medium`: `43 -> 41`
- `ready_for_structured_xmage_pull_review_required`: `39 -> 33`
- `split_family_scope_review_required`: `14 -> 8`

## Current Reading

- PG133 is closed as applied, postchecked, synced, and validated.
- The current local-XMage replay surface residual is now concentrated in eight
  heavier cards:
  - `Agatha's Soul Cauldron`
  - `Necropotence`
  - `Archdruid's Charm`
  - `Sink into Stupor`
  - `Ruthless Technomancer`
  - `Emperor of Bones`
  - `Disciple of Freyalise`
  - `Vibrance`
- The next coherent pass should split these by structural weight rather than by
  raw deck order, because they are no longer simple generic-targeted variants.

## Rollback

- Rollback SQL exists at
  `docs/hermes-analysis/master_optimizer_reports/pg133_current_replay_exact_scope_batch_one_rollback.sql`
  and restores the captured rows from
  `manaloom_deploy_audit.pg133_current_replay_exact_scope_batch_one_20260624_0102`.
- Rollback was not executed because precheck, apply, postcheck, SQLite sync,
  tests, and post-sync replay-batch validation all passed.
