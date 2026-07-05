# Global Commander Payoff Package Synthesizer

- generated_at: `2026-07-05T21:08:04.430544+00:00`
- status: `commander_payoff_package_synthesis_blocks_candidate_copy`
- commander: `Kaalia of the Vast`
- deck_id: `619`
- selected_add_count: `6`
- selected_cut_count: `5`
- unpaired_add_count: `1`
- package_size_limit: `8`
- candidate_copy_allowed_now: `false`
- battle_gate_allowed_now: `false`
- promotion_allowed: `false`
- candidate_copy_blocker_count: `1`
- next_gate: `expand_commander_cut_source_lane_for_full_profile_package`

## Requirements

| Axis | Initial | Remaining |
| --- | ---: | ---: |
| `commander_attack_window` | 0 | 0 |
| `lands` | 0 | 0 |
| `spot_interaction` | 0 | 0 |
| `angels_demons_dragons_payoffs` | 6 | 0 |
| `reanimation_plan_b` | 0 | 0 |

## Blockers

- `insufficient_reviewable_cuts_for_full_profile_package:required_6_ready_5`

## Selected Adds

| Add | Axis | Covers | Score | Roles |
| --- | --- | --- | ---: | --- |
| `Dragon Mage` | `angels_demons_dragons_payoffs` | `angels_demons_dragons_payoffs` | 98 | `angels_demons_dragons_payoffs, card_draw_selection` |
| `Bonehoard Dracosaur` | `angels_demons_dragons_payoffs` | `angels_demons_dragons_payoffs` | 97 | `angels_demons_dragons_payoffs, mana_acceleration` |
| `Drakuseth, Maw of Flames` | `angels_demons_dragons_payoffs` | `angels_demons_dragons_payoffs` | 96 | `angels_demons_dragons_payoffs` |
| `The Balrog of Moria` | `angels_demons_dragons_payoffs` | `angels_demons_dragons_payoffs` | 96 | `angels_demons_dragons_payoffs, card_draw_selection, haste_protection_silence, mana_acceleration` |
| `Wrathful Red Dragon` | `angels_demons_dragons_payoffs` | `angels_demons_dragons_payoffs` | 96 | `angels_demons_dragons_payoffs, dedicated_win_conditions` |
| `Akroma, Angel of Wrath` | `angels_demons_dragons_payoffs` | `angels_demons_dragons_payoffs` | 95 | `angels_demons_dragons_payoffs, haste_protection_silence` |

## Tentative Add/Cut Pairs

| Step | Add | Cut | Cut Rationale |
| ---: | --- | --- | --- |
| 1 | `Dragon Mage` | `Diabolic Intent` | over_target_tutors_access, tutor_role_above_target_review |
| 2 | `Bonehoard Dracosaur` | `Jeska's Will` | over_target_mana_acceleration |
| 3 | `Drakuseth, Maw of Flames` | `Professional Face-Breaker` | over_target_mana_acceleration |
| 4 | `The Balrog of Moria` | `Ornithopter of Paradise` | over_target_mana_acceleration |
| 5 | `Wrathful Red Dragon` | `Dark Ritual` | over_target_mana_acceleration |

## Unpaired Adds

- `Akroma, Angel of Wrath`: covers `angels_demons_dragons_payoffs`

## Policy

- package_boundary: A synthesized package is planning evidence, not a deck mutation.
- cut_boundary: Every add needs a reviewed cut before candidate-copy materialization.
- size_boundary: Packages over 8 swaps must be split or re-sourced before materialization.
- battle_boundary: Battle and promotion remain closed until candidate copy, strategy matrix, and replay gates pass.
