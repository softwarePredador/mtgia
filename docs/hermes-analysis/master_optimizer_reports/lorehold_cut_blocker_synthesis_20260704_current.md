# Lorehold Cut Blocker Synthesis

- generated_at: `2026-07-04T22:38:20Z`
- status: `cut_blocker_no_seed_safe_pressure_requires_full_shell`
- postgres_writes: `false`
- source_db_mutated: `false`
- deck_607_mutated: `false`
- seed_safe_ready_count: `0`
- evidence_gap_only_count: `0`
- same_lane_only_count: `0`
- same_lane_constraint_count: `2`
- hard_blocked_count: `94`
- classification_counts: `{"hard_blocked": 94}`

## Pressure Finding

- status: `pressure_signal_blocked_by_cut_model`
- natural_trigger_cards: `["Guttersnipe", "Young Pyromancer"]`
- interpretation: Pressure adds have real signal, but 607 currently has no seed-safe or same-lane pressure-payoff cut. A Guttersnipe/Young Pyromancer package is therefore a full-shell hypothesis, not a one-for-one promotion gate.

## Evidence Gap Queue

- None.

## Same-Lane Only Queue

- `Creative Technique` lane `big_spell_value` requires concrete same-lane add; blockers `cut_is_miracle_core_big_spell, cut_safety_not_seed_safe, manual_status_not_seed_safe, miracle_or_finisher_core, prior_rejected_cut, protected_cut, same_lane_only_requires_concrete_same_lane_add`.
- `Bender's Waterskin` lane `early_mana` requires concrete same-lane add; blockers `cut_is_early_mana_floor_support, cut_not_flex_decision, cut_safety_not_seed_safe, early_mana_floor_support, manual_status_not_seed_safe, measured_high_cut_exposure, prior_rejected_cut, protected_cut, same_lane_only_requires_concrete_same_lane_add`.

## Hard-Blocked Top

- `Radiant Summit` lane `mana_base` blockers `cut_not_flex_decision, mana_base_never_cut, manual_status_not_seed_safe, missing_cut_safety_row, never_cut_lane, never_cut_or_mana_base, prior_rejected_cut`.
- `Call Forth the Tempest` lane `spell_velocity` blockers `cut_is_miracle_core_big_spell, cut_not_flex_decision, manual_status_not_seed_safe, miracle_or_finisher_core, missing_cut_safety_row, structural_dependency`.
- `Elegant Parlor` lane `mana_base` blockers `cut_not_flex_decision, mana_base_never_cut, manual_status_not_seed_safe, missing_cut_safety_row, never_cut_lane, never_cut_or_mana_base`.
- `Pinnacle Monk // Mystic Peak` lane `removal` blockers `cut_is_miracle_core_big_spell, cut_not_flex_decision, manual_status_not_seed_safe, missing_cut_safety_row, prior_rejected_cut, prior_rejected_cut_slot, prior_rejected_signature`.
- `Turbulent Steppe` lane `mana_base` blockers `cut_not_flex_decision, mana_base_never_cut, manual_status_not_seed_safe, missing_cut_safety_row, never_cut_lane, never_cut_or_mana_base, prior_rejected_cut`.
- `Redirect Lightning` lane `protection` blockers `cut_is_early_mana_floor_support, cut_is_protection_shell, cut_not_flex_decision, manual_status_not_seed_safe, missing_cut_safety_row, prior_rejected_cut, prior_rejected_cut_slot, protection_shell`.
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
- `Tibalt's Trickery` lane `protection` blockers `cut_is_protection_shell, cut_not_flex_decision, manual_status_not_seed_safe, missing_cut_safety_row, prior_rejected_cut, prior_rejected_cut_slot, protected_cut, protection_shell`.
- `Command Beacon` lane `mana_base` blockers `cut_not_flex_decision, mana_base_never_cut, manual_status_not_seed_safe, missing_cut_safety_row, never_cut_lane, never_cut_or_mana_base`.
- `Flooded Strand` lane `mana_base` blockers `cut_not_flex_decision, mana_base_never_cut, manual_status_not_seed_safe, missing_cut_safety_row, never_cut_lane, never_cut_or_mana_base`.
- `Insurrection` lane `wincon` blockers `cut_is_miracle_core_big_spell, manual_status_not_seed_safe, miracle_or_finisher_core, missing_cut_safety_row, protected_cut, structural_dependency`.
- `Reforge the Soul` lane `draw` blockers `cut_is_miracle_core_big_spell, cut_not_flex_decision, manual_status_not_seed_safe, miracle_or_finisher_core, missing_cut_safety_row, prior_rejected_cut, prior_rejected_cut_slot, protected_cut`.
- `Teferi's Protection` lane `protection` blockers `cut_is_protection_shell, cut_not_flex_decision, manual_status_not_seed_safe, missing_cut_safety_row, protection_shell, structural_dependency`.
- `Storm Herd` lane `big_spell_value` blockers `cut_is_miracle_core_big_spell, cut_not_flex_decision, cut_safety_not_seed_safe, manual_review_cut_safety_block, manual_status_not_seed_safe, miracle_or_finisher_core, prior_rejected_cut, protected_cut`.
- `Marsh Flats` lane `mana_base` blockers `cut_not_flex_decision, mana_base_never_cut, manual_status_not_seed_safe, missing_cut_safety_row, never_cut_lane, never_cut_or_mana_base`.
- `Sunbaked Canyon` lane `mana_base` blockers `cut_not_flex_decision, mana_base_never_cut, manual_status_not_seed_safe, missing_cut_safety_row, never_cut_lane, never_cut_or_mana_base`.
- `Bloodstained Mire` lane `mana_base` blockers `cut_not_flex_decision, mana_base_never_cut, manual_status_not_seed_safe, missing_cut_safety_row, never_cut_lane, never_cut_or_mana_base`.
- `Reliquary Tower` lane `mana_base` blockers `cut_not_flex_decision, cut_safety_not_seed_safe, mana_base_never_cut, manual_status_not_seed_safe, never_cut_lane, never_cut_or_mana_base, prior_rejected_cut, protected_cut`.
- `Tempt with Bunnies` lane `wincon` blockers `cut_is_miracle_core_big_spell, cut_not_flex_decision, manual_status_not_seed_safe, miracle_or_finisher_core, missing_cut_safety_row, structural_dependency`.
- `Sunbillow Verge` lane `mana_base` blockers `cut_not_flex_decision, mana_base_never_cut, manual_status_not_seed_safe, missing_cut_safety_row, never_cut_lane, never_cut_or_mana_base`.

## External Learning

- GameTyrant Lorehold deck tech: https://gametyrant.com/news/how-to-build-a-lorehold-the-historian-commander-deck-deck-tech
- EDHREC optimized topdeck page: https://edhrec.com/decks/lorehold-the-historian/optimized/topdeck
- Draftsim Lorehold Commander guide: https://draftsim.com/lorehold-the-historian-edh-deck/

## Decision

- keep_607_as_protected_baseline: `true`
- promotion_allowed: `false`
- reason: No current cut slot is seed-safe. Public Lorehold pressure evidence supports further pressure modeling, but the active 607 evidence classifies the available slots as hard-blocked, same-lane-only, or requiring more cut-safety evidence.
- next_actions:
  - build_same_lane_only_microbenchmarks_without_cross_lane_promotion
  - keep_607_protected_until_equal_gate_and_card_use_proof
  - model_pressure_as_full_shell_or_find_true_pressure_lane_cut
