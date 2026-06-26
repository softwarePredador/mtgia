# Scholar of New Horizons Lorehold Progress 2026-06-26

## Scope

- target card: `Scholar of New Horizons`
- objective slice: move one Lorehold-facing `needs_rule_before_strategy` / `mapper_manual` card into a verified XMage -> ManaLoom package-ready lane with runtime coverage and fresh matrix evidence
- PostgreSQL writes: `false`
- canonical SQLite mutated: `false`
- git commit/push: `not done in this slice`

## Code Changes

- `docs/hermes-analysis/manaloom-knowledge/scripts/xmage_to_manaloom_effect_hints.py`
  - exact XMage mapper for `ScholarOfNewHorizons`
  - emitted scope:
    `activated_remove_counter_plains_tutor_battlefield_tapped_if_behind_else_hand_v1`
- `docs/hermes-analysis/manaloom-knowledge/scripts/xmage_semantic_family_classifier.py`
  - exact-scope batch-safe recognizer for the Scholar tutor creature family
- `docs/hermes-analysis/manaloom-knowledge/scripts/battle_analyst_v9.py`
  - ETB +1/+1 counter application for exact/runtime-backed permanents
  - runtime support for tutoring any `Plains` card
  - activated land-tutor creature branch now supports:
    - removing a controlled `+1/+1` counter as activation cost
    - upgrading the tutored Plains directly onto the battlefield tapped when behind on lands
- `docs/hermes-analysis/manaloom-knowledge/scripts/test_xmage_to_manaloom_effect_hints.py`
  - mapper test for Scholar
- `docs/hermes-analysis/manaloom-knowledge/scripts/test_xmage_semantic_family_batch_pipeline.py`
  - classifier batch-safe test for Scholar
- `docs/hermes-analysis/manaloom-knowledge/scripts/battle_card_specific_tests.py`
  - runtime tests:
    - `test_pg232_scholar_of_new_horizons_enters_with_counter_and_upgrades_plains_to_battlefield_when_behind`
    - `test_pg232_scholar_of_new_horizons_puts_plains_into_hand_when_not_behind`

## Test Evidence

- `python3 -m unittest test_xmage_to_manaloom_effect_hints.py`
  - `226` tests passed
- `python3 -m unittest test_xmage_semantic_family_batch_pipeline.py`
  - `211` tests passed
- `python3 test_battle_analyst_v10_3.py`
  - full aggregated battle suite passed, including both new Scholar runtime tests

## Pipeline Evidence

- fresh pipeline prefix:
  `xmage_current_replay_batch_pipeline_20260626_pg232_scholar_runtime_v1`
- manifest:
  `docs/hermes-analysis/master_optimizer_reports/xmage_current_replay_batch_pipeline_20260626_pg232_scholar_runtime_v1_manifest.json`
- proposals:
  `docs/hermes-analysis/master_optimizer_reports/xmage_current_replay_batch_pipeline_20260626_pg232_scholar_runtime_v1_proposals.json`
- matrix:
  `docs/hermes-analysis/master_optimizer_reports/lorehold_ideal_candidate_matrix_20260626_pg232_scholar_runtime_v1.json`

### Family / proposal deltas

- `creature`: `5 -> 6`
- `manual_model`: `331 -> 330`
- `xmage_source_valid_mapper_required`: `327 -> 326`
- `ready_for_structured_xmage_pull_review_required`: `69 -> 70`
- `batch_pg_candidate_after_precheck`: `3 -> 4`
- `mapper_metadata_or_test_scenario_required`: `328 -> 327`

### Lorehold-scoped matrix deltas

Restricted to deck ids:
`6, 606, 607, 608, 609, 610, 611, 612, 613, 614, 615, 616`

- `needs_rule_before_strategy`: `77 -> 76`
- `watchlist_candidate`: `120 -> 121`
- `mapper_manual`: `68 -> 67`
- `package_ready`: `3 -> 4`

### Scholar row movement

- before:
  - `recommendation_lane=needs_rule_before_strategy`
  - `rule_status=mapper_manual`
  - `promotion_lane=mapper_metadata_or_test_scenario_required`
  - `score=11.0`
- after:
  - `recommendation_lane=watchlist_candidate`
  - `rule_status=package_ready`
  - `promotion_lane=batch_metadata_candidate_requires_pg_precheck`
  - `score=35.0`

## Queue / Audit State

- live effective queue:
  - `package_ready_unprepared=4`
  - cards:
    `Galvanoth`, `Palantír of Orthanc`, `Scholar of New Horizons`, `Velomachus Lorehold`
- strategy consistency audit:
  - `17/18` pass
  - only failing check:
    `effective_queue.package_ready_unprepared=4`

## Slot Optimizer Smoke

Restricted smoke against the PG232 matrix:

- `python3 -u slot_optimizer.py --deck-id 6 --games 1 --max-per-category 1 --candidate-matrix ...pg232... --candidate-lane priority_benchmark_candidate --phase pg232_scholar_runtime_smoke`
- pre-run evidence before manual interrupt:
  - `baseline_id=9`
  - `baseline_wr=12.5%`
  - `candidate_allowlist_size=46`
  - `selected_candidates=15`
  - `battle_replay_final_status=review_required`
  - `mandatory_gate_divergences=["event_contract_static=review_required"]`
- category scan had already reached:
  - `[draw] 1 selected candidates (cut target: Valakut Awakening // Valakut Stoneforge)`

This confirms the baseline/hash-guard path still reads the fresh PG232 matrix correctly, but final optimizer WR evidence remains blocked by the same mandatory gate divergence and subprocess battle cost.

## Operational Conclusion

- `Scholar of New Horizons` is no longer in the Lorehold `needs_rule_before_strategy` backlog.
- Lorehold rule-first backlog dropped by exactly one card in this slice.
- Runtime coverage is in place and broadly regression-tested.
- The next highest-ROI Lorehold rule-first targets are now:
  `Blood Sun`, `Currency Converter`, and `Firesong and Sunspeaker`.
- No PostgreSQL package was applied in this slice, so all four `package_ready` cards remain outside the canonical `battle_ready` pool until PG precheck/apply/sync.
