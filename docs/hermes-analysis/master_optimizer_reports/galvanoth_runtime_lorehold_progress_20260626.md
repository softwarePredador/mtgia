# Galvanoth Lorehold Progress 2026-06-26

## Scope

- target card: `Galvanoth`
- objective slice: move one Lorehold-facing `needs_rule_before_strategy` / `mapper_manual` card into an exact XMage -> ManaLoom package-ready lane with runtime coverage and fresh matrix evidence
- PostgreSQL writes: `false`
- canonical SQLite mutated: `true` only through the normal local pipeline/materialization flow
- git commit/push: `not done in this slice`

## Code Changes

- `docs/hermes-analysis/manaloom-knowledge/scripts/xmage_to_manaloom_effect_hints.py`
  - exact XMage mapper for `Galvanoth`
  - emitted scope:
    `controller_upkeep_look_top_instant_or_sorcery_may_cast_without_paying_mana_v1`
- `docs/hermes-analysis/manaloom-knowledge/scripts/xmage_semantic_family_classifier.py`
  - exact-scope batch-safe recognizer for the Galvanoth upkeep free-cast creature family
- `docs/hermes-analysis/manaloom-knowledge/scripts/battle_analyst_v9.py`
  - upkeep runtime branch that looks at the top card and free-casts supported instant/sorcery spells from the library
- `docs/hermes-analysis/manaloom-knowledge/scripts/test_xmage_to_manaloom_effect_hints.py`
  - mapper test for Galvanoth
- `docs/hermes-analysis/manaloom-knowledge/scripts/test_xmage_semantic_family_batch_pipeline.py`
  - classifier batch-safe test for Galvanoth
- `docs/hermes-analysis/manaloom-knowledge/scripts/battle_card_specific_tests.py`
  - runtime test:
    `test_pg230_galvanoth_upkeep_casts_top_instant_without_paying_mana`

## Test Evidence

- `python3 -m unittest test_xmage_to_manaloom_effect_hints.py`
  - `224` tests passed
- `python3 -m unittest test_xmage_semantic_family_batch_pipeline.py`
  - `209` tests passed
- `python3 test_battle_analyst_v10_3.py`
  - full aggregated battle suite passed, including the new Galvanoth upkeep runtime test

## Pipeline Evidence

- fresh pipeline prefix:
  `xmage_current_replay_batch_pipeline_20260626_pg230_galvanoth_runtime_v1`
- manifest:
  `docs/hermes-analysis/master_optimizer_reports/xmage_current_replay_batch_pipeline_20260626_pg230_galvanoth_runtime_v1_manifest.json`
- proposals:
  `docs/hermes-analysis/master_optimizer_reports/xmage_current_replay_batch_pipeline_20260626_pg230_galvanoth_runtime_v1_proposals.json`
- effective queue:
  `docs/hermes-analysis/master_optimizer_reports/xmage_effective_queue_20260626_pg230_galvanoth_runtime_v1.json`
- matrix:
  `docs/hermes-analysis/master_optimizer_reports/lorehold_ideal_candidate_matrix_20260626_pg230_galvanoth_runtime_v1.json`

### Lorehold-scoped matrix deltas

Restricted to deck ids:
`6, 606, 607, 608, 609, 610, 611, 612, 613, 614, 615, 616`

- `needs_rule_before_strategy`: `80 -> 78`
- `watchlist_candidate`: `119 -> 120`
- `low_priority`: `50 -> 51`
- `mapper_manual`: `70 -> 69`
- `split_scope`: `8 -> 7`
- `package_ready`: `0 -> 2`

### Galvanoth row movement

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

### Effective queue note

- `Galvanoth` now sits in `package_ready_unprepared`
- current queue count there is `2`:
  - `Galvanoth`
  - `Palantír of Orthanc`
- this is why the fresh strategy consistency audit still reports `status=fail`;
  the failure is not a regression in the runtime slice, but an operational guard
  that unresolved package-ready cards still exist

## Operational Conclusion

- `Galvanoth` is no longer in the Lorehold `needs_rule_before_strategy` backlog.
- Lorehold first-priority backlog dropped by exactly two rows in this slice.
- runtime coverage is in place and regression-tested.
- the next highest-ROI Lorehold rule-first targets are now:
  - `Blood Sun`
  - `Currency Converter`
  - `Firesong and Sunspeaker`
  - `Scholar of New Horizons`
- no PostgreSQL package was applied in this slice, so `package_ready` cards still do not enter the canonical `battle_ready` pool.
