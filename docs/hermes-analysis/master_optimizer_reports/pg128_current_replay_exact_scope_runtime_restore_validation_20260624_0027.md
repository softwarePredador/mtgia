# PG128 Current Replay Exact Scope Runtime Restore Validation - 2026-06-24 00:27 UTC

## Scope

- Promote exact XMage-backed scopes for cards already exposed in the current
  replay/audit surface:
  - `Borne Upon a Wind`
  - `Red Elemental Blast`
  - `Consecrated Sphinx`
  - `Cyclonic Rift`
  - `Soul-Guide Lantern`
- Deprecate the broader shadow rules those cards were still resolving through.
- Sync the exact rules into local Hermes SQLite/cache.
- Re-measure the replay-batch residual on the same Lorehold + opponent deck set.

## PostgreSQL Evidence

Package files:

- `docs/hermes-analysis/master_optimizer_reports/pg128_current_replay_exact_scope_runtime_restore_precheck.sql`
- `docs/hermes-analysis/master_optimizer_reports/pg128_current_replay_exact_scope_runtime_restore_apply.sql`
- `docs/hermes-analysis/master_optimizer_reports/pg128_current_replay_exact_scope_runtime_restore_postcheck.sql`
- `docs/hermes-analysis/master_optimizer_reports/pg128_current_replay_exact_scope_runtime_restore_rollback.sql`

Precheck result:

- all 5 cards had `target_card_rows >= 1`
- all 5 cards had `expected_rule_rows_before=0`
- active broad rows existed already and would be deprecated:
  - `Borne Upon a Wind`: `existing_rule_rows=2`,
    `would_deprecate_shadow_rows=2`
  - `Consecrated Sphinx`: `existing_rule_rows=2`,
    `would_deprecate_shadow_rows=2`
  - `Cyclonic Rift`: `existing_rule_rows=2`,
    `would_deprecate_shadow_rows=2`
  - `Red Elemental Blast`: `existing_rule_rows=2`,
    `would_deprecate_shadow_rows=2`
  - `Soul-Guide Lantern`: `existing_rule_rows=3`,
    `would_deprecate_shadow_rows=3`

Apply result:

- backup snapshot rows captured: `11`
- `deprecated_shadow_rows=11`
- `upserted_rows=5`
- transaction committed successfully

Postcheck result:

- all five cards have `promoted_rule_rows=1`
- all five cards have `promoted_verified_auto_rows=1`
- all five cards have `promoted_oracle_hash_rows=1`
- backup table retained `11` captured rows

Promoted scopes:

- `Borne Upon a Wind` ->
  `draw_one_and_source_controller_spells_gain_flash_until_eot_v1`
- `Red Elemental Blast` ->
  `counter_target_blue_spell_or_destroy_target_blue_permanent_v1`
- `Consecrated Sphinx` ->
  `flying_may_draw_two_when_opponent_draws_card_v1`
- `Cyclonic Rift` ->
  `return_target_nonland_permanent_you_dont_control_or_overload_all_opponents_nonlands_v1`
- `Soul-Guide Lantern` ->
  `etb_exile_graveyard_card_or_sacrifice_for_mass_graveyard_exile_or_draw_v1`

## Replay Surface Proof

These cards were selected because they are on the current replay/audit surface,
not only because they exist in audited decks:

- `Borne Upon a Wind` appears in current replay events as a resolved end-step
  instant in `seed_63241258` and `seed_63241253`, and is flagged in current
  `effect_coverage.json` with `cast_permission_not_explicit`.
- `Red Elemental Blast` appears in current replay coverage and residual files,
  and is flagged with `oracle_target_removal_mismatch`.
- `Consecrated Sphinx` appears in current `effect_coverage.json` and is flagged
  with `trigger_not_explicit`.
- `Cyclonic Rift` appears in current replay coverage/residual files and is
  flagged with `cast_permission_not_explicit`.
- `Soul-Guide Lantern` appears in current replay events in `seed_63241256` and
  is flagged with `oracle_target_removal_mismatch`.

## SQLite/Hermes Sync

Command:

```bash
python3 docs/hermes-analysis/manaloom-knowledge/scripts/sync_battle_card_rules_pg.py --apply-sqlite-from-pg --include-needs-review --only-card "Borne Upon a Wind" --only-card "Red Elemental Blast" --only-card "Consecrated Sphinx" --only-card "Cyclonic Rift" --only-card "Soul-Guide Lantern" --report docs/hermes-analysis/master_optimizer_reports/battle_card_rules_sqlite_from_pg_pg128_current_replay_exact_scope_20260624_0027.json
```

Sync result:

- `selected_card_count=5`
- `pg_rows_loaded=16`
- `sqlite_inserted_or_updated=15`
- `generated_rows=5`
- `curated_rows=1`
- `canonical_snapshot_rows_exported=3209`

## Test Evidence

- `python3 -m py_compile docs/hermes-analysis/manaloom-knowledge/scripts/xmage_to_manaloom_effect_hints.py docs/hermes-analysis/manaloom-knowledge/scripts/xmage_semantic_family_classifier.py docs/hermes-analysis/manaloom-knowledge/scripts/test_xmage_to_manaloom_effect_hints.py docs/hermes-analysis/manaloom-knowledge/scripts/test_xmage_semantic_family_batch_pipeline.py`
  passed.
- `PYTHONPATH=docs/hermes-analysis/manaloom-knowledge/scripts python3 -m unittest docs.hermes-analysis.manaloom-knowledge.scripts.test_xmage_to_manaloom_effect_hints docs.hermes-analysis.manaloom-knowledge.scripts.test_xmage_semantic_family_batch_pipeline`
  passed, `70 tests`.
- `PYTHONPATH=docs/hermes-analysis/manaloom-knowledge/scripts python3 -m unittest docs.hermes-analysis.manaloom-knowledge.scripts.test_battle_forensic_audit_supported_effects docs.hermes-analysis.manaloom-knowledge.scripts.test_runtime_pg_rule_fallback_for_promoted_hotfixes`
  passed, `3 tests`.

## Replay-Batch Evidence

Seed pipeline before PG128 apply:

- `docs/hermes-analysis/master_optimizer_reports/xmage_current_replay_batch_pipeline_20260624_pg128_seed_v2_manifest.json`
- `proposal_status_counts={"batch_pg_candidate_after_precheck":6,"blocked_missing_xmage_source":4,"mapper_metadata_or_test_scenario_required":247,"runtime_family_implementation_required":25,"split_family_scope_review_required":22}`

Post-sync pipeline:

- `docs/hermes-analysis/master_optimizer_reports/xmage_current_replay_batch_pipeline_20260624_pg128_postsync_real_manifest.json`
- `severity_counts={"critical":1,"high":255,"medium":43,"pass":242}`
- `validity_status_counts={"blocked_missing_xmage_class":4,"ready_for_structured_xmage_pull_review_required":48,"xmage_source_valid_mapper_required":247}`
- `proposal_status_counts={"batch_pg_candidate_after_precheck":1,"blocked_missing_xmage_source":4,"mapper_metadata_or_test_scenario_required":247,"runtime_family_implementation_required":25,"split_family_scope_review_required":22}`

Observed delta versus the PG127 post-sync baseline:

- `pass`: `237 -> 242`
- `high`: `260 -> 255`
- `ready_for_structured_xmage_pull_review_required`: `53 -> 48`

Observed delta inside the PG128 seed candidate set:

- `batch_pg_candidate_after_precheck`: `6 -> 1`
- the single remaining batch-safe card is:
  `Goblin Bombardment` under
  `activated_sacrifice_creature_deal_one_any_target_v1`
  and it was intentionally left out of PG128 because it did not appear in the
  current `latest` replay surface used for prioritization.

## Current Reading

- PG128 is closed as applied, postchecked, synced to Hermes, and validated by
  tests plus replay-batch residual movement.
- The executed-current-surface subset shrank by five exact cards.
- The next priority remains the same shape:
  finish the remaining replay-surface exact cases with XMage local source, then
  leave only the true residual:
  no-local-XMage or manual-model families.

## Rollback

- Rollback SQL exists at
  `docs/hermes-analysis/master_optimizer_reports/pg128_current_replay_exact_scope_runtime_restore_rollback.sql`
  and restores the captured rows from
  `manaloom_deploy_audit.pg128_current_replay_exact_scope_runtime_restore_2026062`.
- Rollback was not executed because precheck, apply, postcheck, SQLite sync,
  tests, and post-sync replay-batch validation all passed.
