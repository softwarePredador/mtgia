# Global Commander Same-Lane Package Resynthesizer

- generated_at: `2026-07-05T23:17:11.718186+00:00`
- status: `same_lane_package_resynthesis_blocks_candidate_copy_needs_source_lanes`
- commander: `Kaalia of the Vast`
- deck_id: `619`
- package_axes: `angels_demons_dragons_payoffs`
- selected_add_count: `6`
- selected_cut_count: `5`
- held_payoff_add_count: `6`
- same_lane_axis_requirement_count: `3`
- satisfied_same_lane_axis_count: `0`
- value_safe_cut_count: `0`
- ready_pair_count: `0`
- candidate_copy_allowed_now: `false`
- value_safe_reclassification_allowed_now: `false`
- battle_gate_allowed_now: `false`
- promotion_allowed: `false`
- next_gate: `expand_same_lane_add_source_lanes_for_target_cut_roles`

## Same-Lane Axis Requirements

| Cut Role | Target Cuts | Required Add Axis | Explicit Adds | Status | Next Gate |
| --- | ---: | --- | ---: | --- | --- |
| `haste_protection_silence` | 4 | `commander_attack_window` | 0 | `source_lane_required_before_package_resynthesis` | `expand_same_lane_add_source_lane_for_role` |
| `mana_acceleration` | 1 | `mana_acceleration_replacement` | 0 | `source_lane_required_before_package_resynthesis` | `expand_same_lane_add_source_lane_for_role` |
| `tutors_access` | 8 | `tutors_access_replacement` | 0 | `source_lane_required_before_package_resynthesis` | `expand_same_lane_add_source_lane_for_role` |

## Held Payoff Adds

- `Dragon Mage`: axis `angels_demons_dragons_payoffs`, guardrail `payoff_axis_needs_own_value_safe_cut_or_same_lane_package_cut`
- `Bonehoard Dracosaur`: axis `angels_demons_dragons_payoffs`, guardrail `payoff_axis_needs_own_value_safe_cut_or_same_lane_package_cut`
- `Drakuseth, Maw of Flames`: axis `angels_demons_dragons_payoffs`, guardrail `payoff_axis_needs_own_value_safe_cut_or_same_lane_package_cut`
- `The Balrog of Moria`: axis `angels_demons_dragons_payoffs`, guardrail `payoff_axis_needs_own_value_safe_cut_or_same_lane_package_cut`
- `Wrathful Red Dragon`: axis `angels_demons_dragons_payoffs`, guardrail `payoff_axis_needs_own_value_safe_cut_or_same_lane_package_cut`
- `Akroma, Angel of Wrath`: axis `angels_demons_dragons_payoffs`, guardrail `payoff_axis_needs_own_value_safe_cut_or_same_lane_package_cut`

## Selected Cut Diagnostics

- `Diabolic Intent`: roles `tutors_access`, required replacement axes `tutors_access_replacement`
- `Jeska's Will`: roles `mana_acceleration`, required replacement axes `mana_acceleration_replacement`
- `Professional Face-Breaker`: roles `mana_acceleration`, required replacement axes `mana_acceleration_replacement`
- `Ornithopter of Paradise`: roles `mana_acceleration`, required replacement axes `mana_acceleration_replacement`
- `Dark Ritual`: roles `mana_acceleration`, required replacement axes `mana_acceleration_replacement`

## Resynthesis Actions

| Priority | Action | Status | Reason |
| --- | --- | --- | --- |
| `P0` | `expand_same_lane_add_source_lanes_for_target_cut_roles` | `required_now` | Every exhausted cut role needs an explicit replacement add lane before package pairing. |
| `P1` | `hold_payoff_package_until_payoff_lane_has_own_cuts` | `held` | Payoff adds remain useful source candidates but cannot consume ramp, tutor, or attack-window cuts. |
| `P3` | `keep_package_resynthesis_closed_to_deck_action` | `closed_no_deck_action` | Requirements are not a materialized package and do not open battle or promotion. |

## Blockers

- `same_lane_add_source_lanes_missing_for_target_cut_roles`
- `payoff_adds_held_until_payoff_lane_has_own_cuts`
- `candidate_copy_closed_until_named_same_lane_value_safe_pairs_exist`

## Policy

- resynthesis_boundary: This gate creates source-lane requirements, not deck changes.
- same_lane_boundary: A cut role must be replaced by an explicit same-lane add axis or separately proven by equal-gate evidence.
- payoff_boundary: Payoff source candidates stay held when current cut pressure is ramp, tutor, or attack-window pressure.
- battle_boundary: No battle or promotion opens from requirements alone.
