# Battle Decision Trace Taxonomy Audit

- Generated at UTC: `2026-06-24T22:36:25Z`
- Status: `decision_trace_taxonomy_ready`
- Engine source: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/manaloom-knowledge/scripts/battle_analyst_v9.py`
- Decision trace paths: `["/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260624_221826/seed_61592400/replay.decision_trace.jsonl", "/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260624_221826/seed_61592401/replay.decision_trace.jsonl", "/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260624_221826/seed_61592402/replay.decision_trace.jsonl", "/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260624_221826/seed_61592403/replay.decision_trace.jsonl", "/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260624_221826/seed_61592404/replay.decision_trace.jsonl", "/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260624_221826/seed_61592405/replay.decision_trace.jsonl", "/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260624_221826/seed_61592406/replay.decision_trace.jsonl", "/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260624_221826/seed_61592407/replay.decision_trace.jsonl", "/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260624_221826/seed_61592408/replay.decision_trace.jsonl", "/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260624_221826/seed_61592409/replay.decision_trace.jsonl", "/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260624_221826/seed_61592410/replay.decision_trace.jsonl", "/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260624_221826/seed_61592411/replay.decision_trace.jsonl", "/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260624_221826/seed_61592412/replay.decision_trace.jsonl", "/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260624_221826/seed_61592413/replay.decision_trace.jsonl", "/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260624_221826/seed_61592414/replay.decision_trace.jsonl", "/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260624_221826/seed_61592415/replay.decision_trace.jsonl"]`
- Decision rows: `2132`
- Static decision types: `18`
- Observed decision types: `11`
- Uncovered static decision types: `7`
- Contract findings: `0`
- Missing required fields: `0`
- Static without contract: `0`
- Observed without contract: `0`
- Static without specific contract: `0`
- Observed without specific contract: `0`
- Accepted waivers: `["activated_sacrifice_damage", "activated_self_counter_growth", "attack_trigger_artifact_tutor", "land_tax_upkeep_tutor", "lorehold_upkeep_rummage", "saga_chapter_resolution", "utility_artifact_activation", "utility_creature_activation", "utility_land_activation"]`

## Ownership Matrix

| Decision type | Latest count | Owner | Strategy auditor | Research category | Specific status | Fixture/gate | Score keys observed |
| --- | ---: | --- | --- | --- | --- | --- | --- |
| `activated_sacrifice_damage` | `0` | `activated-sacrifice-damage-field-contract` | `generic_strategy_fields_only` | `-` | `accepted_field_contract_waiver` | `field_contract_required_before_observed_learning` | `-` |
| `activated_self_counter_growth` | `0` | `activated-self-counter-growth-field-contract` | `generic_strategy_fields_only` | `-` | `accepted_field_contract_waiver` | `field_contract_required_before_observed_learning` | `-` |
| `attack_trigger_artifact_tutor` | `0` | `attack-trigger-artifact-tutor-field-contract` | `generic_strategy_fields_only` | `-` | `accepted_field_contract_waiver` | `field_contract_required_before_observed_learning` | `-` |
| `board_wipe` | `0` | `battle_decision_strategy_auditor.py` | `generic_strategy_fields_plus_specialized_rules` | `board_wipe_wheel` | `specific` | `test_battle_decision_strategy_auditor.py` | `-` |
| `cast_spell` | `622` | `battle_decision_strategy_auditor.py` | `generic_strategy_fields_plus_specialized_rules` | `cast_spell` | `specific` | `test_battle_decision_strategy_auditor.py` | `castable_count, cmc, commander_tax, effective_cost, mana_after_payment, mana_before, multikicker_count, ramp_options, remaining_options, requires_discard_land, requires_imprint_nonartifact_nonland, requires_sacrifice_land, resource_gate, role, strategic_benefit_reason, threat_score, unlock_card, unlock_reason, unlock_role, unlocks_same_turn_action` |
| `combat_attack` | `266` | `battle_decision_research_review.py` | `generic_strategy_fields_only` | `combat_attack` | `specific_via_research` | `test_battle_decision_research_review.py` | `attack_restrictions, attackers, evaluation_target_active, evaluation_target_player, multi_defender_available, reserved_attackers_for_self_preservation, table_intent_enabled, table_intent_options, target_life_before, target_reason, total_power` |
| `land_tax_upkeep_tutor` | `6` | `land-tax-upkeep-tutor-field-contract` | `generic_strategy_fields_only` | `-` | `accepted_field_contract_waiver` | `field_contract_required_before_observed_learning` | `candidate_count, max_count, max_opponent_land_count, opponent_land_counts, player_land_count, reveals, selected_count, shuffle_after` |
| `lorehold_upkeep_rummage` | `23` | `lorehold-upkeep-rummage-field-contract` | `generic_strategy_fields_only` | `-` | `accepted_field_contract_waiver` | `field_contract_required_before_observed_learning` | `discard_destination, drawn_card, miracle_cost` |
| `mulligan_decision` | `104` | `battle_decision_strategy_auditor.py` | `generic_strategy_fields_plus_specialized_rules` | `mulligan` | `specific` | `test_battle_decision_strategy_auditor.py` | `card_flow_count, colors, early_play, early_ramp, early_turn_window, high_cost_cards, high_cost_cluster_count, keep, lands, nonlands, off_color_early_cards, off_color_early_count, plan_role, proactive_board_count, reactive_only_count` |
| `pass_no_action` | `960` | `battle_decision_strategy_auditor.py` | `generic_strategy_fields_plus_specialized_rules` | `pass_no_action` | `specific` | `test_battle_decision_strategy_auditor.py` | `affordable_card_count, available_mana, castable_now_count, hand_nonland_count, main_phase_action_taken, minimum_hand_cmc, phase_is_main, reactive_option_count, stack_empty` |
| `response` | `38` | `battle_decision_research_review.py` | `generic_strategy_fields_only` | `response` | `specific_via_research` | `test_battle_decision_research_review.py` | `attackers, available_counters, available_instants, available_responses, copyable_stack_target, counter_worth, kicker_paid, life_before_damage, projected_combat_damage, redirectable_stack_target, stack_threat_score, targeted_attacker` |
| `saga_chapter_resolution` | `4` | `saga-chapter-resolution-field-contract` | `generic_strategy_fields_only` | `-` | `accepted_field_contract_waiver` | `field_contract_required_before_observed_learning` | `candidate_count, chapter, selected_reason` |
| `tutor` | `50` | `battle_decision_strategy_auditor.py` | `generic_strategy_fields_plus_specialized_rules` | `tutor` | `specific` | `test_battle_decision_strategy_auditor.py` | `candidate_count, lands, opponent_creatures, selected_reason, selection_count, target_type` |
| `utility_artifact_activation` | `51` | `utility-artifact-activation-field-contract` | `generic_strategy_fields_only` | `-` | `accepted_field_contract_waiver` | `field_contract_required_before_observed_learning` | `activation_cost, activation_cost_generic, bonus_mana, burden_counters_after, burden_counters_before, candidate_count, cards_drawn, cards_exchanged, creature_cost, current_lands, found_land, hand_after, hand_before, hand_to_top, life_cost, miracle_cost, peek_top_count, return_land, selected_card, target_count, target_lands, target_type, top_after, top_before, unlock_target` |
| `utility_creature_activation` | `0` | `utility-creature-activation-field-contract` | `generic_strategy_fields_only` | `-` | `accepted_field_contract_waiver` | `field_contract_required_before_observed_learning` | `-` |
| `utility_land_activation` | `8` | `utility-land-activation-field-contract` | `generic_strategy_fields_only` | `-` | `accepted_field_contract_waiver` | `field_contract_required_before_observed_learning` | `artifact_count, artifact_count_after, artifact_threshold_bonus, candidate_count, chapter, chosen_unlock_reason, flood_relief_bonus, hand_low_bonus, land_loss_penalty, life_before, mana_after, mana_before, mana_spend_penalty, selected_reason` |
| `wheel` | `0` | `battle_decision_strategy_auditor.py` | `generic_strategy_fields_plus_specialized_rules` | `board_wipe_wheel` | `specific` | `test_battle_decision_strategy_auditor.py` | `-` |
| `worldfire_reset` | `0` | `battle_decision_strategy_auditor.py` | `generic_strategy_fields_plus_specialized_rules` | `-` | `specific` | `test_battle_decision_strategy_auditor.py` | `-` |

## Accepted Waivers

- `activated_sacrifice_damage`: Deterministic activated damage outlet; strategy trust is bounded by target/damage/creature-options trace fields until a dedicated research category is justified.
- `activated_self_counter_growth`: Self-counter sacrifice outlet is a deterministic board conversion; the trace must expose counter gain, sacrificed permanent, and resulting outlet stats before it can be used as learning evidence.
- `attack_trigger_artifact_tutor`: Triggered artifact tutor is narrow and non-optional quality is captured by treasures/candidate-count plus chosen tutor option.
- `land_tax_upkeep_tutor`: Land Tax upkeep tutor is deterministic card-advantage bookkeeping; the trace must expose land-count condition, candidate count, selected count, max count, reveal policy, and shuffle policy.
- `lorehold_upkeep_rummage`: Lorehold upkeep rummage is commander-engine bookkeeping; the trace must expose discard destination and drawn card, while broader strategic quality remains covered by parent engine choices.
- `saga_chapter_resolution`: Saga chapter resolution is deterministic trigger resolution; the specific contract is chapter, candidate count, and selected reason.
- `utility_artifact_activation`: Utility artifact activations are narrow deterministic resource conversions; each observed row must expose an activation-cost or activation-family score key before it can be used as trace evidence.
- `utility_creature_activation`: Utility creature activations cover deterministic tutor/token/mana conversions; each observed row must expose the activation family through concrete score keys before it can feed learning.
- `utility_land_activation`: Utility land activations are deterministic resource conversions; each row must expose an activation-family score key.

## Findings

- No taxonomy contract findings.
