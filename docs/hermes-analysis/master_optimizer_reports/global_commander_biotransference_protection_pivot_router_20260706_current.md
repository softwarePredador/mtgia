# Global Commander Biotransference Protection Pivot Router

- generated_at: `2026-07-06T05:09:19.412224+00:00`
- status: `biotransference_protected_engine_axis_exhausted_pivot_required`
- commander: `Kaalia of the Vast`
- deck_id: `619`
- type_conversion_lane_exhausted: `true`
- biotransference_protected: `true`
- viable_non_biotransference_engine_cut_count: `0`
- candidate_copy_allowed_now: `false`
- battle_gate_allowed_now: `false`
- promotion_allowed: `false`
- next_gate: `return_to_global_role_axis_learning_priority_after_engine_axis_exhaustion`

## Engine Cut Routes

| Card | Status | Route | Policy Bucket | Next Gate | Blockers |
| --- | --- | --- | --- | --- | --- |
| `Archaeomancer's Map` | `non_biotransference_engine_cut_blocked_by_trace_review` | `blocked` | `engine_overlap_excess_cut_pressure` | `do_not_cut_without_new_same_lane_or_trace_evidence` | trace_review_blocks_negative_clearance_equal_score_tutor_candidate, card_was_equal_or_better_tutor_candidate |
| `Biotransference` | `biotransference_protected_no_outside_type_conversion_replacement` | `protect_cut` | `engine_only_excess_cut_pressure` | `exclude_biotransference_from_candidate_copy` | no_outside_artifact_type_conversion_candidate, biotransference_is_current_deck_artifact_type_converter |
| `Genji Glove` | `engine_cut_protected_by_commander_plan_signal` | `blocked` | `protected_engine_cut_pressure` | `keep_commander_plan_engine_protected` | engine_card_has_commander_plan_signal:kaalia_attack_window_or_extra_combat,kaalia_equipment_support_package |
| `Karlach, Fury of Avernus` | `engine_cut_protected_by_commander_plan_signal` | `blocked` | `protected_engine_cut_pressure` | `keep_commander_plan_engine_protected` | engine_card_has_commander_plan_signal:kaalia_attack_window_or_extra_combat |
| `Ardenn, Intrepid Archaeologist` | `engine_cut_protected_by_commander_plan_signal` | `blocked` | `protected_engine_cut_pressure` | `keep_commander_plan_engine_protected` | engine_card_has_commander_plan_signal:kaalia_equipment_support_package |
| `Delney, Streetwise Lookout` | `engine_cut_protected_by_commander_plan_signal` | `blocked` | `protected_engine_cut_pressure` | `keep_commander_plan_engine_protected` | engine_card_has_commander_plan_signal:kaalia_trigger_or_type_enabler |
| `Maskwood Nexus` | `engine_cut_protected_by_commander_plan_signal` | `blocked` | `protected_engine_cut_pressure` | `keep_commander_plan_engine_protected` | engine_card_has_commander_plan_signal:kaalia_trigger_or_type_enabler |
| `Sigarda's Aid` | `engine_cut_protected_by_commander_plan_signal` | `blocked` | `protected_engine_cut_pressure` | `keep_commander_plan_engine_protected` | engine_card_has_commander_plan_signal:kaalia_equipment_support_package |

## Policy

- biotransference_boundary: Biotransference stays protected when it is the only exact artifact type-conversion source.
- non_biotransference_boundary: Other engine cuts still need trace and same-lane proof before pair modeling.
- pivot_boundary: When no engine cut remains viable, return to global role-axis learning instead of forcing same-deck source expansion.
