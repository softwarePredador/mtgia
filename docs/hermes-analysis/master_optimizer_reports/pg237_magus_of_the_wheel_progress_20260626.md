# PG237 Magus of the Wheel Progress 2026-06-26

- slice: `Magus of the Wheel`
- deploy_id: `PG237`
- scope: close one Lorehold-facing `needs_rule_before_strategy` creature family with local XMage source, runtime support, PostgreSQL promotion, Hermes sync, and post-sync audit evidence

## What Changed

- Added exact XMage -> ManaLoom mapping for `MagusOfTheWheel` in
  `xmage_to_manaloom_effect_hints.py`.
- Added exact-scope batch-safe classifier support for
  `activated_tap_sacrifice_self_each_player_discards_hand_draws_seven_v1`.
- Extended `battle_analyst_v9.py` runtime to support a precombat battlefield
  creature activation that:
  - pays `{1}{R}`
  - taps and sacrifices the source
  - resolves multiplayer discard-hand / draw-seven using existing wheel runtime
  - emits decision trace and replay evidence
- Added tests for mapper, classifier, and activated battlefield runtime.

## Validation

- `python3 -m unittest test_xmage_to_manaloom_effect_hints.py` -> `230/230 OK`
- `python3 -m unittest test_xmage_semantic_family_batch_pipeline.py` -> `215/215 OK`
- targeted runtime test passed:
  - `test_magus_of_the_wheel_activates_from_battlefield_and_refills_each_player`

## Pipeline Delta

Pre-apply artifacts:

- proposals:
  `xmage_current_replay_batch_pipeline_20260626_pg237_magus_runtime_v3_proposals.json`
- matrix:
  `lorehold_ideal_candidate_matrix_20260626_pg237_magus_runtime_v3.json`
- effective queue:
  `xmage_effective_queue_20260626_pg237_magus_runtime_v3.json`

Observed pre-apply state:

- `Magus of the Wheel` promoted to:
  - `effect=creature`
  - `battle_model_scope=activated_tap_sacrifice_self_each_player_discards_hand_draws_seven_v1`
  - `proposal_status=batch_pg_candidate_after_precheck`
  - `safe_for_batch_pg_package=true`
- effective queue delta:
  - `package_ready_unprepared: 1`
- matrix delta:
  - `rule_status_counts.package_ready: 1`
  - `recommendation_lane.watchlist_candidate -> pending post-sync`

Post-apply artifacts:

- proposals:
  `xmage_current_replay_batch_pipeline_20260626_pg237_magus_postsync_v1_proposals.json`
- matrix:
  `lorehold_ideal_candidate_matrix_20260626_pg237_magus_postsync_v1.json`
- effective queue:
  `xmage_effective_queue_20260626_pg237_magus_postsync_v1.json`
- strategy audit:
  `xmage_strategy_consistency_audit_20260626_pg237_magus_postsync_v1.json`

Observed post-apply state:

- effective queue delta:
  - `package_ready_unprepared: 0`
- matrix delta:
  - `battle_ready: 370 -> 371`
  - `priority_benchmark_candidate: 193 -> 194`
  - `watchlist_candidate: 164 -> 163`
- `Magus of the Wheel` moved to:
  - `rule_status=battle_ready`
  - `recommendation_lane=priority_benchmark_candidate`
  - `score=46.5`
- strategy audit:
  - `18/18 pass`

## PostgreSQL / Sync Evidence

- package manifest:
  `pg237_magus_of_the_wheel_exact_scope_manifest.json`
- precheck:
  - `target_card_rows=1`
  - `existing_rule_rows=2`
  - `expected_rule_rows_before=0`
  - `would_deprecate_shadow_rows=2`
- apply:
  - `deprecated_shadow_rows=2`
  - `upserted_rows=1`
- postcheck:
  - `promoted_rule_rows=1`
  - `promoted_verified_auto_rows=1`
  - `promoted_oracle_hash_rows=1`
  - `backup_rows=2`
- SQLite sync report:
  `battle_card_rules_sqlite_from_pg_pg237_magus_of_the_wheel_20260626.json`
  - `pg_rows_loaded=1`
  - `sqlite_inserted_or_updated=3`

## Recommendation For Next Step

`Magus of the Wheel` no longer belongs to `needs_rule_before_strategy`.
Operationally, the next action is to benchmark the new
`priority_benchmark_candidate` row under the Lorehold baseline/hash guard and
slot optimizer path, while the rule-closing lane continues on the remaining
manual and split-scope backlog.
