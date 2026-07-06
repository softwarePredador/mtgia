# Global Commander Same-Lane Used Cut Recovery Router

- generated_at: `2026-07-06T00:04:33.190569+00:00`
- status: `same_lane_used_cut_recovery_routes_to_new_cut_source`
- commander: `Kaalia of the Vast`
- deck_id: `619`
- used_cut_count: `19`
- strict_recovery_count: `10`
- same_lane_replacement_proof_count: `9`
- no_same_lane_route_count: `0`
- candidate_copy_allowed_now: `false`
- value_safe_reclassification_allowed_now: `false`
- battle_gate_allowed_now: `false`
- promotion_allowed: `false`
- next_gate: `mine_or_research_new_same_lane_cut_source_before_candidate_copy`

## Used Cut Recovery Rows

| Cut | Role | Usage | Routes | Decision | Next Evidence |
| --- | --- | ---: | ---: | --- | --- |
| `Smothering Tithe` | `mana_acceleration` | 163 | 1 | `used_structural_or_anchor_cut_needs_strict_replacement_or_new_cut_source` | `prefer_new_cut_source_unless_replacement_proof_is_explicit` |
| `Birgi, God of Storytelling // Harnfel, Horn of Bounty` | `mana_acceleration` | 21 | 1 | `used_structural_or_anchor_cut_needs_strict_replacement_or_new_cut_source` | `prefer_new_cut_source_unless_replacement_proof_is_explicit` |
| `Ornithopter of Paradise` | `mana_acceleration` | 12 | 1 | `used_cut_has_same_lane_add_route_but_not_value_safe` | `collect_explicit_replacement_proof_or_equal_gate` |
| `Silence` | `haste_protection_silence` | 12 | 2 | `used_structural_or_anchor_cut_needs_strict_replacement_or_new_cut_source` | `prefer_new_cut_source_unless_replacement_proof_is_explicit` |
| `Voice of Victory` | `haste_protection_silence` | 12 | 2 | `used_cut_has_same_lane_add_route_but_not_value_safe` | `collect_explicit_replacement_proof_or_equal_gate` |
| `Demonic Tutor` | `tutors_access` | 9 | 5 | `used_structural_or_anchor_cut_needs_strict_replacement_or_new_cut_source` | `prefer_new_cut_source_unless_replacement_proof_is_explicit` |
| `Jeska's Will` | `mana_acceleration` | 9 | 1 | `used_structural_or_anchor_cut_needs_strict_replacement_or_new_cut_source` | `prefer_new_cut_source_unless_replacement_proof_is_explicit` |
| `Mana Vault` | `mana_acceleration` | 9 | 1 | `used_structural_or_anchor_cut_needs_strict_replacement_or_new_cut_source` | `prefer_new_cut_source_unless_replacement_proof_is_explicit` |
| `The One Ring` | `haste_protection_silence` | 9 | 2 | `used_cut_has_same_lane_add_route_but_not_value_safe` | `collect_explicit_replacement_proof_or_equal_gate` |
| `Lightning Greaves` | `haste_protection_silence` | 8 | 2 | `used_structural_or_anchor_cut_needs_strict_replacement_or_new_cut_source` | `prefer_new_cut_source_unless_replacement_proof_is_explicit` |
| `Sunforger` | `tutors_access` | 8 | 5 | `used_cut_has_same_lane_add_route_but_not_value_safe` | `collect_explicit_replacement_proof_or_equal_gate` |
| `Sol Ring` | `mana_acceleration` | 7 | 1 | `used_structural_or_anchor_cut_needs_strict_replacement_or_new_cut_source` | `prefer_new_cut_source_unless_replacement_proof_is_explicit` |
| `Professional Face-Breaker` | `mana_acceleration` | 6 | 1 | `used_cut_has_same_lane_add_route_but_not_value_safe` | `collect_explicit_replacement_proof_or_equal_gate` |
| `Diabolic Intent` | `tutors_access` | 5 | 5 | `used_cut_has_same_lane_add_route_but_not_value_safe` | `collect_explicit_replacement_proof_or_equal_gate` |
| `Arcane Signet` | `mana_acceleration` | 3 | 1 | `used_structural_or_anchor_cut_needs_strict_replacement_or_new_cut_source` | `prefer_new_cut_source_unless_replacement_proof_is_explicit` |
| `Ragavan, Nimble Pilferer` | `haste_protection_silence` | 3 | 2 | `used_cut_has_same_lane_add_route_but_not_value_safe` | `collect_explicit_replacement_proof_or_equal_gate` |
| `Ragavan, Nimble Pilferer` | `mana_acceleration` | 3 | 1 | `used_cut_has_same_lane_add_route_but_not_value_safe` | `collect_explicit_replacement_proof_or_equal_gate` |
| `Enlightened Tutor` | `tutors_access` | 2 | 5 | `used_structural_or_anchor_cut_needs_strict_replacement_or_new_cut_source` | `prefer_new_cut_source_unless_replacement_proof_is_explicit` |
| `Hammer of Nazahn` | `haste_protection_silence` | 1 | 2 | `used_cut_has_same_lane_add_route_but_not_value_safe` | `collect_explicit_replacement_proof_or_equal_gate` |

## Blockers

- `used_stage_cuts_are_not_value_safe_from_current_trace`
- `candidate_copy_closed_until_new_cut_source_or_explicit_replacement_proof`
- `used_structural_or_anchor_cuts_need_strict_recovery:10`

## Policy

- usage_boundary: A used cut is not value-safe unless later proof replaces its function or finds a different cut.
- structural_boundary: Structural staples, expected anchors, and prior failed-gate cuts should prefer new cut-source lanes unless replacement proof is explicit.
- candidate_copy_boundary: This router never opens candidate copy or battle.
