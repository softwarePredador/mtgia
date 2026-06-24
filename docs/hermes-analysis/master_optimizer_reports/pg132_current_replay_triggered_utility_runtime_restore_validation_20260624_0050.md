# PG132 Current Replay Triggered Utility Runtime Restore Validation - 2026-06-24 00:50 UTC

## Scope

- Promote exact XMage-backed scopes for two cards still exposed in the current
  replay surface:
  - `Orcish Bowmasters`
  - `Deathrite Shaman`
- Deprecate the broad shadow rules these cards still resolved through.
- Sync the exact rules into Hermes SQLite/cache.
- Re-measure the replay-batch residual after the promotion.

## PostgreSQL Evidence

Package files:

- `docs/hermes-analysis/master_optimizer_reports/pg132_current_replay_triggered_utility_runtime_restore_precheck.sql`
- `docs/hermes-analysis/master_optimizer_reports/pg132_current_replay_triggered_utility_runtime_restore_apply.sql`
- `docs/hermes-analysis/master_optimizer_reports/pg132_current_replay_triggered_utility_runtime_restore_postcheck.sql`
- `docs/hermes-analysis/master_optimizer_reports/pg132_current_replay_triggered_utility_runtime_restore_rollback.sql`

Precheck result:

- `Deathrite Shaman`: `existing_rule_rows=2`,
  `would_deprecate_shadow_rows=2`
- `Orcish Bowmasters`: `existing_rule_rows=2`,
  `would_deprecate_shadow_rows=2`

Apply result:

- backup snapshot rows captured: `4`
- `deprecated_shadow_rows=4`
- `upserted_rows=2`

Postcheck result:

- both cards have `promoted_rule_rows=1`
- both cards have `promoted_verified_auto_rows=1`
- both cards have `promoted_oracle_hash_rows=1`
- backup table retained `4` captured rows

Promoted scopes:

- `Orcish Bowmasters` ->
  `flash_etb_or_opponent_extra_draw_damage_any_target_amass_orcs_v1`
- `Deathrite Shaman` ->
  `graveyard_exile_mana_or_life_shaman_v1`

## SQLite/Hermes Sync

Command:

```bash
python3 docs/hermes-analysis/manaloom-knowledge/scripts/sync_battle_card_rules_pg.py --apply-sqlite-from-pg --include-needs-review --only-card "Orcish Bowmasters" --only-card "Deathrite Shaman" --report docs/hermes-analysis/master_optimizer_reports/battle_card_rules_sqlite_from_pg_pg132_current_replay_triggered_utility_20260624_0050.json
```

Sync result:

- `selected_card_count=2`
- `pg_rows_loaded=6`
- `sqlite_inserted_or_updated=6`
- `generated_rows=2`
- `canonical_snapshot_rows_exported=3209`

## Test Evidence

- `python3 -m py_compile ...xmage_to_manaloom_effect_hints.py ...xmage_semantic_family_classifier.py ...test_xmage_to_manaloom_effect_hints.py ...test_xmage_semantic_family_batch_pipeline.py`
  passed.
- `PYTHONPATH=docs/hermes-analysis/manaloom-knowledge/scripts python3 -m unittest docs.hermes-analysis.manaloom-knowledge.scripts.test_xmage_to_manaloom_effect_hints docs.hermes-analysis.manaloom-knowledge.scripts.test_xmage_semantic_family_batch_pipeline`
  passed, `86 tests`.
- `PYTHONPATH=docs/hermes-analysis/manaloom-knowledge/scripts python3 -m unittest docs.hermes-analysis.manaloom-knowledge.scripts.test_battle_forensic_audit_supported_effects docs.hermes-analysis.manaloom-knowledge.scripts.test_runtime_pg_rule_fallback_for_promoted_hotfixes`
  passed, `3 tests`.

## Replay-Batch Evidence

Seed pipeline before PG132 apply:

- `docs/hermes-analysis/master_optimizer_reports/xmage_current_replay_batch_pipeline_20260624_pg132_seed_manifest.json`
- `proposal_status_counts={"batch_pg_candidate_after_precheck":2,"blocked_missing_xmage_source":4,"mapper_metadata_or_test_scenario_required":247,"runtime_family_implementation_required":25,"split_family_scope_review_required":14}`

Post-sync pipeline:

- `docs/hermes-analysis/master_optimizer_reports/xmage_current_replay_batch_pipeline_20260624_pg132_postsync_real_manifest.json`
- `severity_counts={"critical":1,"high":246,"medium":43,"pass":251}`
- `validity_status_counts={"blocked_missing_xmage_class":4,"ready_for_structured_xmage_pull_review_required":39,"xmage_source_valid_mapper_required":247}`
- `proposal_status_counts={"blocked_missing_xmage_source":4,"mapper_metadata_or_test_scenario_required":247,"runtime_family_implementation_required":25,"split_family_scope_review_required":14}`

Observed delta versus PG131 post-sync:

- `pass`: `249 -> 251`
- `high`: `248 -> 246`
- `ready_for_structured_xmage_pull_review_required`: `41 -> 39`

## Current Reading

- PG132 is closed as applied, postchecked, synced, and validated.
- The directly executed replay-surface cases with straightforward XMage local
  semantics are now further reduced.
- The next residual local-XMage case exposed in the current replay surface is
  the heavier artifact/static case `Agatha's Soul Cauldron`; the remaining
  queue is otherwise concentrated in harder split-family or non-current-surface
  local-XMage work plus the no-XMage subset.

## Rollback

- Rollback SQL exists at
  `docs/hermes-analysis/master_optimizer_reports/pg132_current_replay_triggered_utility_runtime_restore_rollback.sql`
  and restores the captured rows from
  `manaloom_deploy_audit.pg132_current_replay_triggered_utility_runtime_restore_20260624_005007`.
- Rollback was not executed because precheck, apply, postcheck, SQLite sync,
  tests, and post-sync replay-batch validation all passed.
