# Battle Event Contract Static Audit

- Generated at UTC: `2026-06-25T02:36:29Z`
- Status: `event_contract_static_ready`
- Engine source: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/manaloom-knowledge/scripts/battle_analyst_v9.py`
- Static engine sources: `["/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/manaloom-knowledge/scripts/battle_analyst_v9.py", "/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/manaloom-knowledge/scripts/battle_sba_support.py", "/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/manaloom-knowledge/scripts/battle_replacement_support.py", "/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/manaloom-knowledge/scripts/battle_zone_transition_support.py"]`
- Event paths: `["/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260625_022517/seed_61592700/replay.events.jsonl", "/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260625_022517/seed_61592701/replay.events.jsonl", "/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260625_022517/seed_61592702/replay.events.jsonl", "/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260625_022517/seed_61592703/replay.events.jsonl", "/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260625_022517/seed_61592704/replay.events.jsonl", "/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260625_022517/seed_61592705/replay.events.jsonl", "/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260625_022517/seed_61592706/replay.events.jsonl", "/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260625_022517/seed_61592707/replay.events.jsonl", "/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260625_022517/seed_61592708/replay.events.jsonl", "/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260625_022517/seed_61592709/replay.events.jsonl", "/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260625_022517/seed_61592710/replay.events.jsonl", "/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260625_022517/seed_61592711/replay.events.jsonl", "/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260625_022517/seed_61592712/replay.events.jsonl", "/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260625_022517/seed_61592713/replay.events.jsonl", "/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260625_022517/seed_61592714/replay.events.jsonl", "/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260625_022517/seed_61592715/replay.events.jsonl"]`
- Observed events: `16619`
- Observed event types: `90`
- Static event types: `170`
- Static unclassified total: `0`
- Observed unclassified total: `0`
- Observed missing required fields: `0`
- Fixture/waiver counts: `{"observed_in_latest": 90, "static_contract_accepted_waiver": 80}`
- Static fixture accepted waiver total: `80`
- Static contract waiver until forced fixture: `0`
- Static fixture accepted waiver reasons: `{"accepted_action_branch_static_contract_until_natural_or_targeted_regression": 3, "accepted_explicitly_ignored_event_contract": 9, "accepted_forensic_card_event_static_contract_until_observed": 2, "accepted_renderer_only_event_no_guardrail_consumer": 7, "accepted_strategy_context_signal_static_contract": 50, "accepted_technical_ledger_event_no_forced_replay_required": 9}`
- Static fixture unaccepted types: `[]`
- Static class counts: `{"action_audited": 28, "forensic_card_event": 2, "ignored_with_reason": 17, "renderer_only": 16, "strategy_signal": 90, "technical": 17}`
- Observed type class counts: `{"action_audited": 25, "ignored_with_reason": 8, "renderer_only": 9, "strategy_signal": 40, "technical": 8}`
- Observed event class counts: `{"action_audited": 6882, "ignored_with_reason": 576, "renderer_only": 68, "strategy_signal": 300, "technical": 8793}`
- Observed not static literal: `[]`

## Event Contract Matrix

| Event | Static | Observed | Class | Consumer | Minimum fields | Fixture/waiver | Reason |
| --- | --- | ---: | --- | --- | --- | --- | --- |
| `activated_ability` | `yes` | `20` | `strategy_signal` | `decision_strategy_or_replay_context` | `event, turn` | `observed_in_latest` | `-` |
| `activated_ability_skipped` | `yes` | `381` | `ignored_with_reason` | `skip_guardrail_or_state_cleanup` | `event` | `observed_in_latest` | `-` |
| `additional_cost_failed` | `yes` | `0` | `action_audited` | `battle_action_critic.py` | `event, turn` | `static_contract_accepted_waiver` | `accepted_action_branch_static_contract_until_natural_or_targeted_regression` |
| `additional_cost_paid` | `yes` | `35` | `technical` | `structured_replay_ledger` | `event` | `observed_in_latest` | `-` |
| `adventure_cast` | `yes` | `0` | `strategy_signal` | `decision_strategy_or_replay_context` | `event, turn` | `static_contract_accepted_waiver` | `accepted_strategy_context_signal_static_contract` |
| `adventure_creature_cast_from_exile` | `yes` | `0` | `strategy_signal` | `decision_strategy_or_replay_context` | `event, turn` | `static_contract_accepted_waiver` | `accepted_strategy_context_signal_static_contract` |
| `adventure_exiled` | `yes` | `0` | `technical` | `structured_replay_ledger` | `event` | `static_contract_accepted_waiver` | `accepted_technical_ledger_event_no_forced_replay_required` |
| `aetherflux_reservoir_resolved` | `yes` | `3` | `strategy_signal` | `decision_strategy_or_replay_context` | `event, turn` | `observed_in_latest` | `-` |
| `airbend_creature_cast_from_exile` | `yes` | `0` | `strategy_signal` | `decision_strategy_or_replay_context` | `event, turn` | `static_contract_accepted_waiver` | `accepted_strategy_context_signal_static_contract` |
| `airbend_other_creatures_resolved` | `yes` | `0` | `strategy_signal` | `decision_strategy_or_replay_context` | `event, turn` | `static_contract_accepted_waiver` | `accepted_strategy_context_signal_static_contract` |
| `approach_cast_tracked` | `yes` | `5` | `strategy_signal` | `decision_strategy_or_replay_context` | `event, turn` | `observed_in_latest` | `-` |
| `approach_first_resolution` | `yes` | `4` | `strategy_signal` | `decision_strategy_or_replay_context` | `event, turn` | `observed_in_latest` | `-` |
| `attachment_sba` | `yes` | `3` | `ignored_with_reason` | `skip_guardrail_or_state_cleanup` | `event` | `observed_in_latest` | `-` |
| `attack_prevented_by_orims_chant` | `yes` | `2` | `strategy_signal` | `decision_strategy_or_replay_context` | `event, turn` | `observed_in_latest` | `-` |
| `battle_back_face_cast` | `yes` | `0` | `strategy_signal` | `decision_strategy_or_replay_context` | `event, turn` | `static_contract_accepted_waiver` | `accepted_strategy_context_signal_static_contract` |
| `battle_damage` | `yes` | `0` | `renderer_only` | `battle_replay_v10_3.py` | `event` | `static_contract_accepted_waiver` | `accepted_renderer_only_event_no_guardrail_consumer` |
| `board_wipe_resolved` | `yes` | `1` | `strategy_signal` | `decision_strategy_or_replay_context` | `event, turn` | `observed_in_latest` | `-` |
| `cannot_lose_turn_resolved` | `yes` | `0` | `strategy_signal` | `decision_strategy_or_replay_context` | `event, turn` | `static_contract_accepted_waiver` | `accepted_strategy_context_signal_static_contract` |
| `cantrip_mana_filter_artifact_resolved` | `yes` | `0` | `strategy_signal` | `decision_strategy_or_replay_context` | `event, turn` | `static_contract_accepted_waiver` | `accepted_strategy_context_signal_static_contract` |
| `cast_announced` | `yes` | `825` | `technical` | `structured_replay_ledger` | `event` | `observed_in_latest` | `-` |
| `cast_illegal` | `yes` | `6` | `technical` | `structured_replay_ledger` | `event` | `observed_in_latest` | `-` |
| `chaos_warp_reveal_resolved` | `yes` | `4` | `strategy_signal` | `decision_strategy_or_replay_context` | `event, turn` | `observed_in_latest` | `-` |
| `class_level_gained` | `yes` | `0` | `strategy_signal` | `decision_strategy_or_replay_context` | `event, turn` | `static_contract_accepted_waiver` | `accepted_strategy_context_signal_static_contract` |
| `class_level_trigger_resolved` | `yes` | `0` | `strategy_signal` | `decision_strategy_or_replay_context` | `event, turn` | `static_contract_accepted_waiver` | `accepted_strategy_context_signal_static_contract` |
| `class_level_trigger_skipped` | `yes` | `0` | `ignored_with_reason` | `skip_guardrail_or_state_cleanup` | `event` | `static_contract_accepted_waiver` | `accepted_explicitly_ignored_event_contract` |
| `combat` | `yes` | `254` | `action_audited` | `battle_action_critic.py` | `event, turn` | `observed_in_latest` | `-` |
| `combat_result` | `yes` | `286` | `action_audited` | `battle_action_critic.py` | `event, turn` | `observed_in_latest` | `-` |
| `combat_step` | `yes` | `1645` | `action_audited` | `battle_action_critic.py` | `event, turn` | `observed_in_latest` | `-` |
| `commander_cast` | `yes` | `120` | `action_audited` | `battle_action_critic.py` | `event, turn` | `observed_in_latest` | `-` |
| `compensation_tokens_created` | `yes` | `2` | `renderer_only` | `battle_replay_v10_3.py` | `event` | `observed_in_latest` | `-` |
| `composite_rule_component_resolved` | `yes` | `0` | `strategy_signal` | `decision_strategy_or_replay_context` | `event, turn` | `static_contract_accepted_waiver` | `accepted_strategy_context_signal_static_contract` |
| `composite_rule_resolved` | `yes` | `0` | `strategy_signal` | `decision_strategy_or_replay_context` | `event, turn` | `static_contract_accepted_waiver` | `accepted_strategy_context_signal_static_contract` |
| `copy_creature_token_created` | `yes` | `15` | `renderer_only` | `battle_replay_v10_3.py` | `event` | `observed_in_latest` | `-` |
| `copy_creature_token_failed` | `yes` | `1` | `ignored_with_reason` | `skip_guardrail_or_state_cleanup` | `event` | `observed_in_latest` | `-` |
| `copy_spell_no_stack_target` | `yes` | `4` | `ignored_with_reason` | `skip_guardrail_or_state_cleanup` | `event` | `observed_in_latest` | `-` |
| `cost_paid` | `yes` | `819` | `action_audited` | `battle_action_critic.py` | `event, turn` | `observed_in_latest` | `-` |
| `counters_cancelled` | `yes` | `0` | `ignored_with_reason` | `skip_guardrail_or_state_cleanup` | `event` | `static_contract_accepted_waiver` | `accepted_explicitly_ignored_event_contract` |
| `creature_cast` | `yes` | `201` | `action_audited` | `battle_action_critic.py` | `event, turn` | `observed_in_latest` | `-` |
| `creature_to_battlefield` | `yes` | `20` | `renderer_only` | `battle_replay_v10_3.py` | `event` | `observed_in_latest` | `-` |
| `damage_resolved` | `yes` | `9` | `renderer_only` | `battle_replay_v10_3.py` | `event` | `observed_in_latest` | `-` |
| `damage_wipe_resolved` | `yes` | `0` | `strategy_signal` | `decision_strategy_or_replay_context` | `event, turn` | `static_contract_accepted_waiver` | `accepted_strategy_context_signal_static_contract` |
| `damage_wipe_treasure_resolved` | `yes` | `0` | `strategy_signal` | `decision_strategy_or_replay_context` | `event, turn` | `static_contract_accepted_waiver` | `accepted_strategy_context_signal_static_contract` |
| `demonstrate_resolved` | `yes` | `0` | `strategy_signal` | `decision_strategy_or_replay_context` | `event, turn` | `static_contract_accepted_waiver` | `accepted_strategy_context_signal_static_contract` |
| `dig_to_hand_resolved` | `yes` | `0` | `strategy_signal` | `decision_strategy_or_replay_context` | `event, turn` | `static_contract_accepted_waiver` | `accepted_strategy_context_signal_static_contract` |
| `discard_modal_trigger_resolved` | `yes` | `0` | `strategy_signal` | `decision_strategy_or_replay_context` | `event, turn` | `static_contract_accepted_waiver` | `accepted_strategy_context_signal_static_contract` |
| `dragons_approach_dragon_tutored` | `yes` | `0` | `strategy_signal` | `decision_strategy_or_replay_context` | `event, turn` | `static_contract_accepted_waiver` | `accepted_strategy_context_signal_static_contract` |
| `dragons_approach_resolved` | `yes` | `0` | `strategy_signal` | `decision_strategy_or_replay_context` | `event, turn` | `static_contract_accepted_waiver` | `accepted_strategy_context_signal_static_contract` |
| `draw_cards_resolved` | `yes` | `13` | `strategy_signal` | `decision_strategy_or_replay_context` | `event, turn` | `observed_in_latest` | `-` |
| `draw_equal_to_discarded_hand_resolved` | `yes` | `2` | `strategy_signal` | `decision_strategy_or_replay_context` | `event, turn` | `observed_in_latest` | `-` |
| `end_step_instant` | `yes` | `32` | `action_audited` | `battle_action_critic.py` | `event, turn` | `observed_in_latest` | `-` |
| `end_step_token_death_draw_resolved` | `yes` | `0` | `technical` | `structured_replay_ledger` | `event` | `static_contract_accepted_waiver` | `accepted_technical_ledger_event_no_forced_replay_required` |
| `end_step_token_exiled` | `yes` | `7` | `renderer_only` | `battle_replay_v10_3.py` | `event` | `observed_in_latest` | `-` |
| `end_step_token_sacrificed` | `yes` | `6` | `renderer_only` | `battle_replay_v10_3.py` | `event` | `observed_in_latest` | `-` |
| `equipment_attached` | `yes` | `2` | `renderer_only` | `battle_replay_v10_3.py` | `event` | `observed_in_latest` | `-` |
| `equipment_unattached` | `yes` | `3` | `renderer_only` | `battle_replay_v10_3.py` | `event` | `observed_in_latest` | `-` |
| `etb_land_ramp_skipped` | `yes` | `0` | `ignored_with_reason` | `skip_guardrail_or_state_cleanup` | `event` | `static_contract_accepted_waiver` | `accepted_explicitly_ignored_event_contract` |
| `etb_recursion_resolved` | `yes` | `0` | `strategy_signal` | `decision_strategy_or_replay_context` | `event, turn` | `static_contract_accepted_waiver` | `accepted_strategy_context_signal_static_contract` |
| `etb_removal_resolved` | `yes` | `1` | `strategy_signal` | `decision_strategy_or_replay_context` | `event, turn` | `observed_in_latest` | `-` |
| `etb_removal_skipped` | `yes` | `0` | `ignored_with_reason` | `skip_guardrail_or_state_cleanup` | `event` | `static_contract_accepted_waiver` | `accepted_explicitly_ignored_event_contract` |
| `etb_tutor_resolved` | `yes` | `0` | `strategy_signal` | `decision_strategy_or_replay_context` | `event, turn` | `static_contract_accepted_waiver` | `accepted_strategy_context_signal_static_contract` |
| `extra_combat_cap_reached` | `yes` | `0` | `ignored_with_reason` | `skip_guardrail_or_state_cleanup` | `event` | `static_contract_accepted_waiver` | `accepted_explicitly_ignored_event_contract` |
| `extra_combat_scheduled` | `yes` | `0` | `strategy_signal` | `decision_strategy_or_replay_context` | `event, turn` | `static_contract_accepted_waiver` | `accepted_strategy_context_signal_static_contract` |
| `extra_combat_taken` | `yes` | `0` | `strategy_signal` | `decision_strategy_or_replay_context` | `event, turn` | `static_contract_accepted_waiver` | `accepted_strategy_context_signal_static_contract` |
| `extra_turn_cap_reached` | `yes` | `0` | `ignored_with_reason` | `skip_guardrail_or_state_cleanup` | `event` | `static_contract_accepted_waiver` | `accepted_explicitly_ignored_event_contract` |
| `extra_turn_scheduled` | `yes` | `6` | `strategy_signal` | `decision_strategy_or_replay_context` | `event, turn` | `observed_in_latest` | `-` |
| `extra_turn_taken` | `yes` | `0` | `strategy_signal` | `decision_strategy_or_replay_context` | `event, turn` | `static_contract_accepted_waiver` | `accepted_strategy_context_signal_static_contract` |
| `flashback_cast` | `yes` | `2` | `action_audited` | `battle_action_critic.py` | `event, turn` | `observed_in_latest` | `-` |
| `flashback_exiled` | `yes` | `2` | `technical` | `structured_replay_ledger` | `event` | `observed_in_latest` | `-` |
| `game_lost` | `yes` | `0` | `strategy_signal` | `decision_strategy_or_replay_context` | `event, turn` | `static_contract_accepted_waiver` | `accepted_strategy_context_signal_static_contract` |
| `game_win_prevented` | `yes` | `0` | `strategy_signal` | `decision_strategy_or_replay_context` | `event, turn` | `static_contract_accepted_waiver` | `accepted_strategy_context_signal_static_contract` |
| `game_won` | `yes` | `15` | `action_audited` | `battle_action_critic.py` | `event, turn` | `observed_in_latest` | `-` |
| `graveyard_flashback_granted` | `yes` | `4` | `strategy_signal` | `decision_strategy_or_replay_context` | `event, turn` | `observed_in_latest` | `-` |
| `hand_filter_resolved` | `yes` | `4` | `strategy_signal` | `decision_strategy_or_replay_context` | `event, turn` | `observed_in_latest` | `-` |
| `hate_artifact_resolved` | `yes` | `4` | `strategy_signal` | `decision_strategy_or_replay_context` | `event, turn` | `observed_in_latest` | `-` |
| `imprint_failed` | `yes` | `0` | `ignored_with_reason` | `skip_guardrail_or_state_cleanup` | `event` | `static_contract_accepted_waiver` | `accepted_explicitly_ignored_event_contract` |
| `imprint_resolved` | `yes` | `7` | `strategy_signal` | `decision_strategy_or_replay_context` | `event, turn` | `observed_in_latest` | `-` |
| `instant_removal` | `yes` | `0` | `forensic_card_event` | `battle_forensic_audit.py` | `event, turn` | `static_contract_accepted_waiver` | `accepted_forensic_card_event_static_contract_until_observed` |
| `invoke_calamity_free_cast` | `yes` | `0` | `strategy_signal` | `decision_strategy_or_replay_context` | `event, turn` | `static_contract_accepted_waiver` | `accepted_strategy_context_signal_static_contract` |
| `invoke_calamity_resolved` | `yes` | `0` | `strategy_signal` | `decision_strategy_or_replay_context` | `event, turn` | `static_contract_accepted_waiver` | `accepted_strategy_context_signal_static_contract` |
| `jeskas_will_resolved` | `yes` | `1` | `strategy_signal` | `decision_strategy_or_replay_context` | `event, turn` | `observed_in_latest` | `-` |
| `land_played` | `yes` | `384` | `action_audited` | `battle_action_critic.py` | `event, turn` | `observed_in_latest` | `-` |
| `land_ramp_resolved` | `yes` | `10` | `strategy_signal` | `decision_strategy_or_replay_context` | `event, turn` | `observed_in_latest` | `-` |
| `land_recursion_creature_resolved` | `yes` | `0` | `strategy_signal` | `decision_strategy_or_replay_context` | `event, turn` | `static_contract_accepted_waiver` | `accepted_strategy_context_signal_static_contract` |
| `land_recursion_resolved` | `yes` | `0` | `strategy_signal` | `decision_strategy_or_replay_context` | `event, turn` | `static_contract_accepted_waiver` | `accepted_strategy_context_signal_static_contract` |
| `land_tax_trigger_resolved` | `yes` | `11` | `strategy_signal` | `decision_strategy_or_replay_context` | `event, turn` | `observed_in_latest` | `-` |
| `land_tax_trigger_skipped` | `yes` | `12` | `ignored_with_reason` | `skip_guardrail_or_state_cleanup` | `event` | `observed_in_latest` | `-` |
| `lander_token_created` | `yes` | `0` | `renderer_only` | `battle_replay_v10_3.py` | `event` | `static_contract_accepted_waiver` | `accepted_renderer_only_event_no_guardrail_consumer` |
| `life_artifact_resolved` | `yes` | `0` | `strategy_signal` | `decision_strategy_or_replay_context` | `event, turn` | `static_contract_accepted_waiver` | `accepted_strategy_context_signal_static_contract` |
| `life_totals_redistributed` | `yes` | `0` | `strategy_signal` | `decision_strategy_or_replay_context` | `event, turn` | `static_contract_accepted_waiver` | `accepted_strategy_context_signal_static_contract` |
| `loot_resolved` | `yes` | `3` | `strategy_signal` | `decision_strategy_or_replay_context` | `event, turn` | `observed_in_latest` | `-` |
| `lorehold_upkeep_rummage` | `yes` | `43` | `strategy_signal` | `decision_strategy_or_replay_context` | `event, turn` | `observed_in_latest` | `-` |
| `lorehold_upkeep_rummage_skipped` | `yes` | `172` | `ignored_with_reason` | `skip_guardrail_or_state_cleanup` | `event` | `observed_in_latest` | `-` |
| `loyalty_ability_activated` | `yes` | `0` | `strategy_signal` | `decision_strategy_or_replay_context` | `event, turn` | `static_contract_accepted_waiver` | `accepted_strategy_context_signal_static_contract` |
| `mana_refreshed` | `yes` | `612` | `technical` | `structured_replay_ledger` | `event` | `observed_in_latest` | `-` |
| `mill_resolved` | `yes` | `3` | `strategy_signal` | `decision_strategy_or_replay_context` | `event, turn` | `observed_in_latest` | `-` |
| `miracle_cast` | `yes` | `12` | `action_audited` | `battle_action_critic.py` | `event, turn` | `observed_in_latest` | `-` |
| `mizzix_mastery_copy_cast` | `yes` | `4` | `strategy_signal` | `decision_strategy_or_replay_context` | `event, turn` | `observed_in_latest` | `-` |
| `mizzix_mastery_resolved` | `yes` | `5` | `strategy_signal` | `decision_strategy_or_replay_context` | `event, turn` | `observed_in_latest` | `-` |
| `modal_boros_charm_resolved` | `yes` | `3` | `strategy_signal` | `decision_strategy_or_replay_context` | `event, turn` | `observed_in_latest` | `-` |
| `modal_spell_resolved` | `yes` | `0` | `strategy_signal` | `decision_strategy_or_replay_context` | `event, turn` | `static_contract_accepted_waiver` | `accepted_strategy_context_signal_static_contract` |
| `multi_defender_attack` | `yes` | `26` | `action_audited` | `battle_action_critic.py` | `event, turn` | `observed_in_latest` | `-` |
| `multi_target_resolution` | `yes` | `0` | `forensic_card_event` | `battle_forensic_audit.py` | `event, turn` | `static_contract_accepted_waiver` | `accepted_forensic_card_event_static_contract_until_observed` |
| `multikicker_paid` | `yes` | `0` | `technical` | `structured_replay_ledger` | `event` | `static_contract_accepted_waiver` | `accepted_technical_ledger_event_no_forced_replay_required` |
| `noncombat_damage_modified` | `yes` | `0` | `strategy_signal` | `decision_strategy_or_replay_context` | `event, turn` | `static_contract_accepted_waiver` | `accepted_strategy_context_signal_static_contract` |
| `one_ring_burden_life_loss` | `yes` | `8` | `strategy_signal` | `decision_strategy_or_replay_context` | `event, turn` | `observed_in_latest` | `-` |
| `paradigm_exiled` | `yes` | `0` | `renderer_only` | `battle_replay_v10_3.py` | `event` | `static_contract_accepted_waiver` | `accepted_renderer_only_event_no_guardrail_consumer` |
| `permanent_moved_by_sba` | `yes` | `1` | `ignored_with_reason` | `skip_guardrail_or_state_cleanup` | `event` | `observed_in_latest` | `-` |
| `phase_creatures_resolved` | `yes` | `0` | `strategy_signal` | `decision_strategy_or_replay_context` | `event, turn` | `static_contract_accepted_waiver` | `accepted_strategy_context_signal_static_contract` |
| `phase_out_resolved` | `yes` | `2` | `strategy_signal` | `decision_strategy_or_replay_context` | `event, turn` | `observed_in_latest` | `-` |
| `pile_selection_draw_resolved` | `yes` | `0` | `strategy_signal` | `decision_strategy_or_replay_context` | `event, turn` | `static_contract_accepted_waiver` | `accepted_strategy_context_signal_static_contract` |
| `planeswalker_damage` | `yes` | `0` | `renderer_only` | `battle_replay_v10_3.py` | `event` | `static_contract_accepted_waiver` | `accepted_renderer_only_event_no_guardrail_consumer` |
| `planeswalker_resolved` | `yes` | `0` | `action_audited` | `battle_action_critic.py` | `event, turn` | `static_contract_accepted_waiver` | `accepted_action_branch_static_contract_until_natural_or_targeted_regression` |
| `player_eliminated` | `yes` | `12` | `action_audited` | `battle_action_critic.py` | `event, turn` | `observed_in_latest` | `-` |
| `powerbalance_trigger_resolved` | `yes` | `0` | `strategy_signal` | `decision_strategy_or_replay_context` | `event, turn` | `static_contract_accepted_waiver` | `accepted_strategy_context_signal_static_contract` |
| `prepared_copies_removed` | `yes` | `0` | `technical` | `structured_replay_ledger` | `event` | `static_contract_accepted_waiver` | `accepted_technical_ledger_event_no_forced_replay_required` |
| `prepared_copy_created` | `yes` | `0` | `renderer_only` | `battle_replay_v10_3.py` | `event` | `static_contract_accepted_waiver` | `accepted_renderer_only_event_no_guardrail_consumer` |
| `priority_pass` | `yes` | `7296` | `technical` | `structured_replay_ledger` | `event` | `observed_in_latest` | `-` |
| `protection_from_everything_granted` | `yes` | `7` | `strategy_signal` | `decision_strategy_or_replay_context` | `event, turn` | `observed_in_latest` | `-` |
| `protection_resolved` | `yes` | `3` | `strategy_signal` | `decision_strategy_or_replay_context` | `event, turn` | `observed_in_latest` | `-` |
| `random_discard_after_tutor` | `yes` | `4` | `strategy_signal` | `decision_strategy_or_replay_context` | `event, turn` | `observed_in_latest` | `-` |
| `rebound_cast` | `yes` | `0` | `strategy_signal` | `decision_strategy_or_replay_context` | `event, turn` | `static_contract_accepted_waiver` | `accepted_strategy_context_signal_static_contract` |
| `rebound_exiled` | `yes` | `0` | `technical` | `structured_replay_ledger` | `event` | `static_contract_accepted_waiver` | `accepted_technical_ledger_event_no_forced_replay_required` |
| `rebound_skipped` | `yes` | `0` | `ignored_with_reason` | `skip_guardrail_or_state_cleanup` | `event` | `static_contract_accepted_waiver` | `accepted_explicitly_ignored_event_contract` |
| `recursion_resolved` | `yes` | `6` | `action_audited` | `battle_action_critic.py` | `event, turn` | `observed_in_latest` | `-` |
| `redirect_removal_resolved` | `yes` | `5` | `action_audited` | `battle_action_critic.py` | `event, turn` | `observed_in_latest` | `-` |
| `removal_countered_by_ward` | `yes` | `0` | `strategy_signal` | `decision_strategy_or_replay_context` | `event, turn` | `static_contract_accepted_waiver` | `accepted_strategy_context_signal_static_contract` |
| `removal_resolved` | `yes` | `41` | `action_audited` | `battle_action_critic.py` | `event, turn` | `observed_in_latest` | `-` |
| `replacement_applied` | `yes` | `92` | `action_audited` | `battle_action_critic.py` | `event, turn` | `observed_in_latest` | `-` |
| `replacement_exiled_on_resolution` | `yes` | `0` | `technical` | `structured_replay_ledger` | `event` | `static_contract_accepted_waiver` | `accepted_technical_ledger_event_no_forced_replay_required` |
| `ripple_trigger_resolved` | `yes` | `0` | `strategy_signal` | `decision_strategy_or_replay_context` | `event, turn` | `static_contract_accepted_waiver` | `accepted_strategy_context_signal_static_contract` |
| `ritual_mana_added` | `yes` | `12` | `strategy_signal` | `decision_strategy_or_replay_context` | `event, turn` | `observed_in_latest` | `-` |
| `saga_chapter_progressed` | `yes` | `5` | `strategy_signal` | `decision_strategy_or_replay_context` | `event, turn` | `observed_in_latest` | `-` |
| `saga_chapter_resolved` | `yes` | `2` | `strategy_signal` | `decision_strategy_or_replay_context` | `event, turn` | `observed_in_latest` | `-` |
| `saga_sacrificed_by_sba` | `yes` | `2` | `ignored_with_reason` | `skip_guardrail_or_state_cleanup` | `event` | `observed_in_latest` | `-` |
| `self_exiled_on_resolution` | `yes` | `7` | `technical` | `structured_replay_ledger` | `event` | `observed_in_latest` | `-` |
| `spell_cast` | `yes` | `514` | `action_audited` | `battle_action_critic.py` | `event, turn` | `observed_in_latest` | `-` |
| `spell_copied` | `yes` | `6` | `strategy_signal` | `decision_strategy_or_replay_context` | `event, turn` | `observed_in_latest` | `-` |
| `spell_copy_ceased_to_exist` | `yes` | `10` | `technical` | `structured_replay_ledger` | `event` | `observed_in_latest` | `-` |
| `spell_countered` | `yes` | `14` | `action_audited` | `battle_action_critic.py` | `event, turn` | `observed_in_latest` | `-` |
| `spell_exiled_from_stack` | `yes` | `0` | `action_audited` | `battle_action_critic.py` | `event, turn` | `static_contract_accepted_waiver` | `accepted_action_branch_static_contract_until_natural_or_targeted_regression` |
| `spell_resolved` | `yes` | `392` | `action_audited` | `battle_action_critic.py` | `cast_pipeline, destination, event, from_zone, locked_cost, phase, priority_window, resolved_from_stack, result, source_zone, stack_depth, stack_object, to_zone, turn, zone_after` | `observed_in_latest` | `-` |
| `spell_shuffled_into_library_on_resolution` | `yes` | `3` | `strategy_signal` | `decision_strategy_or_replay_context` | `event, turn` | `observed_in_latest` | `-` |
| `static_enter_tapped_applied` | `yes` | `0` | `technical` | `structured_replay_ledger` | `event` | `static_contract_accepted_waiver` | `accepted_technical_ledger_event_no_forced_replay_required` |
| `station_activated` | `yes` | `0` | `strategy_signal` | `decision_strategy_or_replay_context` | `event, turn` | `static_contract_accepted_waiver` | `accepted_strategy_context_signal_static_contract` |
| `steal_all_creatures_resolved` | `yes` | `0` | `strategy_signal` | `decision_strategy_or_replay_context` | `event, turn` | `static_contract_accepted_waiver` | `accepted_strategy_context_signal_static_contract` |
| `surge_to_victory_resolved` | `yes` | `0` | `strategy_signal` | `decision_strategy_or_replay_context` | `event, turn` | `static_contract_accepted_waiver` | `accepted_strategy_context_signal_static_contract` |
| `thassa_oracle_resolved` | `yes` | `0` | `strategy_signal` | `decision_strategy_or_replay_context` | `event, turn` | `static_contract_accepted_waiver` | `accepted_strategy_context_signal_static_contract` |
| `token_ceased_to_exist` | `yes` | `0` | `renderer_only` | `battle_replay_v10_3.py` | `event` | `static_contract_accepted_waiver` | `accepted_renderer_only_event_no_guardrail_consumer` |
| `tokens_created` | `yes` | `0` | `renderer_only` | `battle_replay_v10_3.py` | `event` | `static_contract_accepted_waiver` | `accepted_renderer_only_event_no_guardrail_consumer` |
| `top_nonland_free_cast` | `yes` | `0` | `strategy_signal` | `decision_strategy_or_replay_context` | `event, turn` | `static_contract_accepted_waiver` | `accepted_strategy_context_signal_static_contract` |
| `top_nonland_free_cast_resolved` | `yes` | `0` | `strategy_signal` | `decision_strategy_or_replay_context` | `event, turn` | `static_contract_accepted_waiver` | `accepted_strategy_context_signal_static_contract` |
| `topdeck_manipulation_activated` | `yes` | `14` | `strategy_signal` | `decision_strategy_or_replay_context` | `event, turn` | `observed_in_latest` | `-` |
| `treasure_created` | `yes` | `4` | `renderer_only` | `battle_replay_v10_3.py` | `event` | `observed_in_latest` | `-` |
| `trigger_put_on_stack` | `yes` | `361` | `action_audited` | `battle_action_critic.py` | `event, turn` | `observed_in_latest` | `-` |
| `trigger_resolved` | `yes` | `373` | `action_audited` | `battle_action_critic.py` | `event, turn` | `observed_in_latest` | `-` |
| `trigger_skipped` | `yes` | `0` | `ignored_with_reason` | `skip_guardrail_or_state_cleanup` | `event` | `static_contract_accepted_waiver` | `accepted_explicitly_ignored_event_contract` |
| `turn_end` | `yes` | `595` | `action_audited` | `battle_action_critic.py` | `event, turn` | `observed_in_latest` | `-` |
| `turn_start` | `yes` | `612` | `action_audited` | `battle_action_critic.py` | `event, turn` | `observed_in_latest` | `-` |
| `tutor_life_loss_resolved` | `yes` | `11` | `strategy_signal` | `decision_strategy_or_replay_context` | `event, turn` | `observed_in_latest` | `-` |
| `tutor_resolved` | `yes` | `69` | `action_audited` | `battle_action_critic.py` | `event, turn` | `observed_in_latest` | `-` |
| `utility_artifact_activated` | `yes` | `16` | `strategy_signal` | `decision_strategy_or_replay_context` | `event, turn` | `observed_in_latest` | `-` |
| `utility_land_activated` | `yes` | `24` | `strategy_signal` | `decision_strategy_or_replay_context` | `event, turn` | `observed_in_latest` | `-` |
| `utility_land_triggered` | `yes` | `13` | `strategy_signal` | `decision_strategy_or_replay_context` | `event, turn` | `observed_in_latest` | `-` |
| `ward_countered` | `yes` | `0` | `strategy_signal` | `decision_strategy_or_replay_context` | `event, turn` | `static_contract_accepted_waiver` | `accepted_strategy_context_signal_static_contract` |
| `ward_paid` | `yes` | `0` | `technical` | `structured_replay_ledger` | `event` | `static_contract_accepted_waiver` | `accepted_technical_ledger_event_no_forced_replay_required` |
| `warp_cast` | `yes` | `0` | `strategy_signal` | `decision_strategy_or_replay_context` | `event, turn` | `static_contract_accepted_waiver` | `accepted_strategy_context_signal_static_contract` |
| `warp_exiled_end_step` | `yes` | `0` | `technical` | `structured_replay_ledger` | `event` | `static_contract_accepted_waiver` | `accepted_technical_ledger_event_no_forced_replay_required` |
| `warp_recast_from_exile` | `yes` | `0` | `strategy_signal` | `decision_strategy_or_replay_context` | `event, turn` | `static_contract_accepted_waiver` | `accepted_strategy_context_signal_static_contract` |
| `wheel_resolved` | `yes` | `7` | `strategy_signal` | `decision_strategy_or_replay_context` | `event, turn` | `observed_in_latest` | `-` |
| `worldfire_resolved` | `yes` | `0` | `strategy_signal` | `decision_strategy_or_replay_context` | `event, turn` | `static_contract_accepted_waiver` | `accepted_strategy_context_signal_static_contract` |

## Field Findings

- No observed event field findings.
