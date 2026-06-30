# Lorehold Seed-Safe Cut Hypothesis Builder

- generated_at: `2026-06-30T22:34:00Z`
- postgres_writes: `False`
- source_db_mutated: `False`
- deck_id: `607`
- deck_card_count: `94`
- seed_safe_cut_ready_count: `0`
- same_lane_only_count: `2`
- blocked_count: `94`
- recommended_next_action: `expand_cut_safety_model_or_multi_card_shell_before_gate`
- status_counts: `{"blocked": 92, "same_lane_only_not_seed_safe": 2}`
- blocker_counts: `{"commander_never_cut": 1, "cut_is_early_mana_floor_support": 14, "cut_is_miracle_core_big_spell": 25, "cut_is_protection_shell": 13, "cut_not_flex_decision": 84, "cut_safety_not_seed_safe": 11, "early_mana_floor_support": 18, "mana_base_never_cut": 28, "manual_review_cut_safety_block": 8, "manual_status_not_seed_safe": 94, "measured_high_cut_exposure": 31, "miracle_or_finisher_core": 24, "missing_cut_safety_row": 77, "never_cut_lane": 29, "never_cut_or_mana_base": 29, "prior_rejected_cut": 39, "prior_rejected_cut_slot": 26, "prior_rejected_signature": 4, "protected_cut": 22, "protection_shell": 11, "same_lane_only_requires_concrete_same_lane_add": 2, "structural_dependency": 24}`

## Interpretation

- No battle package should be generated from this report.
- The current 607 shell has no generic seed-safe cut slot under the active evidence.
- Next work is a new cut-safety model, a multi-card shell hypothesis, or a diagnostic-only forced-access probe.

## Seed-Safe Cut Candidates

- None.

## Same-Lane Only Slots

- `Creative Technique` lane `big_spell_value` remains same-lane only; blockers `cut_is_miracle_core_big_spell, cut_safety_not_seed_safe, manual_status_not_seed_safe, miracle_or_finisher_core, prior_rejected_cut, protected_cut, same_lane_only_requires_concrete_same_lane_add`.
- `Bender's Waterskin` lane `early_mana` remains same-lane only; blockers `cut_is_early_mana_floor_support, cut_not_flex_decision, cut_safety_not_seed_safe, early_mana_floor_support, manual_status_not_seed_safe, measured_high_cut_exposure, prior_rejected_cut, protected_cut, same_lane_only_requires_concrete_same_lane_add`.

## Top Blocked Slots

- `Radiant Summit` lane `mana_base` blockers `cut_not_flex_decision, mana_base_never_cut, manual_status_not_seed_safe, missing_cut_safety_row, never_cut_lane, never_cut_or_mana_base, prior_rejected_cut`.
- `Call Forth the Tempest` lane `spell_velocity` blockers `cut_is_miracle_core_big_spell, cut_not_flex_decision, manual_status_not_seed_safe, miracle_or_finisher_core, missing_cut_safety_row, structural_dependency`.
- `Elegant Parlor` lane `mana_base` blockers `cut_not_flex_decision, mana_base_never_cut, manual_status_not_seed_safe, missing_cut_safety_row, never_cut_lane, never_cut_or_mana_base`.
- `Pinnacle Monk // Mystic Peak` lane `removal` blockers `cut_is_miracle_core_big_spell, cut_not_flex_decision, manual_status_not_seed_safe, missing_cut_safety_row, prior_rejected_cut, prior_rejected_cut_slot, prior_rejected_signature`.
- `Tibalt's Trickery` lane `protection` blockers `cut_is_protection_shell, cut_not_flex_decision, manual_status_not_seed_safe, missing_cut_safety_row, prior_rejected_cut, prior_rejected_cut_slot, protected_cut, protection_shell`.
- `Turbulent Steppe` lane `mana_base` blockers `cut_not_flex_decision, mana_base_never_cut, manual_status_not_seed_safe, missing_cut_safety_row, never_cut_lane, never_cut_or_mana_base, prior_rejected_cut`.
- `Redirect Lightning` lane `draw` blockers `cut_is_early_mana_floor_support, cut_not_flex_decision, manual_status_not_seed_safe, missing_cut_safety_row, prior_rejected_cut, prior_rejected_cut_slot`.
- `Spectator Seating` lane `mana_base` blockers `cut_not_flex_decision, mana_base_never_cut, manual_status_not_seed_safe, missing_cut_safety_row, never_cut_lane, never_cut_or_mana_base`.
- `Hit the Mother Lode` lane `early_mana` blockers `cut_is_miracle_core_big_spell, cut_not_flex_decision, early_mana_floor_support, manual_status_not_seed_safe, miracle_or_finisher_core, missing_cut_safety_row, prior_rejected_cut, prior_rejected_cut_slot`.
- `Windswept Heath` lane `mana_base` blockers `cut_not_flex_decision, mana_base_never_cut, manual_status_not_seed_safe, missing_cut_safety_row, never_cut_lane, never_cut_or_mana_base`.
- `Arid Mesa` lane `mana_base` blockers `cut_not_flex_decision, mana_base_never_cut, manual_status_not_seed_safe, missing_cut_safety_row, never_cut_lane, never_cut_or_mana_base`.
- `War Room` lane `mana_base` blockers `cut_not_flex_decision, mana_base_never_cut, manual_status_not_seed_safe, missing_cut_safety_row, never_cut_lane, never_cut_or_mana_base`.
- `Exotic Orchard` lane `mana_base` blockers `cut_not_flex_decision, mana_base_never_cut, manual_status_not_seed_safe, missing_cut_safety_row, never_cut_lane, never_cut_or_mana_base`.
- `Prismatic Vista` lane `mana_base` blockers `cut_not_flex_decision, mana_base_never_cut, manual_status_not_seed_safe, missing_cut_safety_row, never_cut_lane, never_cut_or_mana_base`.
- `Battlefield Forge` lane `mana_base` blockers `cut_not_flex_decision, mana_base_never_cut, manual_status_not_seed_safe, missing_cut_safety_row, never_cut_lane, never_cut_or_mana_base`.
- `Flawless Maneuver` lane `protection` blockers `cut_is_protection_shell, cut_not_flex_decision, manual_status_not_seed_safe, missing_cut_safety_row, protection_shell, structural_dependency`.
- `Dawn's Truce` lane `hand_filter` blockers `cut_is_protection_shell, cut_not_flex_decision, cut_safety_not_seed_safe, manual_review_cut_safety_block, manual_status_not_seed_safe, prior_rejected_cut, protected_cut, protection_shell`.
- `Plaza of Heroes` lane `mana_base` blockers `cut_not_flex_decision, mana_base_never_cut, manual_status_not_seed_safe, missing_cut_safety_row, never_cut_lane, never_cut_or_mana_base`.
- `Command Beacon` lane `mana_base` blockers `cut_not_flex_decision, mana_base_never_cut, manual_status_not_seed_safe, missing_cut_safety_row, never_cut_lane, never_cut_or_mana_base`.
- `Flooded Strand` lane `mana_base` blockers `cut_not_flex_decision, mana_base_never_cut, manual_status_not_seed_safe, missing_cut_safety_row, never_cut_lane, never_cut_or_mana_base`.

## Method Notes

- This report is a cut-slot synthesis, not a deck promotion.
- A same-lane-only cut is not seed-safe without a concrete same-lane add and gate.
- Early mana, protection, miracle core, lands, commander, high-exposure slots, and prior-negative slots are blocked.
- PostgreSQL and SQLite are not mutated by this script.
