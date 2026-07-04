# Lorehold Trace Cut Evidence Expansion Queue

- Generated at: `2026-07-04T21:25:37Z`
- PostgreSQL writes: `false`
- Source DB mutated: `false`
- Seed-safe cut report: `docs/hermes-analysis/master_optimizer_reports/lorehold_seed_safe_cut_hypothesis_20260704_role_tag_repair.json`
- Current champion snapshot: `docs/hermes-analysis/master_optimizer_reports/lorehold_current_champion_snapshot_20260704_learning_refresh.json`
- Micro-package model: `docs/hermes-analysis/master_optimizer_reports/lorehold_trace_targeted_micro_package_model_20260704_role_tag_repair.json`
- Cut slots: `94`
- Seed-safe ready: `0`
- Reviewable evidence gaps: `0`
- Same-lane hard blocked: `2`
- Hard blocked: `92`
- Recommended next action: `no_cut_slot_to_expand_under_current_607_contract`
- Actionability counts: `{"hard_blocked": 92, "same_lane_hard_blocked": 2}`

## Reviewable Evidence Gaps

- None.

## Same-Lane Hard Blocked

- `Creative Technique` lane `big_spell_value` absolute blockers `cut_is_miracle_core_big_spell, miracle_or_finisher_core, prior_rejected_cut, protected_cut`.
- `Bender's Waterskin` lane `early_mana` absolute blockers `cut_is_early_mana_floor_support, early_mana_floor_support, measured_high_cut_exposure, prior_rejected_cut, protected_cut`.

## Top Near Misses

- `Creative Technique` actionability `same_lane_hard_blocked` lane `big_spell_value` blockers `cut_is_miracle_core_big_spell, cut_safety_not_seed_safe, manual_status_not_seed_safe, miracle_or_finisher_core, prior_rejected_cut, protected_cut, same_lane_only_requires_concrete_same_lane_add`.
- `Bender's Waterskin` actionability `same_lane_hard_blocked` lane `early_mana` blockers `cut_is_early_mana_floor_support, cut_not_flex_decision, cut_safety_not_seed_safe, early_mana_floor_support, manual_status_not_seed_safe, measured_high_cut_exposure, prior_rejected_cut, protected_cut, same_lane_only_requires_concrete_same_lane_add`.
- `Generous Gift` actionability `hard_blocked` lane `removal` blockers `cut_not_flex_decision, manual_status_not_seed_safe, measured_high_cut_exposure, missing_cut_safety_row`.
- `Improvisation Capstone` actionability `hard_blocked` lane `draw` blockers `cut_not_flex_decision, manual_status_not_seed_safe, missing_cut_safety_row, structural_dependency`.
- `Esper Sentinel` actionability `hard_blocked` lane `draw` blockers `cut_not_flex_decision, manual_status_not_seed_safe, measured_high_cut_exposure, missing_cut_safety_row`.
- `Path to Exile` actionability `hard_blocked` lane `removal` blockers `cut_not_flex_decision, manual_status_not_seed_safe, measured_high_cut_exposure, missing_cut_safety_row`.
- `Swords to Plowshares` actionability `hard_blocked` lane `removal` blockers `cut_not_flex_decision, manual_status_not_seed_safe, measured_high_cut_exposure, missing_cut_safety_row`.
- `Stroke of Midnight` actionability `hard_blocked` lane `removal` blockers `cut_not_flex_decision, manual_status_not_seed_safe, missing_cut_safety_row, prior_rejected_cut, prior_rejected_cut_slot`.
- `Winds of Abandon` actionability `hard_blocked` lane `removal` blockers `cut_not_flex_decision, manual_status_not_seed_safe, missing_cut_safety_row, prior_rejected_cut, prior_rejected_cut_slot`.
- `Monument to Endurance` actionability `hard_blocked` lane `early_mana` blockers `cut_not_flex_decision, early_mana_floor_support, manual_status_not_seed_safe, measured_high_cut_exposure, missing_cut_safety_row`.
- `Sensei's Divining Top` actionability `hard_blocked` lane `draw` blockers `cut_not_flex_decision, manual_status_not_seed_safe, measured_high_cut_exposure, missing_cut_safety_row, protected_cut`.
- `Smothering Tithe` actionability `hard_blocked` lane `early_mana` blockers `cut_not_flex_decision, early_mana_floor_support, manual_status_not_seed_safe, measured_high_cut_exposure, missing_cut_safety_row`.
- `Hexing Squelcher` actionability `hard_blocked` lane `contextual` blockers `cut_not_flex_decision, cut_safety_not_seed_safe, manual_review_cut_safety_block, manual_status_not_seed_safe, prior_rejected_cut, protected_cut`.
- `Call Forth the Tempest` actionability `hard_blocked` lane `spell_velocity` blockers `cut_is_miracle_core_big_spell, cut_not_flex_decision, manual_status_not_seed_safe, miracle_or_finisher_core, missing_cut_safety_row, structural_dependency`.
- `Elegant Parlor` actionability `hard_blocked` lane `mana_base` blockers `cut_not_flex_decision, mana_base_never_cut, manual_status_not_seed_safe, missing_cut_safety_row, never_cut_lane, never_cut_or_mana_base`.
- `Spectator Seating` actionability `hard_blocked` lane `mana_base` blockers `cut_not_flex_decision, mana_base_never_cut, manual_status_not_seed_safe, missing_cut_safety_row, never_cut_lane, never_cut_or_mana_base`.
- `Windswept Heath` actionability `hard_blocked` lane `mana_base` blockers `cut_not_flex_decision, mana_base_never_cut, manual_status_not_seed_safe, missing_cut_safety_row, never_cut_lane, never_cut_or_mana_base`.
- `Arid Mesa` actionability `hard_blocked` lane `mana_base` blockers `cut_not_flex_decision, mana_base_never_cut, manual_status_not_seed_safe, missing_cut_safety_row, never_cut_lane, never_cut_or_mana_base`.
- `War Room` actionability `hard_blocked` lane `mana_base` blockers `cut_not_flex_decision, mana_base_never_cut, manual_status_not_seed_safe, missing_cut_safety_row, never_cut_lane, never_cut_or_mana_base`.
- `Exotic Orchard` actionability `hard_blocked` lane `mana_base` blockers `cut_not_flex_decision, mana_base_never_cut, manual_status_not_seed_safe, missing_cut_safety_row, never_cut_lane, never_cut_or_mana_base`.

## Method Notes

- This report does not make blocked cuts safe.
- A reviewable evidence gap must be reclassified by cut-safety evidence before any package gate.
- If reviewable_evidence_gap_count is zero, the current 607 one-for-one cut contract is exhausted.
- PostgreSQL and SQLite are not mutated by this script.
