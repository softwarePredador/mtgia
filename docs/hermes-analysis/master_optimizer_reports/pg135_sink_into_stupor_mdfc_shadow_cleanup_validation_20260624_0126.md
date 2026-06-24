# PG135 Sink into Stupor MDFC Shadow Cleanup Validation - 2026-06-24 01:26 UTC

## Scope

- Remove the remaining MDFC shadow rows left behind for `Sink into Stupor`
  after the PG134 promotion.
- Re-sync the corrected rule set into Hermes SQLite/cache.
- Re-run the replay batch so the last false-positive local-XMage residual is
  not carried forward.

## PostgreSQL Evidence

Package files:

- `docs/hermes-analysis/master_optimizer_reports/pg135_sink_into_stupor_mdfc_shadow_cleanup_precheck.sql`
- `docs/hermes-analysis/master_optimizer_reports/pg135_sink_into_stupor_mdfc_shadow_cleanup_apply.sql`
- `docs/hermes-analysis/master_optimizer_reports/pg135_sink_into_stupor_mdfc_shadow_cleanup_postcheck.sql`
- `docs/hermes-analysis/master_optimizer_reports/pg135_sink_into_stupor_mdfc_shadow_cleanup_rollback.sql`

Precheck result:

- `Sink into Stupor`: `target_card_rows=1`, `existing_rule_rows=4`,
  `expected_rule_rows_before=1`, `would_deprecate_shadow_rows=2`

Apply result:

- `deprecated_shadow_rows=3`
- `upserted_rows=1`

Postcheck result:

- `promoted_rule_rows=1`
- `promoted_verified_auto_rows=1`
- `promoted_oracle_hash_rows=1`
- backup table retained `4` captured rows

## SQLite/Hermes Sync

Command:

```bash
python3 docs/hermes-analysis/manaloom-knowledge/scripts/sync_battle_card_rules_pg.py --apply-sqlite-from-pg --include-needs-review --only-card "Sink into Stupor" --report docs/hermes-analysis/master_optimizer_reports/battle_card_rules_sqlite_from_pg_pg135_sink_into_stupor_mdfc_shadow_cleanup_20260624_0126.json
```

Sync result:

- `selected_card_count=1`
- `pg_rows_loaded=4`
- `sqlite_inserted_or_updated=5`
- `generated_rows=1`
- `oracle_normalized_rows=1`
- `canonical_snapshot_rows_exported=3211`

## Test Evidence

- `PYTHONPATH=docs/hermes-analysis/manaloom-knowledge/scripts python3 -m unittest docs.hermes-analysis.manaloom-knowledge.scripts.test_sync_battle_card_rules_pg_selection docs.hermes-analysis.manaloom-knowledge.scripts.test_runtime_pg_rule_fallback_for_promoted_hotfixes`
  passed, `16 tests`.
- `PYTHONPATH=docs/hermes-analysis/manaloom-knowledge/scripts python3 -m unittest docs.hermes-analysis.manaloom-knowledge.scripts.test_deck_card_battle_rule_coherence_audit docs.hermes-analysis.manaloom-knowledge.scripts.test_runtime_pg_rule_fallback_for_promoted_hotfixes`
  passed, `12 tests`.

## Replay-Batch Evidence

Post-sync pipeline:

- `docs/hermes-analysis/master_optimizer_reports/xmage_current_replay_batch_pipeline_20260624_pg135_postsync_real_v2_manifest.json`
- `severity_counts={"critical":1,"high":239,"medium":36,"pass":265}`
- `validity_status_counts={"blocked_missing_xmage_class":4,"ready_for_structured_xmage_pull_review_required":27,"xmage_source_valid_mapper_required":245}`
- `proposal_status_counts={"blocked_missing_xmage_source":4,"mapper_metadata_or_test_scenario_required":245,"runtime_family_implementation_required":25,"split_family_scope_review_required":2}`

Residual local-XMage split-family cards after PG135:

- `Agatha's Soul Cauldron`
- `Necropotence`

## Current Reading

- PG135 closed the MDFC alias cleanup lane introduced by `Sink into Stupor`.
- After this point, the real local-XMage replay surface was reduced to exactly
  two non-generic cards: `Agatha's Soul Cauldron` and `Necropotence`.

## Rollback

- Rollback SQL exists at
  `docs/hermes-analysis/master_optimizer_reports/pg135_sink_into_stupor_mdfc_shadow_cleanup_rollback.sql`.
- Rollback was not executed because precheck, apply, postcheck, SQLite sync,
  focused tests, and replay-batch revalidation all passed.
