# PG136 Current Replay Exact Scope Batch Three Validation - 2026-06-24 01:37 UTC

## Scope

- Promote the final two local-XMage residual cards still present in the real
  `Lorehold + oponentes usados` replay surface:
  - `Agatha's Soul Cauldron`
  - `Necropotence`
- Replace their generic fallback interpretations with exact XMage-backed
  semantic scopes.
- Sync the promoted rules into Hermes SQLite/cache.
- Re-run the full replay batch to prove that no local-XMage residual remains.

## PostgreSQL Evidence

Package files:

- `docs/hermes-analysis/master_optimizer_reports/pg136_current_replay_exact_scope_batch_three_precheck.sql`
- `docs/hermes-analysis/master_optimizer_reports/pg136_current_replay_exact_scope_batch_three_apply.sql`
- `docs/hermes-analysis/master_optimizer_reports/pg136_current_replay_exact_scope_batch_three_postcheck.sql`
- `docs/hermes-analysis/master_optimizer_reports/pg136_current_replay_exact_scope_batch_three_rollback.sql`

Precheck result:

- `Agatha's Soul Cauldron`: `target_card_rows=1`, `existing_rule_rows=2`,
  `would_deprecate_shadow_rows=2`
- `Necropotence`: `target_card_rows=1`, `existing_rule_rows=2`,
  `would_deprecate_shadow_rows=2`

Apply result:

- `deprecated_shadow_rows=4`
- `upserted_rows=2`

Postcheck result:

- both cards have `promoted_rule_rows=1`
- both cards have `promoted_verified_auto_rows=1`
- both cards have `promoted_oracle_hash_rows=1`
- backup table retained `4` captured rows

Promoted scopes:

- `Agatha's Soul Cauldron` ->
  `graveyard_exile_counter_and_ability_grant_artifact_v1`
- `Necropotence` ->
  `skip_draw_discard_exile_pay_life_face_down_draw_next_end_step_v1`

## SQLite/Hermes Sync

Command:

```bash
python3 docs/hermes-analysis/manaloom-knowledge/scripts/sync_battle_card_rules_pg.py --apply-sqlite-from-pg --include-needs-review --only-card "Agatha's Soul Cauldron" --only-card "Necropotence" --report docs/hermes-analysis/master_optimizer_reports/battle_card_rules_sqlite_from_pg_pg136_current_replay_exact_scope_batch_three_20260624_0137.json
```

Sync result:

- `selected_card_count=2`
- `pg_rows_loaded=6`
- `sqlite_inserted_or_updated=6`
- `generated_rows=2`
- `oracle_normalized_rows=1`
- `canonical_snapshot_rows_exported=3211`

## Test Evidence

- `python3 -m py_compile docs/hermes-analysis/manaloom-knowledge/scripts/xmage_to_manaloom_effect_hints.py docs/hermes-analysis/manaloom-knowledge/scripts/xmage_semantic_family_classifier.py docs/hermes-analysis/manaloom-knowledge/scripts/xmage_effect_json_batch_generator.py docs/hermes-analysis/manaloom-knowledge/scripts/test_xmage_to_manaloom_effect_hints.py docs/hermes-analysis/manaloom-knowledge/scripts/test_xmage_semantic_family_batch_pipeline.py`
  passed.
- `PYTHONPATH=docs/hermes-analysis/manaloom-knowledge/scripts python3 -m unittest docs.hermes-analysis.manaloom-knowledge.scripts.test_xmage_to_manaloom_effect_hints docs.hermes-analysis.manaloom-knowledge.scripts.test_xmage_semantic_family_batch_pipeline`
  passed, `115 tests`.

## Replay-Batch Evidence

Seed pipeline before PG136 apply:

- `docs/hermes-analysis/master_optimizer_reports/xmage_current_replay_batch_pipeline_20260624_pg136_seed_v2_manifest.json`
- `family_counts={"draw_engine":1,"manual_model":249,"passive":1,"token_maker":25}`
- `proposal_status_counts={"batch_pg_candidate_after_precheck":2,"blocked_missing_xmage_source":4,"mapper_metadata_or_test_scenario_required":245,"runtime_family_implementation_required":25}`

Post-sync pipeline:

- `docs/hermes-analysis/master_optimizer_reports/xmage_current_replay_batch_pipeline_20260624_pg136_postsync_real_manifest.json`
- `severity_counts={"critical":1,"high":237,"medium":36,"pass":267}`
- `validity_status_counts={"blocked_missing_xmage_class":4,"ready_for_structured_xmage_pull_review_required":25,"xmage_source_valid_mapper_required":245}`
- `family_counts={"manual_model":249,"token_maker":25}`
- `proposal_status_counts={"blocked_missing_xmage_source":4,"mapper_metadata_or_test_scenario_required":245,"runtime_family_implementation_required":25}`

Observed delta versus PG135 post-sync:

- `pass`: `265 -> 267`
- `high`: `239 -> 237`
- `ready_for_structured_xmage_pull_review_required`: `27 -> 25`
- `split_family_scope_review_required`: `2 -> 0`
- `batch_pg_candidate_after_precheck`: `2 -> 0`

## Current Reading

- PG136 eliminated the last two cards in the current replay surface that still
  had exact local XMage source but lacked promoted ManaLoom scope.
- After PG136, the real `Lorehold + oponentes usados` surface has no remaining
  local-XMage residual. What remains is only:
  - `blocked_missing_xmage_source=4`
  - `mapper_metadata_or_test_scenario_required=245`
  - `runtime_family_implementation_required=25`

## Rollback

- Rollback SQL exists at
  `docs/hermes-analysis/master_optimizer_reports/pg136_current_replay_exact_scope_batch_three_rollback.sql`.
- Rollback was not executed because precheck, apply, postcheck, SQLite sync,
  focused tests, and post-sync replay-batch validation all passed.
