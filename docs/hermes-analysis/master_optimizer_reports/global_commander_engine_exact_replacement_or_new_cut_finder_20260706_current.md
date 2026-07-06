# Global Commander Engine Exact Replacement Or New Cut Finder

- generated_at: `2026-07-06T04:54:22.420626+00:00`
- status: `engine_exact_replacement_found_needs_source_trace`
- commander: `Kaalia of the Vast`
- deck_id: `619`
- replacement_candidate_scanned_count: `12`
- exact_replacement_ready_count: `5`
- engine_cut_row_count: `8`
- new_unblocked_engine_cut_count: `0`
- candidate_copy_allowed_now: `false`
- battle_gate_allowed_now: `false`
- promotion_allowed: `false`
- next_gate: `source_trace_exact_engine_replacement_before_candidate_copy`

## Replacement Candidates

| Card | Status | Signals | Color | Legality | Blockers |
| --- | --- | --- | --- | --- | --- |
| `Digsite Engineer` | `exact_replacement_candidate_ready_for_source_trace` | `artifact_spell_token_payoff` | `W` | `legal` | - |
| `Golem Foundry` | `exact_replacement_candidate_ready_for_source_trace` | `artifact_spell_token_payoff` | `` | `legal` | - |
| `Myrsmith` | `exact_replacement_candidate_ready_for_source_trace` | `artifact_spell_token_payoff` | `W` | `legal` | - |
| `Poetic Ingenuity` | `exact_replacement_candidate_ready_for_source_trace` | `artifact_spell_token_payoff` | `R` | `legal` | - |
| `Ravenous Robots` | `exact_replacement_candidate_ready_for_source_trace` | `artifact_spell_token_payoff` | `R` | `legal` | - |
| `Etherium Sculptor` | `artifact_spell_support_not_biotransference_replacement` | `artifact_spell_cost_reducer` | `U` | `legal` | outside_commander_color_identity, support_only_no_token_or_draw_payoff |
| `Sai, Master Thopterist` | `exact_artifact_spell_payoff_candidate` | `artifact_spell_draw_payoff,artifact_spell_token_payoff` | `U` | `legal` | outside_commander_color_identity |
| `Biotransference` | `exact_type_conversion_engine_candidate` | `artifact_spell_token_payoff,artifact_type_conversion_engine` | `B` | `legal` | already_in_current_deck |
| `Forensic Gadgeteer` | `exact_artifact_spell_payoff_candidate` | `artifact_spell_cost_reducer,artifact_spell_draw_payoff,artifact_spell_token_payoff` | `U` | `legal` | outside_commander_color_identity |
| `Locket of Yesterdays` | `artifact_spell_support_not_biotransference_replacement` | `artifact_spell_cost_reducer` | `` | `legal` | support_only_no_token_or_draw_payoff |
| `Uthros Research Craft` | `exact_artifact_spell_payoff_candidate` | `artifact_spell_draw_payoff` | `U` | `legal` | outside_commander_color_identity |
| `Vedalken Archmage` | `exact_artifact_spell_payoff_candidate` | `artifact_spell_draw_payoff` | `U` | `legal` | outside_commander_color_identity |

## New Engine Cut Rows

| Card | Status | Policy Bucket | Signals | Blockers |
| --- | --- | --- | --- | --- |
| `Archaeomancer's Map` | `already_reviewed_engine_cut_not_new_source` | `engine_overlap_excess_cut_pressure` | `` | - |
| `Biotransference` | `already_reviewed_engine_cut_not_new_source` | `engine_only_excess_cut_pressure` | `` | - |
| `Ardenn, Intrepid Archaeologist` | `new_engine_cut_blocked_by_commander_plan_signal` | `protected_engine_cut_pressure` | `kaalia_equipment_support_package` | engine_card_has_commander_plan_signal:kaalia_equipment_support_package |
| `Delney, Streetwise Lookout` | `new_engine_cut_blocked_by_commander_plan_signal` | `protected_engine_cut_pressure` | `kaalia_trigger_or_type_enabler` | engine_card_has_commander_plan_signal:kaalia_trigger_or_type_enabler |
| `Genji Glove` | `new_engine_cut_blocked_by_commander_plan_signal` | `protected_engine_cut_pressure` | `kaalia_attack_window_or_extra_combat,kaalia_equipment_support_package` | engine_card_has_commander_plan_signal:kaalia_attack_window_or_extra_combat,kaalia_equipment_support_package |
| `Karlach, Fury of Avernus` | `new_engine_cut_blocked_by_commander_plan_signal` | `protected_engine_cut_pressure` | `kaalia_attack_window_or_extra_combat` | engine_card_has_commander_plan_signal:kaalia_attack_window_or_extra_combat |
| `Maskwood Nexus` | `new_engine_cut_blocked_by_commander_plan_signal` | `protected_engine_cut_pressure` | `kaalia_trigger_or_type_enabler` | engine_card_has_commander_plan_signal:kaalia_trigger_or_type_enabler |
| `Sigarda's Aid` | `new_engine_cut_blocked_by_commander_plan_signal` | `protected_engine_cut_pressure` | `kaalia_equipment_support_package` | engine_card_has_commander_plan_signal:kaalia_equipment_support_package |

## Blockers

- `no_new_unblocked_engine_cut_source`
- `candidate_copy_closed_after_exact_replacement_or_new_cut_finder`

## Policy

- exact_replacement_boundary: Biotransference replacement requires artifact-spell payoff or artifact type-conversion, not generic artifact adjacency.
- new_cut_boundary: Protected commander-plan engines are not new cut sources without source-lane evidence.
- cache_boundary: This report searches local Hermes card_oracle_cache and commander legality cache only; external source expansion is a separate gate.
- mutation_boundary: This finder reads SQLite and report artifacts only.
