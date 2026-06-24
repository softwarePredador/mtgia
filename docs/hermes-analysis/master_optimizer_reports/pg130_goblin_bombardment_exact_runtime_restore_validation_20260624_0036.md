# PG130 Goblin Bombardment Exact Runtime Restore Validation - 2026-06-24 00:36 UTC

## Scope

- Promote `Goblin Bombardment` from the remaining batch-safe queue into an
  exact XMage-backed runtime scope.
- Deprecate the prior broad shadow rows.
- Sync the exact rule into Hermes SQLite/cache.
- Re-measure the replay-batch residual after the final easy local-XMage card.

## PostgreSQL Evidence

Package files:

- `docs/hermes-analysis/master_optimizer_reports/pg130_goblin_bombardment_exact_runtime_restore_precheck.sql`
- `docs/hermes-analysis/master_optimizer_reports/pg130_goblin_bombardment_exact_runtime_restore_apply.sql`
- `docs/hermes-analysis/master_optimizer_reports/pg130_goblin_bombardment_exact_runtime_restore_postcheck.sql`
- `docs/hermes-analysis/master_optimizer_reports/pg130_goblin_bombardment_exact_runtime_restore_rollback.sql`

Precheck result:

- `Goblin Bombardment`: `existing_rule_rows=3`,
  `would_deprecate_shadow_rows=3`

Apply result:

- backup snapshot rows captured: `3`
- `deprecated_shadow_rows=3`
- `upserted_rows=1`

Postcheck result:

- `promoted_rule_rows=1`
- `promoted_verified_auto_rows=1`
- `promoted_oracle_hash_rows=1`
- backup table retained `3` captured rows

Promoted scope:

- `Goblin Bombardment` ->
  `activated_sacrifice_creature_deal_one_any_target_v1`

## SQLite/Hermes Sync

Command:

```bash
python3 docs/hermes-analysis/manaloom-knowledge/scripts/sync_battle_card_rules_pg.py --apply-sqlite-from-pg --include-needs-review --only-card "Goblin Bombardment" --report docs/hermes-analysis/master_optimizer_reports/battle_card_rules_sqlite_from_pg_pg130_goblin_bombardment_20260624_0036.json
```

Sync result:

- `selected_card_count=1`
- `pg_rows_loaded=4`
- `sqlite_inserted_or_updated=4`
- `generated_rows=1`
- `canonical_snapshot_rows_exported=3209`

## Test Evidence

- `PYTHONPATH=docs/hermes-analysis/manaloom-knowledge/scripts python3 -m unittest docs.hermes-analysis.manaloom-knowledge.scripts.test_battle_forensic_audit_supported_effects docs.hermes-analysis.manaloom-knowledge.scripts.test_runtime_pg_rule_fallback_for_promoted_hotfixes`
  passed, `3 tests`.

## Replay-Batch Evidence

Post-sync pipeline:

- `docs/hermes-analysis/master_optimizer_reports/xmage_current_replay_batch_pipeline_20260624_pg130_postsync_real_manifest.json`
- `severity_counts={"critical":1,"high":251,"medium":43,"pass":246}`
- `validity_status_counts={"blocked_missing_xmage_class":4,"ready_for_structured_xmage_pull_review_required":44,"xmage_source_valid_mapper_required":247}`
- `proposal_status_counts={"blocked_missing_xmage_source":4,"mapper_metadata_or_test_scenario_required":247,"runtime_family_implementation_required":25,"split_family_scope_review_required":19}`

Observed delta versus PG129 post-sync:

- `pass`: `245 -> 246`
- `high`: `252 -> 251`
- `ready_for_structured_xmage_pull_review_required`: `45 -> 44`
- `batch_pg_candidate_after_precheck`: `1 -> 0`

## Current Reading

- PG130 is closed as applied, postchecked, synced, and validated.
- The easy local-XMage batch-safe queue is now empty.
- What remains is the real residual:
  local-XMage cards that still need additional exact modeling and the separate
  `blocked_missing_xmage_source` subset.

## Rollback

- Rollback SQL exists at
  `docs/hermes-analysis/master_optimizer_reports/pg130_goblin_bombardment_exact_runtime_restore_rollback.sql`
  and restores the captured rows from
  `manaloom_deploy_audit.pg130_goblin_bombardment_exact_runtime_restore_20260624_003605`.
- Rollback was not executed because precheck, apply, postcheck, SQLite sync,
  tests, and post-sync replay-batch validation all passed.
