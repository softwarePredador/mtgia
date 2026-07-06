# Global Commander External Nonpayoff Same-Lane Source Candidate Discoverer

- generated_at: `2026-07-06T00:58:17.094628+00:00`
- status: `external_nonpayoff_same_lane_source_candidates_discovered_no_cut_permission`
- commander: `Kaalia of the Vast`
- deck_id: `619`
- source_candidate_count: `16`
- role_count: `3`
- current_deck_present_count: `6`
- outside_current_deck_count: `10`
- local_identity_found_count: `15`
- selected_as_package_add_count: `4`
- card_level_cut_permission_count: `0`
- candidate_copy_allowed_now: `false`
- value_safe_reclassification_allowed_now: `false`
- battle_gate_allowed_now: `false`
- promotion_allowed: `false`
- next_gate: `review_external_nonpayoff_same_lane_source_candidates_locally_before_miner`

## Source Candidate Rows

| Role | Card | In Deck | Selected Add | Identity | Status |
| --- | --- | ---: | ---: | ---: | --- |
| `haste_protection_silence` | `Lightning Greaves` | true | false | true | `external_source_candidate_already_in_current_deck_needs_trace_policy` |
| `haste_protection_silence` | `Swiftfoot Boots` | false | true | true | `external_source_candidate_already_selected_as_add_needs_pair_policy` |
| `haste_protection_silence` | `Boros Charm` | false | true | true | `external_source_candidate_already_selected_as_add_needs_pair_policy` |
| `haste_protection_silence` | `Dragon Tempest` | false | false | true | `external_source_candidate_ready_for_local_source_lane_review` |
| `haste_protection_silence` | `Bitter Reunion` | false | false | false | `external_source_candidate_needs_local_identity_resolution` |
| `haste_protection_silence` | `Dihada, Binder of Wills` | false | false | true | `external_source_candidate_ready_for_local_source_lane_review` |
| `mana_acceleration` | `Arcane Signet` | true | false | true | `external_source_candidate_already_in_current_deck_needs_trace_policy` |
| `mana_acceleration` | `Sword of the Animist` | false | false | true | `external_source_candidate_ready_for_local_source_lane_review` |
| `mana_acceleration` | `Dihada, Binder of Wills` | false | false | true | `external_source_candidate_ready_for_local_source_lane_review` |
| `mana_acceleration` | `Simian Spirit Guide` | false | false | true | `external_source_candidate_ready_for_local_source_lane_review` |
| `mana_acceleration` | `Fellwar Stone` | false | true | true | `external_source_candidate_already_selected_as_add_needs_pair_policy` |
| `tutors_access` | `Demonic Tutor` | true | false | true | `external_source_candidate_already_in_current_deck_needs_trace_policy` |
| `tutors_access` | `Enlightened Tutor` | true | false | true | `external_source_candidate_already_in_current_deck_needs_trace_policy` |
| `tutors_access` | `Vampiric Tutor` | true | false | true | `external_source_candidate_already_in_current_deck_needs_trace_policy` |
| `tutors_access` | `Diabolic Intent` | true | false | true | `external_source_candidate_already_in_current_deck_needs_trace_policy` |
| `tutors_access` | `Gamble` | false | true | true | `external_source_candidate_already_selected_as_add_needs_pair_policy` |

## Blockers

- `named_external_candidates_are_not_cut_permission`
- `current_deck_present_candidates_need_trace_policy_before_cut_consideration`
- `outside_deck_candidates_need_local_source_lane_review_before_miner`
- `candidate_copy_closed_until_value_safe_same_lane_pair_exists`

## Policy

- candidate_boundary: Named external candidates are source-lane evidence, not card-level cut permission.
- current_deck_boundary: Candidates already in the current deck need trace/negative-review policy before any cut consideration.
- outside_deck_boundary: Candidates outside the current deck can inform future add/source lanes, but do not solve current cuts.
- battle_boundary: No battle gate opens before candidate copy and relevant card-level usage evidence.
