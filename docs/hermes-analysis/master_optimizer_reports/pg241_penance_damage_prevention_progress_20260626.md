# PG241 Penance Damage Prevention Progress

## Scope

- target card: `Penance`
- target family: `damage_prevention_shield`
- PostgreSQL writes: `true`
- SQLite/Hermes sync: `true`
- git commit/push: `pending`

## Code Changes

- `docs/hermes-analysis/manaloom-knowledge/scripts/xmage_to_manaloom_effect_hints.py`
  - exact XMage mapper for `Penance`
  - emitted scope:
    `activated_put_card_from_hand_on_top_library_prevent_next_damage_from_chosen_black_or_red_source_to_you_v1`
- `docs/hermes-analysis/manaloom-knowledge/scripts/xmage_semantic_family_classifier.py`
  - new supported family:
    `damage_prevention_shield`
  - exact-scope batch-safe validation for the Penance shape
- `docs/hermes-analysis/manaloom-knowledge/scripts/battle_analyst_v9.py`
  - combat defensive response window now scans battlefield permanents for
    activated chosen-source prevention shields
  - new black/red source filter for response selection
  - activated response pays the real ManaLoom cost model here by putting a hand
    card on top of the library, then creates a one-shot chosen-source shield
  - resolved spell/permanent path now supports `damage_prevention_shield`
- `docs/hermes-analysis/manaloom-knowledge/scripts/test_xmage_to_manaloom_effect_hints.py`
  - added exact mapper test for `Penance`
- `docs/hermes-analysis/manaloom-knowledge/scripts/test_xmage_semantic_family_batch_pipeline.py`
  - added batch-safe classifier test for `Penance`
- `docs/hermes-analysis/manaloom-knowledge/scripts/battle_card_specific_tests.py`
  - added runtime tests:
    - `test_pg241_penance_activates_in_combat_window_and_prevents_matching_damage`
    - `test_pg241_penance_skips_non_black_red_source`

## Test Evidence

- `python3 -m unittest test_xmage_to_manaloom_effect_hints.py`
  - `235` tests passed
- `python3 -m unittest test_xmage_semantic_family_batch_pipeline.py`
  - `220` tests passed
- focused runtime invocation through `register_tests(...)`
  - `penance_battle_tests=ok`

## Presync Evidence

- pipeline prefix:
  `xmage_current_replay_batch_pipeline_20260626_pg241_penance_presync_v1`
- key deltas:
  - `family_counts.damage_prevention_shield: 1`
  - `proposal_status_counts.batch_pg_candidate_after_precheck: 1`
- `Penance` row before PG apply:
  - `family_id=damage_prevention_shield`
  - `proposal_status=batch_pg_candidate_after_precheck`
  - `promotion_lane=batch_metadata_candidate_requires_pg_precheck`
  - `rule_status=package_ready`
  - `recommendation_lane=watchlist_candidate`
  - `score=33.0`

## PostgreSQL Package Evidence

- package:
  `docs/hermes-analysis/master_optimizer_reports/pg241_penance_damage_prevention_package.md`
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
  `docs/hermes-analysis/master_optimizer_reports/battle_card_rules_sqlite_from_pg_pg241_penance_damage_prevention_20260626.json`
- result:
  - `pg_rows_loaded=1`
  - `sqlite_inserted_or_updated=3`
  - `selected_cards=["Penance"]`

## Runtime Proof With Real Card Name

Using `battle.get_card_effect({'name':'Penance', ...})` after PG -> SQLite sync:

- `effect=damage_prevention_shield`
- `battle_model_scope=activated_put_card_from_hand_on_top_library_prevent_next_damage_from_chosen_black_or_red_source_to_you_v1`
- `review_status=verified`
- `execution_status=auto`
- `logical_rule_key=battle_rule_v1:7b7befc4b77b04202df8c2966004c8e6`
- `oracle_hash=fbe58d392a998f29895af142fa09e6d6`

Focused combat runtime proof:

- `responded=true`
- `damage_dealt=false`
- `life_after=4`
- `top_library=Slow Haymaker`
- `hand_size_after=0`

This proves the activated permanent response consumed a hand card, topdecked it,
selected the matching black source, and prevented the damage.

## Postsync Evidence

- pipeline prefix:
  `xmage_current_replay_batch_pipeline_20260626_pg241_penance_postsync_v1`
- effective queue:
  - `package_ready_unprepared=0`
  - `manual_mapper_backlog=316`
  - `split_scope_backlog=59`
  - `runtime_family_backlog=4`
- strategy audit:
  - `18/18 pass`
- matrix:
  - `battle_ready=724`
  - `needs_rule_before_strategy=240`
  - `watchlist_candidate=324`
- Lorehold-focused matrix:
  - `rule_status_counts.battle_ready=328`
  - `needs_rule_before_strategy=67`

## Operational Conclusion

- `Penance` is no longer in the Lorehold `needs_rule_before_strategy` backlog.
- The new family `damage_prevention_shield` is now available for future exact
  XMage pulls with the same activated chosen-source prevention shape.
- The next highest-ROI Lorehold targets are now:
  `Currency Converter`, `Firesong and Sunspeaker`, `Radiant Scrollwielder`,
  `Deathbellow War Cry`, and `Magmakin Artillerist`.
