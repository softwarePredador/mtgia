# PG242 Magmakin Artillerist Discard Damage Progress

## Scope

- target card: `Magmakin Artillerist`
- target family: `creature`
- PostgreSQL writes: `true`
- SQLite/Hermes sync: `true`
- git commit/push: `pending`

## Code Changes

- `docs/hermes-analysis/manaloom-knowledge/scripts/xmage_to_manaloom_effect_hints.py`
  - exact XMage mapper for `Magmakin Artillerist`
  - emitted scope:
    `controller_discards_one_or_more_damage_each_opponent_cycling_ping_annotation_v1`
- `docs/hermes-analysis/manaloom-knowledge/scripts/xmage_semantic_family_classifier.py`
  - exact-scope batch-safe validation for the Magmakin discard-damage shape
- `docs/hermes-analysis/manaloom-knowledge/scripts/test_xmage_to_manaloom_effect_hints.py`
  - added exact mapper test for `Magmakin Artillerist`
- `docs/hermes-analysis/manaloom-knowledge/scripts/test_xmage_semantic_family_batch_pipeline.py`
  - added batch-safe classifier test for `Magmakin Artillerist`
- `docs/hermes-analysis/manaloom-knowledge/scripts/battle_card_specific_tests.py`
  - added runtime test:
    `test_pg242_magmakin_artillerist_discard_count_hits_each_opponent`

## Test Evidence

- `python3 -m unittest test_xmage_to_manaloom_effect_hints.py`
  - `236` tests passed
- `python3 -m unittest test_xmage_semantic_family_batch_pipeline.py`
  - `221` tests passed
- focused runtime invocation through `register_tests(...)`
  - `magmakin_battle_test=ok`

## Presync Evidence

- pipeline prefix:
  `xmage_current_replay_batch_pipeline_20260626_pg242_magmakin_presync_v1`
- key deltas versus the prior postsync state:
  - `family_counts.creature: 3 -> 4`
  - `manual_model: 319 -> 318`
  - `proposal_status_counts.batch_pg_candidate_after_precheck: 0 -> 1`
- `Magmakin Artillerist` row before PG apply:
  - `family_id=creature`
  - `proposal_status=batch_pg_candidate_after_precheck`
  - `promotion_lane=batch_metadata_candidate_requires_pg_precheck`
  - `rule_status=package_ready`
  - `recommendation_lane=watchlist_candidate`
  - `score=33.5`
  - `deck_ids=[608, 617]`
- presync effective queue:
  - `package_ready_unprepared=1`
  - `manual_mapper_backlog=315`
  - `split_scope_backlog=59`
  - `runtime_family_backlog=4`
- presync strategy audit:
  - `17/18 pass`
  - only failing check:
    `effective_queue.package_ready_unprepared=1`

## PostgreSQL Package Evidence

- package:
  `docs/hermes-analysis/master_optimizer_reports/pg242_magmakin_discard_damage_package.md`
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

## SQLite Sync Evidence

- sync report:
  `docs/hermes-analysis/master_optimizer_reports/battle_card_rules_sqlite_from_pg_pg242_magmakin_discard_damage_20260626.json`
- result:
  - `pg_rows_loaded=1`
  - `sqlite_inserted_or_updated=3`
  - `selected_cards=["Magmakin Artillerist"]`

## Runtime Proof With Real Card Name

Using `battle.get_card_effect({'name':'Magmakin Artillerist', ...})` after
PG -> SQLite sync:

- `effect=creature`
- `battle_model_scope=controller_discards_one_or_more_damage_each_opponent_cycling_ping_annotation_v1`
- `review_status=verified`
- `execution_status=auto`
- `logical_rule_key=battle_rule_v1:4e07d6def685d15fad06df5be83b24d2`
- `oracle_hash=a0cad890cfcb5b3938c3d58a32687167`

Focused discard runtime proof:

- discarded cards: `2`
- `opponent_a_life_after=38`
- `opponent_b_life_after=38`

This proves the real DB-backed rule loads by name and the existing
controller-discard trigger runtime now executes the promoted Magmakin scope.

## Postsync Evidence

- pipeline prefix:
  `xmage_current_replay_batch_pipeline_20260626_pg242_magmakin_postsync_v1`
- effective queue:
  - `package_ready_unprepared=0`
  - `manual_mapper_backlog=315`
  - `split_scope_backlog=59`
  - `runtime_family_backlog=4`
- strategy audit:
  - `18/18 pass`
- scoped matrix:
  - `battle_ready=527`
  - `needs_rule_before_strategy=182`
  - `watchlist_candidate=226`
- Lorehold-touching subset:
  - `battle_ready: 328 -> 329`
  - `mapper_manual: 59 -> 58`
  - `needs_rule_before_strategy: 67 -> 66`

## Operational Conclusion

- `Magmakin Artillerist` is no longer in the Lorehold
  `needs_rule_before_strategy` backlog.
- The discard-damage creature lane now has an exact XMage-backed shape for
  future cards that use the same `controller_discard_damage_each_opponent`
  runtime.
- The next highest-ROI Lorehold targets are now:
  `Currency Converter`, `Firesong and Sunspeaker`, `Radiant Scrollwielder`,
  `Deathbellow War Cry`, and `Millikin`.
