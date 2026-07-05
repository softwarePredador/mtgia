# Global Commander Same-Lane Replacement Model

- generated_at: `2026-07-05T21:45:52.881767+00:00`
- status: `same_lane_replacement_model_routes_to_new_cut_source_lane`
- commander: `Kaalia of the Vast`
- deck_id: `619`
- usage_blocked_cut_count: `3`
- same_lane_replacement_route_count: `0`
- incidental_role_overlap_count: `4`
- remaining_stage_only_cut_source_count: `12`
- candidate_copy_allowed_now: `false`
- value_safe_reclassification_allowed_now: `false`
- battle_gate_allowed_now: `false`
- promotion_allowed: `false`
- next_gate: `collect_new_cut_source_lane_evidence_after_contextual_usage_block`

## Usage-Blocked Cuts

| Cut | Decision | Roles | Same-Lane Routes | Incidental Overlaps |
| --- | --- | --- | ---: | ---: |
| `Diabolic Intent` | `blocked_no_same_lane_replacement_route` | `tutors_access` | 0 | 0 |
| `Ornithopter of Paradise` | `blocked_no_same_lane_replacement_route` | `mana_acceleration` | 0 | 2 |
| `Professional Face-Breaker` | `blocked_no_same_lane_replacement_route` | `mana_acceleration` | 0 | 2 |

## Remaining Cut Source Lane Rows

| Burden | Cut | Roles | Route | Reasons |
| ---: | --- | --- | --- | --- |
| 3 | `Sunforger` | `tutors_access` | `collect_attack_window_same_lane_replacement_trace` | `attack_window_cut_requires_same_lane_stage_proof` |
| 3 | `Alicia Masters, Skilled Sculptor` | `mana_acceleration` | `collect_attack_window_same_lane_replacement_trace` | `attack_window_cut_requires_same_lane_stage_proof` |
| 5 | `Jeska's Will` | `mana_acceleration` | `collect_structural_staple_same_lane_or_equal_gate_proof` | `structural_foundation_staple_requires_same_lane_or_battle_proof` |
| 5 | `Smothering Tithe` | `mana_acceleration` | `collect_structural_staple_same_lane_or_equal_gate_proof` | `structural_foundation_staple_requires_same_lane_or_battle_proof` |
| 5 | `Demonic Tutor` | `tutors_access` | `collect_structural_staple_same_lane_or_equal_gate_proof` | `commander_expected_package_anchor_requires_stage_proof, structural_foundation_staple_requires_same_lane_or_battle_proof` |
| 5 | `Enlightened Tutor` | `tutors_access` | `collect_structural_staple_same_lane_or_equal_gate_proof` | `commander_expected_package_anchor_requires_stage_proof, structural_foundation_staple_requires_same_lane_or_battle_proof` |
| 5 | `Vampiric Tutor` | `tutors_access` | `collect_structural_staple_same_lane_or_equal_gate_proof` | `commander_expected_package_anchor_requires_stage_proof, structural_foundation_staple_requires_same_lane_or_battle_proof` |
| 5 | `Arcane Signet` | `mana_acceleration` | `collect_structural_staple_same_lane_or_equal_gate_proof` | `commander_expected_package_anchor_requires_stage_proof, structural_foundation_staple_requires_same_lane_or_battle_proof` |
| 5 | `Dark Ritual` | `mana_acceleration` | `collect_structural_staple_same_lane_or_equal_gate_proof` | `structural_foundation_staple_requires_same_lane_or_battle_proof` |
| 5 | `Mana Vault` | `mana_acceleration` | `collect_structural_staple_same_lane_or_equal_gate_proof` | `structural_foundation_staple_requires_same_lane_or_battle_proof` |
| 5 | `Sol Ring` | `mana_acceleration` | `collect_structural_staple_same_lane_or_equal_gate_proof` | `commander_expected_package_anchor_requires_stage_proof, structural_foundation_staple_requires_same_lane_or_battle_proof` |
| 6 | `Birgi, God of Storytelling // Harnfel, Horn of Bounty` | `mana_acceleration` | `collect_new_global_battle_feedback_reopen_proof` | `global_battle_feedback_requires_new_same_lane_or_gate` |

## Blockers

- `contextual_usage_blocked_cuts:Diabolic Intent,Ornithopter of Paradise,Professional Face-Breaker`
- `no_explicit_same_lane_replacement_route_for_usage_blocked_contextual_cuts`
- `value_safe_reclassification_still_closed`

## Policy

- same_lane_boundary: A card used by the target deck needs explicit same-lane replacement proof before reclassification.
- incidental_overlap_boundary: An added payoff with incidental mana/card text is not same-lane proof unless it explicitly covers the cut lane.
- mutation_boundary: This model does not copy decks, mutate DBs, run battles, reclassify cuts, or open promotion.
