# Battle Event Contract Static Audit

- Generated at UTC: `2026-06-24T04:32:02Z`
- Status: `review_required`
- Engine source: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/manaloom-knowledge/scripts/battle_analyst_v9.py`
- Static engine sources: `["/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/manaloom-knowledge/scripts/battle_analyst_v9.py", "/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/manaloom-knowledge/scripts/battle_sba_support.py", "/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/manaloom-knowledge/scripts/battle_replacement_support.py", "/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/manaloom-knowledge/scripts/battle_zone_transition_support.py"]`
- Event paths: `["/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260624_042318/seed_63250423/replay.events.jsonl", "/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260624_042318/seed_63250424/replay.events.jsonl", "/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260624_042318/seed_63250425/replay.events.jsonl", "/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260624_042318/seed_63250426/replay.events.jsonl", "/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260624_042318/seed_63250427/replay.events.jsonl", "/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260624_042318/seed_63250428/replay.events.jsonl", "/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260624_042318/seed_63250429/replay.events.jsonl", "/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260624_042318/seed_63250430/replay.events.jsonl", "/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260624_042318/seed_63250431/replay.events.jsonl", "/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260624_042318/seed_63250432/replay.events.jsonl", "/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260624_042318/seed_63250433/replay.events.jsonl", "/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260624_042318/seed_63250434/replay.events.jsonl", "/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260624_042318/seed_63250435/replay.events.jsonl", "/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260624_042318/seed_63250436/replay.events.jsonl", "/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260624_042318/seed_63250437/replay.events.jsonl", "/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260624_042318/seed_63250438/replay.events.jsonl"]`
- Observed events: `14931`
- Observed event types: `83`
- Static event types: `152`
- Static unclassified total: `8`
- Observed unclassified total: `0`
- Observed missing required fields: `0`
- Fixture/waiver counts: `{"observed_in_latest": 83, "static_contract_accepted_waiver": 61, "static_contract_waiver_until_forced_fixture": 8}`
- Static fixture accepted waiver total: `61`
- Static contract waiver until forced fixture: `8`
- Static fixture accepted waiver reasons: `{"accepted_explicitly_ignored_event_contract": 6, "accepted_forensic_card_event_static_contract_until_observed": 2, "accepted_renderer_only_event_no_guardrail_consumer": 7, "accepted_strategy_context_signal_static_contract": 39, "accepted_technical_ledger_event_no_forced_replay_required": 7}`
- Static fixture unaccepted types: `["discard_modal_trigger_resolved", "etb_recursion_resolved", "etb_removal_resolved", "etb_removal_skipped", "powerbalance_trigger_resolved", "steal_all_creatures_resolved", "surge_to_victory_resolved", "tokens_created"]`
- Static class counts: `{"action_audited": 26, "forensic_card_event": 2, "ignored_with_reason": 13, "renderer_only": 15, "strategy_signal": 73, "technical": 15, "unclassified": 8}`
- Observed type class counts: `{"action_audited": 26, "ignored_with_reason": 7, "renderer_only": 8, "strategy_signal": 34, "technical": 8}`
- Observed event class counts: `{"action_audited": 6594, "ignored_with_reason": 420, "renderer_only": 48, "strategy_signal": 215, "technical": 7654}`
- Observed not static literal: `[]`

## Event Contract Matrix

| Event | Static | Observed | Class | Consumer | Minimum fields | Fixture/waiver | Reason |
| --- | --- | ---: | --- | --- | --- | --- | --- |
| `activated_ability` | `yes` | `9` | `strategy_signal` | `decision_strategy_or_replay_context` | `event, turn` | `observed_in_latest` | `-` |
| `activated_ability_skipped` | `yes` | `255` | `ignored_with_reason` | `skip_guardrail_or_state_cleanup` | `event` | `observed_in_latest` | `-` |
| `additional_cost_failed` | `yes` | `3` | `action_audited` | `battle_action_critic.py` | `event, turn` | `observed_in_latest` | `-` |
| `additional_cost_paid` | `yes` | `36` | `technical` | `structured_replay_ledger` | `event` | `observed_in_latest` | `-` |
| `adventure_cast` | `yes` | `0` | `strategy_signal` | `decision_strategy_or_replay_context` | `event, turn` | `static_contract_accepted_waiver` | `accepted_strategy_context_signal_static_contract` |
| `adventure_creature_cast_from_exile` | `yes` | `0` | `strategy_signal` | `decision_strategy_or_replay_context` | `event, turn` | `static_contract_accepted_waiver` | `accepted_strategy_context_signal_static_contract` |
| `adventure_exiled` | `yes` | `0` | `technical` | `structured_replay_ledger` | `event` | `static_contract_accepted_waiver` | `accepted_technical_ledger_event_no_forced_replay_required` |
| `aetherflux_reservoir_resolved` | `yes` | `3` | `strategy_signal` | `decision_strategy_or_replay_context` | `event, turn` | `observed_in_latest` | `-` |
| `airbend_creature_cast_from_exile` | `yes` | `0` | `strategy_signal` | `decision_strategy_or_replay_context` | `event, turn` | `static_contract_accepted_waiver` | `accepted_strategy_context_signal_static_contract` |
| `airbend_other_creatures_resolved` | `yes` | `0` | `strategy_signal` | `decision_strategy_or_replay_context` | `event, turn` | `static_contract_accepted_waiver` | `accepted_strategy_context_signal_static_contract` |
| `approach_cast_tracked` | `yes` | `6` | `strategy_signal` | `decision_strategy_or_replay_context` | `event, turn` | `observed_in_latest` | `-` |
| `approach_first_resolution` | `yes` | `4` | `strategy_signal` | `decision_strategy_or_replay_context` | `event, turn` | `observed_in_latest` | `-` |
| `attachment_sba` | `yes` | `2` | `ignored_with_reason` | `skip_guardrail_or_state_cleanup` | `event` | `observed_in_latest` | `-` |
| `attack_prevented_by_orims_chant` | `yes` | `0` | `strategy_signal` | `decision_strategy_or_replay_context` | `event, turn` | `static_contract_accepted_waiver` | `accepted_strategy_context_signal_static_contract` |
| `battle_back_face_cast` | `yes` | `0` | `strategy_signal` | `decision_strategy_or_replay_context` | `event, turn` | `static_contract_accepted_waiver` | `accepted_strategy_context_signal_static_contract` |
| `battle_damage` | `yes` | `0` | `renderer_only` | `battle_replay_v10_3.py` | `event` | `static_contract_accepted_waiver` | `accepted_renderer_only_event_no_guardrail_consumer` |
| `board_wipe_resolved` | `yes` | `0` | `strategy_signal` | `decision_strategy_or_replay_context` | `event, turn` | `static_contract_accepted_waiver` | `accepted_strategy_context_signal_static_contract` |
| `cannot_lose_turn_resolved` | `yes` | `0` | `strategy_signal` | `decision_strategy_or_replay_context` | `event, turn` | `static_contract_accepted_waiver` | `accepted_strategy_context_signal_static_contract` |
| `cantrip_mana_filter_artifact_resolved` | `yes` | `0` | `strategy_signal` | `decision_strategy_or_replay_context` | `event, turn` | `static_contract_accepted_waiver` | `accepted_strategy_context_signal_static_contract` |
| `cast_announced` | `yes` | `730` | `technical` | `structured_replay_ledger` | `event` | `observed_in_latest` | `-` |
| `cast_illegal` | `yes` | `4` | `technical` | `structured_replay_ledger` | `event` | `observed_in_latest` | `-` |
| `chaos_warp_reveal_resolved` | `yes` | `5` | `strategy_signal` | `decision_strategy_or_replay_context` | `event, turn` | `observed_in_latest` | `-` |
| `combat` | `yes` | `314` | `action_audited` | `battle_action_critic.py` | `event, turn` | `observed_in_latest` | `-` |
| `combat_result` | `yes` | `351` | `action_audited` | `battle_action_critic.py` | `event, turn` | `observed_in_latest` | `-` |
| `combat_step` | `yes` | `1904` | `action_audited` | `battle_action_critic.py` | `event, turn` | `observed_in_latest` | `-` |
| `commander_cast` | `yes` | `98` | `action_audited` | `battle_action_critic.py` | `event, turn` | `observed_in_latest` | `-` |
| `compensation_tokens_created` | `yes` | `3` | `renderer_only` | `battle_replay_v10_3.py` | `event` | `observed_in_latest` | `-` |
| `composite_rule_component_resolved` | `yes` | `0` | `strategy_signal` | `decision_strategy_or_replay_context` | `event, turn` | `static_contract_accepted_waiver` | `accepted_strategy_context_signal_static_contract` |
| `composite_rule_resolved` | `yes` | `0` | `strategy_signal` | `decision_strategy_or_replay_context` | `event, turn` | `static_contract_accepted_waiver` | `accepted_strategy_context_signal_static_contract` |
| `copy_creature_token_created` | `yes` | `21` | `renderer_only` | `battle_replay_v10_3.py` | `event` | `observed_in_latest` | `-` |
| `copy_creature_token_failed` | `yes` | `3` | `ignored_with_reason` | `skip_guardrail_or_state_cleanup` | `event` | `observed_in_latest` | `-` |
| `copy_spell_no_stack_target` | `yes` | `2` | `ignored_with_reason` | `skip_guardrail_or_state_cleanup` | `event` | `observed_in_latest` | `-` |
| `cost_paid` | `yes` | `726` | `action_audited` | `battle_action_critic.py` | `event, turn` | `observed_in_latest` | `-` |
| `counters_cancelled` | `yes` | `0` | `ignored_with_reason` | `skip_guardrail_or_state_cleanup` | `event` | `static_contract_accepted_waiver` | `accepted_explicitly_ignored_event_contract` |
| `creature_cast` | `yes` | `181` | `action_audited` | `battle_action_critic.py` | `event, turn` | `observed_in_latest` | `-` |
| `creature_to_battlefield` | `yes` | `2` | `renderer_only` | `battle_replay_v10_3.py` | `event` | `observed_in_latest` | `-` |
| `damage_resolved` | `yes` | `7` | `renderer_only` | `battle_replay_v10_3.py` | `event` | `observed_in_latest` | `-` |
| `damage_wipe_resolved` | `yes` | `1` | `strategy_signal` | `decision_strategy_or_replay_context` | `event, turn` | `observed_in_latest` | `-` |
| `damage_wipe_treasure_resolved` | `yes` | `0` | `strategy_signal` | `decision_strategy_or_replay_context` | `event, turn` | `static_contract_accepted_waiver` | `accepted_strategy_context_signal_static_contract` |
| `demonstrate_resolved` | `yes` | `0` | `strategy_signal` | `decision_strategy_or_replay_context` | `event, turn` | `static_contract_accepted_waiver` | `accepted_strategy_context_signal_static_contract` |
| `discard_modal_trigger_resolved` | `yes` | `0` | `unclassified` | `-` | `event` | `static_contract_waiver_until_forced_fixture` | `unclassified_or_missing_accepted_fixture_waiver` |
| `dragons_approach_dragon_tutored` | `yes` | `0` | `strategy_signal` | `decision_strategy_or_replay_context` | `event, turn` | `static_contract_accepted_waiver` | `accepted_strategy_context_signal_static_contract` |
| `dragons_approach_resolved` | `yes` | `0` | `strategy_signal` | `decision_strategy_or_replay_context` | `event, turn` | `static_contract_accepted_waiver` | `accepted_strategy_context_signal_static_contract` |
| `draw_cards_resolved` | `yes` | `14` | `strategy_signal` | `decision_strategy_or_replay_context` | `event, turn` | `observed_in_latest` | `-` |
| `draw_equal_to_discarded_hand_resolved` | `yes` | `1` | `strategy_signal` | `decision_strategy_or_replay_context` | `event, turn` | `observed_in_latest` | `-` |
| `end_step_instant` | `yes` | `11` | `action_audited` | `battle_action_critic.py` | `event, turn` | `observed_in_latest` | `-` |
| `end_step_token_death_draw_resolved` | `yes` | `1` | `technical` | `structured_replay_ledger` | `event` | `observed_in_latest` | `-` |
| `end_step_token_exiled` | `yes` | `5` | `renderer_only` | `battle_replay_v10_3.py` | `event` | `observed_in_latest` | `-` |
| `end_step_token_sacrificed` | `yes` | `3` | `renderer_only` | `battle_replay_v10_3.py` | `event` | `observed_in_latest` | `-` |
| `equipment_attached` | `yes` | `3` | `renderer_only` | `battle_replay_v10_3.py` | `event` | `observed_in_latest` | `-` |
| `equipment_unattached` | `yes` | `0` | `renderer_only` | `battle_replay_v10_3.py` | `event` | `static_contract_accepted_waiver` | `accepted_renderer_only_event_no_guardrail_consumer` |
| `etb_recursion_resolved` | `yes` | `0` | `unclassified` | `-` | `event` | `static_contract_waiver_until_forced_fixture` | `unclassified_or_missing_accepted_fixture_waiver` |
| `etb_removal_resolved` | `yes` | `0` | `unclassified` | `-` | `event` | `static_contract_waiver_until_forced_fixture` | `unclassified_or_missing_accepted_fixture_waiver` |
| `etb_removal_skipped` | `yes` | `0` | `unclassified` | `-` | `event` | `static_contract_waiver_until_forced_fixture` | `unclassified_or_missing_accepted_fixture_waiver` |
| `etb_tutor_resolved` | `yes` | `0` | `strategy_signal` | `decision_strategy_or_replay_context` | `event, turn` | `static_contract_accepted_waiver` | `accepted_strategy_context_signal_static_contract` |
| `extra_combat_cap_reached` | `yes` | `0` | `ignored_with_reason` | `skip_guardrail_or_state_cleanup` | `event` | `static_contract_accepted_waiver` | `accepted_explicitly_ignored_event_contract` |
| `extra_combat_scheduled` | `yes` | `0` | `strategy_signal` | `decision_strategy_or_replay_context` | `event, turn` | `static_contract_accepted_waiver` | `accepted_strategy_context_signal_static_contract` |
| `extra_combat_taken` | `yes` | `0` | `strategy_signal` | `decision_strategy_or_replay_context` | `event, turn` | `static_contract_accepted_waiver` | `accepted_strategy_context_signal_static_contract` |
| `extra_turn_cap_reached` | `yes` | `0` | `ignored_with_reason` | `skip_guardrail_or_state_cleanup` | `event` | `static_contract_accepted_waiver` | `accepted_explicitly_ignored_event_contract` |
| `extra_turn_scheduled` | `yes` | `3` | `strategy_signal` | `decision_strategy_or_replay_context` | `event, turn` | `observed_in_latest` | `-` |
| `extra_turn_taken` | `yes` | `0` | `strategy_signal` | `decision_strategy_or_replay_context` | `event, turn` | `static_contract_accepted_waiver` | `accepted_strategy_context_signal_static_contract` |
| `flashback_cast` | `yes` | `1` | `action_audited` | `battle_action_critic.py` | `event, turn` | `observed_in_latest` | `-` |
| `flashback_exiled` | `yes` | `0` | `technical` | `structured_replay_ledger` | `event` | `static_contract_accepted_waiver` | `accepted_technical_ledger_event_no_forced_replay_required` |
| `game_lost` | `yes` | `0` | `strategy_signal` | `decision_strategy_or_replay_context` | `event, turn` | `static_contract_accepted_waiver` | `accepted_strategy_context_signal_static_contract` |
| `game_win_prevented` | `yes` | `0` | `strategy_signal` | `decision_strategy_or_replay_context` | `event, turn` | `static_contract_accepted_waiver` | `accepted_strategy_context_signal_static_contract` |
| `game_won` | `yes` | `16` | `action_audited` | `battle_action_critic.py` | `event, turn` | `observed_in_latest` | `-` |
| `graveyard_flashback_granted` | `yes` | `1` | `strategy_signal` | `decision_strategy_or_replay_context` | `event, turn` | `observed_in_latest` | `-` |
| `hand_filter_resolved` | `yes` | `3` | `strategy_signal` | `decision_strategy_or_replay_context` | `event, turn` | `observed_in_latest` | `-` |
| `hate_artifact_resolved` | `yes` | `2` | `strategy_signal` | `decision_strategy_or_replay_context` | `event, turn` | `observed_in_latest` | `-` |
| `imprint_failed` | `yes` | `0` | `ignored_with_reason` | `skip_guardrail_or_state_cleanup` | `event` | `static_contract_accepted_waiver` | `accepted_explicitly_ignored_event_contract` |
| `imprint_resolved` | `yes` | `8` | `strategy_signal` | `decision_strategy_or_replay_context` | `event, turn` | `observed_in_latest` | `-` |
| `instant_removal` | `yes` | `0` | `forensic_card_event` | `battle_forensic_audit.py` | `event, turn` | `static_contract_accepted_waiver` | `accepted_forensic_card_event_static_contract_until_observed` |
| `jeskas_will_resolved` | `yes` | `4` | `strategy_signal` | `decision_strategy_or_replay_context` | `event, turn` | `observed_in_latest` | `-` |
| `land_played` | `yes` | `375` | `action_audited` | `battle_action_critic.py` | `event, turn` | `observed_in_latest` | `-` |
| `land_ramp_resolved` | `yes` | `8` | `strategy_signal` | `decision_strategy_or_replay_context` | `event, turn` | `observed_in_latest` | `-` |
| `land_recursion_creature_resolved` | `yes` | `0` | `strategy_signal` | `decision_strategy_or_replay_context` | `event, turn` | `static_contract_accepted_waiver` | `accepted_strategy_context_signal_static_contract` |
| `land_recursion_resolved` | `yes` | `0` | `strategy_signal` | `decision_strategy_or_replay_context` | `event, turn` | `static_contract_accepted_waiver` | `accepted_strategy_context_signal_static_contract` |
| `land_tax_trigger_resolved` | `yes` | `0` | `strategy_signal` | `decision_strategy_or_replay_context` | `event, turn` | `static_contract_accepted_waiver` | `accepted_strategy_context_signal_static_contract` |
| `land_tax_trigger_skipped` | `yes` | `13` | `ignored_with_reason` | `skip_guardrail_or_state_cleanup` | `event` | `observed_in_latest` | `-` |
| `lander_token_created` | `yes` | `0` | `renderer_only` | `battle_replay_v10_3.py` | `event` | `static_contract_accepted_waiver` | `accepted_renderer_only_event_no_guardrail_consumer` |
| `life_artifact_resolved` | `yes` | `0` | `strategy_signal` | `decision_strategy_or_replay_context` | `event, turn` | `static_contract_accepted_waiver` | `accepted_strategy_context_signal_static_contract` |
| `life_totals_redistributed` | `yes` | `0` | `strategy_signal` | `decision_strategy_or_replay_context` | `event, turn` | `static_contract_accepted_waiver` | `accepted_strategy_context_signal_static_contract` |
| `loot_resolved` | `yes` | `6` | `strategy_signal` | `decision_strategy_or_replay_context` | `event, turn` | `observed_in_latest` | `-` |
| `lorehold_upkeep_rummage` | `yes` | `38` | `strategy_signal` | `decision_strategy_or_replay_context` | `event, turn` | `observed_in_latest` | `-` |
| `lorehold_upkeep_rummage_skipped` | `yes` | `143` | `ignored_with_reason` | `skip_guardrail_or_state_cleanup` | `event` | `observed_in_latest` | `-` |
| `loyalty_ability_activated` | `yes` | `0` | `strategy_signal` | `decision_strategy_or_replay_context` | `event, turn` | `static_contract_accepted_waiver` | `accepted_strategy_context_signal_static_contract` |
| `mana_refreshed` | `yes` | `606` | `technical` | `structured_replay_ledger` | `event` | `observed_in_latest` | `-` |
| `mill_resolved` | `yes` | `0` | `strategy_signal` | `decision_strategy_or_replay_context` | `event, turn` | `static_contract_accepted_waiver` | `accepted_strategy_context_signal_static_contract` |
| `miracle_cast` | `yes` | `16` | `action_audited` | `battle_action_critic.py` | `event, turn` | `observed_in_latest` | `-` |
| `mizzix_mastery_copy_cast` | `yes` | `3` | `strategy_signal` | `decision_strategy_or_replay_context` | `event, turn` | `observed_in_latest` | `-` |
| `mizzix_mastery_resolved` | `yes` | `3` | `strategy_signal` | `decision_strategy_or_replay_context` | `event, turn` | `observed_in_latest` | `-` |
| `modal_boros_charm_resolved` | `yes` | `1` | `strategy_signal` | `decision_strategy_or_replay_context` | `event, turn` | `observed_in_latest` | `-` |
| `multi_defender_attack` | `yes` | `28` | `action_audited` | `battle_action_critic.py` | `event, turn` | `observed_in_latest` | `-` |
| `multi_target_resolution` | `yes` | `0` | `forensic_card_event` | `battle_forensic_audit.py` | `event, turn` | `static_contract_accepted_waiver` | `accepted_forensic_card_event_static_contract_until_observed` |
| `multikicker_paid` | `yes` | `0` | `technical` | `structured_replay_ledger` | `event` | `static_contract_accepted_waiver` | `accepted_technical_ledger_event_no_forced_replay_required` |
| `one_ring_burden_life_loss` | `yes` | `4` | `strategy_signal` | `decision_strategy_or_replay_context` | `event, turn` | `observed_in_latest` | `-` |
| `paradigm_exiled` | `yes` | `0` | `renderer_only` | `battle_replay_v10_3.py` | `event` | `static_contract_accepted_waiver` | `accepted_renderer_only_event_no_guardrail_consumer` |
| `permanent_moved_by_sba` | `yes` | `0` | `ignored_with_reason` | `skip_guardrail_or_state_cleanup` | `event` | `static_contract_accepted_waiver` | `accepted_explicitly_ignored_event_contract` |
| `phase_creatures_resolved` | `yes` | `0` | `strategy_signal` | `decision_strategy_or_replay_context` | `event, turn` | `static_contract_accepted_waiver` | `accepted_strategy_context_signal_static_contract` |
| `phase_out_resolved` | `yes` | `2` | `strategy_signal` | `decision_strategy_or_replay_context` | `event, turn` | `observed_in_latest` | `-` |
| `planeswalker_damage` | `yes` | `0` | `renderer_only` | `battle_replay_v10_3.py` | `event` | `static_contract_accepted_waiver` | `accepted_renderer_only_event_no_guardrail_consumer` |
| `player_eliminated` | `yes` | `17` | `action_audited` | `battle_action_critic.py` | `event, turn` | `observed_in_latest` | `-` |
| `powerbalance_trigger_resolved` | `yes` | `0` | `unclassified` | `-` | `event` | `static_contract_waiver_until_forced_fixture` | `unclassified_or_missing_accepted_fixture_waiver` |
| `prepared_copies_removed` | `yes` | `0` | `technical` | `structured_replay_ledger` | `event` | `static_contract_accepted_waiver` | `accepted_technical_ledger_event_no_forced_replay_required` |
| `prepared_copy_created` | `yes` | `0` | `renderer_only` | `battle_replay_v10_3.py` | `event` | `static_contract_accepted_waiver` | `accepted_renderer_only_event_no_guardrail_consumer` |
| `priority_pass` | `yes` | `6267` | `technical` | `structured_replay_ledger` | `event` | `observed_in_latest` | `-` |
| `protection_from_everything_granted` | `yes` | `8` | `strategy_signal` | `decision_strategy_or_replay_context` | `event, turn` | `observed_in_latest` | `-` |
| `protection_resolved` | `yes` | `1` | `strategy_signal` | `decision_strategy_or_replay_context` | `event, turn` | `observed_in_latest` | `-` |
| `random_discard_after_tutor` | `yes` | `9` | `strategy_signal` | `decision_strategy_or_replay_context` | `event, turn` | `observed_in_latest` | `-` |
| `recursion_resolved` | `yes` | `9` | `action_audited` | `battle_action_critic.py` | `event, turn` | `observed_in_latest` | `-` |
| `redirect_removal_resolved` | `yes` | `5` | `action_audited` | `battle_action_critic.py` | `event, turn` | `observed_in_latest` | `-` |
| `removal_countered_by_ward` | `yes` | `0` | `strategy_signal` | `decision_strategy_or_replay_context` | `event, turn` | `static_contract_accepted_waiver` | `accepted_strategy_context_signal_static_contract` |
| `removal_resolved` | `yes` | `47` | `action_audited` | `battle_action_critic.py` | `event, turn` | `observed_in_latest` | `-` |
| `replacement_applied` | `yes` | `96` | `action_audited` | `battle_action_critic.py` | `event, turn` | `observed_in_latest` | `-` |
| `ripple_trigger_resolved` | `yes` | `0` | `strategy_signal` | `decision_strategy_or_replay_context` | `event, turn` | `static_contract_accepted_waiver` | `accepted_strategy_context_signal_static_contract` |
| `ritual_mana_added` | `yes` | `10` | `strategy_signal` | `decision_strategy_or_replay_context` | `event, turn` | `observed_in_latest` | `-` |
| `saga_chapter_progressed` | `yes` | `4` | `strategy_signal` | `decision_strategy_or_replay_context` | `event, turn` | `observed_in_latest` | `-` |
| `saga_chapter_resolved` | `yes` | `2` | `strategy_signal` | `decision_strategy_or_replay_context` | `event, turn` | `observed_in_latest` | `-` |
| `saga_sacrificed_by_sba` | `yes` | `2` | `ignored_with_reason` | `skip_guardrail_or_state_cleanup` | `event` | `observed_in_latest` | `-` |
| `self_exiled_on_resolution` | `yes` | `4` | `technical` | `structured_replay_ledger` | `event` | `observed_in_latest` | `-` |
| `spell_cast` | `yes` | `459` | `action_audited` | `battle_action_critic.py` | `event, turn` | `observed_in_latest` | `-` |
| `spell_copied` | `yes` | `4` | `strategy_signal` | `decision_strategy_or_replay_context` | `event, turn` | `observed_in_latest` | `-` |
| `spell_copy_ceased_to_exist` | `yes` | `6` | `technical` | `structured_replay_ledger` | `event` | `observed_in_latest` | `-` |
| `spell_countered` | `yes` | `12` | `action_audited` | `battle_action_critic.py` | `event, turn` | `observed_in_latest` | `-` |
| `spell_resolved` | `yes` | `317` | `action_audited` | `battle_action_critic.py` | `cast_pipeline, destination, event, from_zone, locked_cost, phase, priority_window, resolved_from_stack, result, source_zone, stack_depth, stack_object, to_zone, turn, zone_after` | `observed_in_latest` | `-` |
| `static_enter_tapped_applied` | `yes` | `0` | `technical` | `structured_replay_ledger` | `event` | `static_contract_accepted_waiver` | `accepted_technical_ledger_event_no_forced_replay_required` |
| `station_activated` | `yes` | `0` | `strategy_signal` | `decision_strategy_or_replay_context` | `event, turn` | `static_contract_accepted_waiver` | `accepted_strategy_context_signal_static_contract` |
| `steal_all_creatures_resolved` | `yes` | `0` | `unclassified` | `-` | `event` | `static_contract_waiver_until_forced_fixture` | `unclassified_or_missing_accepted_fixture_waiver` |
| `surge_to_victory_resolved` | `yes` | `0` | `unclassified` | `-` | `event` | `static_contract_waiver_until_forced_fixture` | `unclassified_or_missing_accepted_fixture_waiver` |
| `thassa_oracle_resolved` | `yes` | `0` | `strategy_signal` | `decision_strategy_or_replay_context` | `event, turn` | `static_contract_accepted_waiver` | `accepted_strategy_context_signal_static_contract` |
| `token_ceased_to_exist` | `yes` | `0` | `renderer_only` | `battle_replay_v10_3.py` | `event` | `static_contract_accepted_waiver` | `accepted_renderer_only_event_no_guardrail_consumer` |
| `tokens_created` | `yes` | `0` | `unclassified` | `-` | `event` | `static_contract_waiver_until_forced_fixture` | `unclassified_or_missing_accepted_fixture_waiver` |
| `top_nonland_free_cast` | `yes` | `0` | `strategy_signal` | `decision_strategy_or_replay_context` | `event, turn` | `static_contract_accepted_waiver` | `accepted_strategy_context_signal_static_contract` |
| `top_nonland_free_cast_resolved` | `yes` | `0` | `strategy_signal` | `decision_strategy_or_replay_context` | `event, turn` | `static_contract_accepted_waiver` | `accepted_strategy_context_signal_static_contract` |
| `topdeck_manipulation_activated` | `yes` | `19` | `strategy_signal` | `decision_strategy_or_replay_context` | `event, turn` | `observed_in_latest` | `-` |
| `treasure_created` | `yes` | `4` | `renderer_only` | `battle_replay_v10_3.py` | `event` | `observed_in_latest` | `-` |
| `trigger_put_on_stack` | `yes` | `177` | `action_audited` | `battle_action_critic.py` | `event, turn` | `observed_in_latest` | `-` |
| `trigger_resolved` | `yes` | `179` | `action_audited` | `battle_action_critic.py` | `event, turn` | `observed_in_latest` | `-` |
| `trigger_skipped` | `yes` | `0` | `ignored_with_reason` | `skip_guardrail_or_state_cleanup` | `event` | `static_contract_accepted_waiver` | `accepted_explicitly_ignored_event_contract` |
| `turn_end` | `yes` | `584` | `action_audited` | `battle_action_critic.py` | `event, turn` | `observed_in_latest` | `-` |
| `turn_start` | `yes` | `606` | `action_audited` | `battle_action_critic.py` | `event, turn` | `observed_in_latest` | `-` |
| `tutor_resolved` | `yes` | `62` | `action_audited` | `battle_action_critic.py` | `event, turn` | `observed_in_latest` | `-` |
| `utility_artifact_activated` | `yes` | `6` | `strategy_signal` | `decision_strategy_or_replay_context` | `event, turn` | `observed_in_latest` | `-` |
| `utility_land_activated` | `yes` | `14` | `strategy_signal` | `decision_strategy_or_replay_context` | `event, turn` | `observed_in_latest` | `-` |
| `utility_land_triggered` | `yes` | `2` | `strategy_signal` | `decision_strategy_or_replay_context` | `event, turn` | `observed_in_latest` | `-` |
| `ward_countered` | `yes` | `0` | `strategy_signal` | `decision_strategy_or_replay_context` | `event, turn` | `static_contract_accepted_waiver` | `accepted_strategy_context_signal_static_contract` |
| `ward_paid` | `yes` | `0` | `technical` | `structured_replay_ledger` | `event` | `static_contract_accepted_waiver` | `accepted_technical_ledger_event_no_forced_replay_required` |
| `warp_cast` | `yes` | `0` | `strategy_signal` | `decision_strategy_or_replay_context` | `event, turn` | `static_contract_accepted_waiver` | `accepted_strategy_context_signal_static_contract` |
| `warp_exiled_end_step` | `yes` | `0` | `technical` | `structured_replay_ledger` | `event` | `static_contract_accepted_waiver` | `accepted_technical_ledger_event_no_forced_replay_required` |
| `warp_recast_from_exile` | `yes` | `0` | `strategy_signal` | `decision_strategy_or_replay_context` | `event, turn` | `static_contract_accepted_waiver` | `accepted_strategy_context_signal_static_contract` |
| `wheel_resolved` | `yes` | `7` | `strategy_signal` | `decision_strategy_or_replay_context` | `event, turn` | `observed_in_latest` | `-` |
| `worldfire_resolved` | `yes` | `0` | `strategy_signal` | `decision_strategy_or_replay_context` | `event, turn` | `static_contract_accepted_waiver` | `accepted_strategy_context_signal_static_contract` |

## Field Findings

- No observed event field findings.
