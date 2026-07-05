# Global Commander Same-Lane Package Source Synthesizer

- generated_at: `2026-07-05T23:37:01.990983+00:00`
- status: `same_lane_source_package_synthesized_no_cut_pairs`
- commander: `Kaalia of the Vast`
- deck_id: `619`
- package_size_limit: `8`
- source_lane_count: `3`
- ready_source_lane_count: `3`
- selected_add_count: `8`
- axes_covered_count: `3`
- unpaired_add_count: `8`
- ready_pair_count: `0`
- candidate_copy_allowed_now: `false`
- value_safe_reclassification_allowed_now: `false`
- battle_gate_allowed_now: `false`
- promotion_allowed: `false`
- next_gate: `collect_value_safe_same_lane_cut_pairs_for_resynthesized_package`

## Selected Add Package

| Add | Axis | Replaces Cut Role | Score | Roles |
| --- | --- | --- | ---: | --- |
| `Boros Charm` | `commander_attack_window` | `haste_protection_silence` | 132 | `haste_protection_silence` |
| `Fellwar Stone` | `mana_acceleration_replacement` | `mana_acceleration` | 136 | `mana_acceleration` |
| `Gamble` | `tutors_access_replacement` | `tutors_access` | 124 | `tutors_access` |
| `Swiftfoot Boots` | `commander_attack_window` | `haste_protection_silence` | 123 | `haste_protection_silence` |
| `Wishclaw Talisman` | `tutors_access_replacement` | `tutors_access` | 121 | `tutors_access` |
| `Entomb` | `tutors_access_replacement` | `tutors_access` | 120 | `tutors_access` |
| `Imperial Seal` | `tutors_access_replacement` | `tutors_access` | 119 | `tutors_access` |
| `Diabolic Tutor` | `tutors_access_replacement` | `tutors_access` | 114 | `tutors_access` |

## Source Lane Diagnostics

- `commander_attack_window`: ready `351`, selected `2`, cut_role `haste_protection_silence`
- `mana_acceleration_replacement`: ready `304`, selected `1`, cut_role `mana_acceleration`
- `tutors_access_replacement`: ready `105`, selected `5`, cut_role `tutors_access`

## Blockers

- `selected_adds_are_unpaired`
- `value_safe_same_lane_cut_pairs_missing`
- `candidate_copy_closed_until_scope_reducer_pairs_adds_and_cuts`

## Policy

- package_boundary: This report chooses review-only adds from source lanes; it does not pair cuts.
- same_lane_boundary: Every selected add carries an explicit required add axis tied to a target cut role.
- cut_boundary: No cut is value-safe until a later cut-pairing gate proves it.
- battle_boundary: No battle or promotion opens before cut pairing, candidate copy, strategy matrix, and replay evidence.
