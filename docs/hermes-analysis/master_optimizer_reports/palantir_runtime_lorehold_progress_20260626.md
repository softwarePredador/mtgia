# Palantir of Orthanc Lorehold Progress 2026-06-26

## Scope

- target card: `Palantír of Orthanc`
- objective slice: move one Lorehold-facing `needs_rule_before_strategy` / `split_scope` card into a verified XMage -> ManaLoom package-ready lane with runtime coverage and fresh matrix evidence
- PostgreSQL writes: `false`
- canonical SQLite mutated: `true` only through normal local pipeline/materialization flow
- git commit/push: `not done in this slice`

## Code Changes

- `docs/hermes-analysis/manaloom-knowledge/scripts/xmage_to_manaloom_effect_hints.py`
  - exact XMage mapper for `PalantirOfOrthanc`
  - emitted scope:
    `controller_end_step_add_influence_scry_two_target_opponent_may_draw_else_mill_and_life_loss_v1`
- `docs/hermes-analysis/manaloom-knowledge/scripts/xmage_semantic_family_classifier.py`
  - exact-scope batch-safe recognizer for the Palantir draw-engine family
- `docs/hermes-analysis/manaloom-knowledge/scripts/battle_analyst_v9.py`
  - end-step runtime branch for:
    `add_named_counter_scry_target_opponent_may_draw_else_mill_life_loss`
  - added conservative controller scry helper and life-loss projection
- `docs/hermes-analysis/manaloom-knowledge/scripts/test_xmage_to_manaloom_effect_hints.py`
  - mapper test for Palantir
- `docs/hermes-analysis/manaloom-knowledge/scripts/test_xmage_semantic_family_batch_pipeline.py`
  - classifier batch-safe test for Palantir
- `docs/hermes-analysis/manaloom-knowledge/scripts/battle_card_specific_tests.py`
  - runtime tests:
    - `test_pg229_palantir_end_step_target_opponent_allows_draw_when_projected_loss_is_high`
    - `test_pg229_palantir_end_step_decline_draw_mills_and_deals_total_mana_value_damage`

## Test Evidence

- `python3 -m unittest test_xmage_to_manaloom_effect_hints.py`
  - `223` tests passed
- `python3 -m unittest test_xmage_semantic_family_batch_pipeline.py`
  - `208` tests passed
- `python3 test_battle_analyst_v10_3.py`
  - full aggregated battle suite passed, including both new Palantir runtime tests

## Pipeline Evidence

- fresh pipeline prefix:
  `xmage_current_replay_batch_pipeline_20260626_palantir_runtime_v1`
- manifest:
  `docs/hermes-analysis/master_optimizer_reports/xmage_current_replay_batch_pipeline_20260626_palantir_runtime_v1_manifest.json`
- proposals:
  `docs/hermes-analysis/master_optimizer_reports/xmage_current_replay_batch_pipeline_20260626_palantir_runtime_v1_proposals.json`
- matrix:
  `docs/hermes-analysis/master_optimizer_reports/lorehold_ideal_candidate_matrix_20260626_palantir_runtime_v1.json`

### Family / proposal deltas

- `targeted_interaction`: `51 -> 50`
- `draw_engine`: `0 -> 1`
- `split_family_scope_review_required`: `62 -> 61`
- `batch_pg_candidate_after_precheck`: `0 -> 1`

### Lorehold-scoped matrix deltas

Restricted to deck ids:
`6, 606, 607, 608, 609, 610, 611, 612, 613, 614, 615, 616`

- `needs_rule_before_strategy`: `80 -> 79`
- `split_scope`: `8 -> 7`

### Palantir row movement

- before:
  - `recommendation_lane=needs_rule_before_strategy`
  - `rule_status=split_scope`
  - `promotion_lane=split_family_scope_review_required`
  - `score=13.5`
- after:
  - `recommendation_lane=low_priority`
  - `rule_status=package_ready`
  - `promotion_lane=batch_metadata_candidate_requires_pg_precheck`
  - `score=29.5`

## Deck Generation Evidence

- old generated candidate:
  `docs/hermes-analysis/master_optimizer_reports/lorehold_generated_candidate_20260626_try_v1.json`
  - hash: `a2a5793c8c7586bcf2b99860f54afeb0200a93ad127b0b71239fc3ff048d6579`
- new generated candidate:
  `docs/hermes-analysis/master_optimizer_reports/lorehold_generated_candidate_20260626_palantir_runtime_v1.json`
  - hash: `3d827d72b023d4cceb1277c388863000794a29de0ad1c338c9d01bd8c86cac19`

The candidate changed materially after the fresh pipeline/matrix run, even though Palantir itself stayed `package_ready` rather than `battle_ready`.

## Smoke Evidence

- active deck, seed `20260626`, 3 real opponents, 1 game each:
  - `0W/3L/0S`
- earlier generated candidate `try_v1` on same setup:
  - `1W/2L/0S`
- fresh generated candidate `palantir_runtime_v1` on same setup:
  - `1W/2L/0S`
  - wins/losses shifted by matchup:
    - win vs `Kraum, Ludevic's Opus #110`
    - losses vs `Kenrith, the Returned King #113` and `Umbris, Fear Manifest #114`

Candidate battle log:
`docs/hermes-analysis/master_optimizer_reports/lorehold_generated_candidate_20260626_palantir_runtime_v1/knowledge_dir/decks/lorehold-the-historian/BATTLE_LOG.md`

## Baseline / Slot Optimizer Evidence

The optimizer lane was exercised in restricted mode:

- `python3 master_optimizer_baseline.py --deck-id 6 --games 1 --report`
  - interrupted after long-running battle subprocess
- `python3 slot_optimizer.py --deck-id 6 --games 1 --max-per-category 1 --candidate-matrix ... --candidate-lane priority_benchmark_candidate --phase palantir_runtime_smoke`
  - produced pre-run evidence before interruption:
    - `baseline_id=9`
    - `baseline_wr=12.5%`
    - `candidate_allowlist_size=75`
    - `selected_candidates=15`
    - gate status still `review_required`
    - mandatory divergence still:
      `event_contract_static=review_required`

This means the baseline/hash-guard path is wired and reading the new matrix correctly, but it is not yet usable as a final approval gate while the battle subprocess cost and mandatory gate state remain unresolved.

## Operational Conclusion

- `Palantír of Orthanc` is no longer in the Lorehold split-scope backlog.
- Lorehold first-priority backlog dropped by exactly one card in this slice.
- Runtime coverage is in place and broadly regression-tested.
- The next Lorehold split-scope ROI target remains `Blood Sun`, with `Firesong and Sunspeaker` still behind it.
- No PostgreSQL package was applied in this slice, so `package_ready` cards still do not enter the canonical `battle_ready` pool.
