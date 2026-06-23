# Battle Event Contract Static Audit

- Generated at UTC: `2026-06-23T07:18:19Z`
- Status: `review_required`
- Engine source: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/manaloom-knowledge/scripts/battle_analyst_v9.py`
- Static engine sources: `["/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/manaloom-knowledge/scripts/battle_analyst_v9.py", "/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/manaloom-knowledge/scripts/battle_sba_support.py", "/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/manaloom-knowledge/scripts/battle_replacement_support.py", "/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/manaloom-knowledge/scripts/battle_zone_transition_support.py"]`
- Event paths: `["/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260623_065316/seed_64270200/replay.events.jsonl", "/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260623_065316/seed_64270201/replay.events.jsonl", "/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260623_065316/seed_64270202/replay.events.jsonl", "/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260623_065316/seed_64270203/replay.events.jsonl", "/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260623_065316/seed_64270204/replay.events.jsonl", "/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260623_065316/seed_64270205/replay.events.jsonl", "/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260623_065316/seed_64270206/replay.events.jsonl", "/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260623_065316/seed_64270207/replay.events.jsonl", "/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260623_065316/seed_64270208/replay.events.jsonl", "/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260623_065316/seed_64270209/replay.events.jsonl", "/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260623_065316/seed_64270210/replay.events.jsonl", "/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260623_065316/seed_64270211/replay.events.jsonl", "/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260623_065316/seed_64270212/replay.events.jsonl", "/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260623_065316/seed_64270213/replay.events.jsonl", "/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260623_065316/seed_64270214/replay.events.jsonl", "/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260623_065316/seed_64270215/replay.events.jsonl"]`
- Observed events: `19415`
- Observed event types: `86`
- Static event types: `138`
- Static unclassified total: `0`
- Observed unclassified total: `0`
- Observed missing required fields: `13`
- Fixture/waiver counts: `{"observed_in_latest": 86, "static_contract_accepted_waiver": 52}`
- Static fixture accepted waiver total: `52`
- Static contract waiver until forced fixture: `0`
- Static fixture accepted waiver reasons: `{"accepted_explicitly_ignored_event_contract": 7, "accepted_forensic_card_event_static_contract_until_observed": 1, "accepted_renderer_only_event_no_guardrail_consumer": 7, "accepted_strategy_context_signal_static_contract": 32, "accepted_technical_ledger_event_no_forced_replay_required": 5}`
- Static fixture unaccepted types: `[]`
- Static class counts: `{"action_audited": 26, "forensic_card_event": 2, "ignored_with_reason": 13, "renderer_only": 15, "strategy_signal": 68, "technical": 14}`
- Observed type class counts: `{"action_audited": 26, "forensic_card_event": 1, "ignored_with_reason": 6, "renderer_only": 8, "strategy_signal": 36, "technical": 9}`
- Observed event class counts: `{"action_audited": 8243, "forensic_card_event": 1, "ignored_with_reason": 619, "renderer_only": 42, "strategy_signal": 312, "technical": 10198}`
- Observed not static literal: `[]`

## Event Contract Matrix

| Event | Static | Observed | Class | Consumer | Minimum fields | Fixture/waiver | Reason |
| --- | --- | ---: | --- | --- | --- | --- | --- |
| `activated_ability` | `yes` | `10` | `strategy_signal` | `decision_strategy_or_replay_context` | `event, turn` | `observed_in_latest` | `-` |
| `activated_ability_skipped` | `yes` | `311` | `ignored_with_reason` | `skip_guardrail_or_state_cleanup` | `event` | `observed_in_latest` | `-` |
| `additional_cost_failed` | `yes` | `2` | `action_audited` | `battle_action_critic.py` | `event, turn` | `observed_in_latest` | `-` |
| `additional_cost_paid` | `yes` | `44` | `technical` | `structured_replay_ledger` | `event` | `observed_in_latest` | `-` |
| `adventure_cast` | `yes` | `0` | `strategy_signal` | `decision_strategy_or_replay_context` | `event, turn` | `static_contract_accepted_waiver` | `accepted_strategy_context_signal_static_contract` |
| `adventure_creature_cast_from_exile` | `yes` | `0` | `strategy_signal` | `decision_strategy_or_replay_context` | `event, turn` | `static_contract_accepted_waiver` | `accepted_strategy_context_signal_static_contract` |
| `adventure_exiled` | `yes` | `0` | `technical` | `structured_replay_ledger` | `event` | `static_contract_accepted_waiver` | `accepted_technical_ledger_event_no_forced_replay_required` |
| `aetherflux_reservoir_resolved` | `yes` | `5` | `strategy_signal` | `decision_strategy_or_replay_context` | `event, turn` | `observed_in_latest` | `-` |
| `approach_cast_tracked` | `yes` | `11` | `strategy_signal` | `decision_strategy_or_replay_context` | `event, turn` | `observed_in_latest` | `-` |
| `approach_first_resolution` | `yes` | `6` | `strategy_signal` | `decision_strategy_or_replay_context` | `event, turn` | `observed_in_latest` | `-` |
| `attachment_sba` | `yes` | `0` | `ignored_with_reason` | `skip_guardrail_or_state_cleanup` | `event` | `static_contract_accepted_waiver` | `accepted_explicitly_ignored_event_contract` |
| `attack_prevented_by_orims_chant` | `yes` | `3` | `strategy_signal` | `decision_strategy_or_replay_context` | `event, turn` | `observed_in_latest` | `-` |
| `battle_back_face_cast` | `yes` | `0` | `strategy_signal` | `decision_strategy_or_replay_context` | `event, turn` | `static_contract_accepted_waiver` | `accepted_strategy_context_signal_static_contract` |
| `battle_damage` | `yes` | `0` | `renderer_only` | `battle_replay_v10_3.py` | `event` | `static_contract_accepted_waiver` | `accepted_renderer_only_event_no_guardrail_consumer` |
| `board_wipe_resolved` | `yes` | `2` | `strategy_signal` | `decision_strategy_or_replay_context` | `event, turn` | `observed_in_latest` | `-` |
| `cannot_lose_turn_resolved` | `yes` | `0` | `strategy_signal` | `decision_strategy_or_replay_context` | `event, turn` | `static_contract_accepted_waiver` | `accepted_strategy_context_signal_static_contract` |
| `cantrip_mana_filter_artifact_resolved` | `yes` | `0` | `strategy_signal` | `decision_strategy_or_replay_context` | `event, turn` | `static_contract_accepted_waiver` | `accepted_strategy_context_signal_static_contract` |
| `cast_announced` | `yes` | `935` | `technical` | `structured_replay_ledger` | `event` | `observed_in_latest` | `-` |
| `cast_illegal` | `yes` | `21` | `technical` | `structured_replay_ledger` | `event` | `observed_in_latest` | `-` |
| `chaos_warp_reveal_resolved` | `yes` | `5` | `strategy_signal` | `decision_strategy_or_replay_context` | `event, turn` | `observed_in_latest` | `-` |
| `combat` | `yes` | `357` | `action_audited` | `battle_action_critic.py` | `event, turn` | `observed_in_latest` | `-` |
| `combat_result` | `yes` | `390` | `action_audited` | `battle_action_critic.py` | `event, turn` | `observed_in_latest` | `-` |
| `combat_step` | `yes` | `2199` | `action_audited` | `battle_action_critic.py` | `event, turn` | `observed_in_latest` | `-` |
| `commander_cast` | `yes` | `113` | `action_audited` | `battle_action_critic.py` | `event, turn` | `observed_in_latest` | `-` |
| `compensation_tokens_created` | `yes` | `3` | `renderer_only` | `battle_replay_v10_3.py` | `event` | `observed_in_latest` | `-` |
| `composite_rule_component_resolved` | `yes` | `0` | `strategy_signal` | `decision_strategy_or_replay_context` | `event, turn` | `static_contract_accepted_waiver` | `accepted_strategy_context_signal_static_contract` |
| `composite_rule_resolved` | `yes` | `0` | `strategy_signal` | `decision_strategy_or_replay_context` | `event, turn` | `static_contract_accepted_waiver` | `accepted_strategy_context_signal_static_contract` |
| `copy_creature_token_created` | `yes` | `9` | `renderer_only` | `battle_replay_v10_3.py` | `event` | `observed_in_latest` | `-` |
| `copy_creature_token_failed` | `yes` | `2` | `ignored_with_reason` | `skip_guardrail_or_state_cleanup` | `event` | `observed_in_latest` | `-` |
| `copy_spell_no_stack_target` | `yes` | `4` | `ignored_with_reason` | `skip_guardrail_or_state_cleanup` | `event` | `observed_in_latest` | `-` |
| `cost_paid` | `yes` | `914` | `action_audited` | `battle_action_critic.py` | `event, turn` | `observed_in_latest` | `-` |
| `counters_cancelled` | `yes` | `0` | `ignored_with_reason` | `skip_guardrail_or_state_cleanup` | `event` | `static_contract_accepted_waiver` | `accepted_explicitly_ignored_event_contract` |
| `creature_cast` | `yes` | `274` | `action_audited` | `battle_action_critic.py` | `event, turn` | `observed_in_latest` | `-` |
| `creature_to_battlefield` | `yes` | `5` | `renderer_only` | `battle_replay_v10_3.py` | `event` | `observed_in_latest` | `-` |
| `damage_resolved` | `yes` | `7` | `renderer_only` | `battle_replay_v10_3.py` | `event` | `observed_in_latest` | `-` |
| `damage_wipe_resolved` | `yes` | `0` | `strategy_signal` | `decision_strategy_or_replay_context` | `event, turn` | `static_contract_accepted_waiver` | `accepted_strategy_context_signal_static_contract` |
| `damage_wipe_treasure_resolved` | `yes` | `0` | `strategy_signal` | `decision_strategy_or_replay_context` | `event, turn` | `static_contract_accepted_waiver` | `accepted_strategy_context_signal_static_contract` |
| `dragons_approach_dragon_tutored` | `yes` | `0` | `strategy_signal` | `decision_strategy_or_replay_context` | `event, turn` | `static_contract_accepted_waiver` | `accepted_strategy_context_signal_static_contract` |
| `dragons_approach_resolved` | `yes` | `0` | `strategy_signal` | `decision_strategy_or_replay_context` | `event, turn` | `static_contract_accepted_waiver` | `accepted_strategy_context_signal_static_contract` |
| `draw_cards_resolved` | `yes` | `19` | `strategy_signal` | `decision_strategy_or_replay_context` | `event, turn` | `observed_in_latest` | `-` |
| `draw_equal_to_discarded_hand_resolved` | `yes` | `5` | `strategy_signal` | `decision_strategy_or_replay_context` | `event, turn` | `observed_in_latest` | `-` |
| `end_step_instant` | `yes` | `22` | `action_audited` | `battle_action_critic.py` | `event, turn` | `observed_in_latest` | `-` |
| `end_step_token_exiled` | `yes` | `5` | `renderer_only` | `battle_replay_v10_3.py` | `event` | `observed_in_latest` | `-` |
| `end_step_token_sacrificed` | `yes` | `4` | `renderer_only` | `battle_replay_v10_3.py` | `event` | `observed_in_latest` | `-` |
| `equipment_attached` | `yes` | `3` | `renderer_only` | `battle_replay_v10_3.py` | `event` | `observed_in_latest` | `-` |
| `equipment_unattached` | `yes` | `0` | `renderer_only` | `battle_replay_v10_3.py` | `event` | `static_contract_accepted_waiver` | `accepted_renderer_only_event_no_guardrail_consumer` |
| `etb_tutor_resolved` | `yes` | `0` | `strategy_signal` | `decision_strategy_or_replay_context` | `event, turn` | `static_contract_accepted_waiver` | `accepted_strategy_context_signal_static_contract` |
| `extra_combat_cap_reached` | `yes` | `0` | `ignored_with_reason` | `skip_guardrail_or_state_cleanup` | `event` | `static_contract_accepted_waiver` | `accepted_explicitly_ignored_event_contract` |
| `extra_combat_scheduled` | `yes` | `0` | `strategy_signal` | `decision_strategy_or_replay_context` | `event, turn` | `static_contract_accepted_waiver` | `accepted_strategy_context_signal_static_contract` |
| `extra_combat_taken` | `yes` | `0` | `strategy_signal` | `decision_strategy_or_replay_context` | `event, turn` | `static_contract_accepted_waiver` | `accepted_strategy_context_signal_static_contract` |
| `extra_turn_cap_reached` | `yes` | `0` | `ignored_with_reason` | `skip_guardrail_or_state_cleanup` | `event` | `static_contract_accepted_waiver` | `accepted_explicitly_ignored_event_contract` |
| `extra_turn_scheduled` | `yes` | `3` | `strategy_signal` | `decision_strategy_or_replay_context` | `event, turn` | `observed_in_latest` | `-` |
| `extra_turn_taken` | `yes` | `0` | `strategy_signal` | `decision_strategy_or_replay_context` | `event, turn` | `static_contract_accepted_waiver` | `accepted_strategy_context_signal_static_contract` |
| `flashback_cast` | `yes` | `4` | `action_audited` | `battle_action_critic.py` | `event, turn` | `observed_in_latest` | `-` |
| `flashback_exiled` | `yes` | `3` | `technical` | `structured_replay_ledger` | `event` | `observed_in_latest` | `-` |
| `game_lost` | `yes` | `0` | `strategy_signal` | `decision_strategy_or_replay_context` | `event, turn` | `static_contract_accepted_waiver` | `accepted_strategy_context_signal_static_contract` |
| `game_win_prevented` | `yes` | `0` | `strategy_signal` | `decision_strategy_or_replay_context` | `event, turn` | `static_contract_accepted_waiver` | `accepted_strategy_context_signal_static_contract` |
| `game_won` | `yes` | `15` | `action_audited` | `battle_action_critic.py` | `event, turn` | `observed_in_latest` | `-` |
| `graveyard_flashback_granted` | `yes` | `6` | `strategy_signal` | `decision_strategy_or_replay_context` | `event, turn` | `observed_in_latest` | `-` |
| `hand_filter_resolved` | `yes` | `5` | `strategy_signal` | `decision_strategy_or_replay_context` | `event, turn` | `observed_in_latest` | `-` |
| `hate_artifact_resolved` | `yes` | `3` | `strategy_signal` | `decision_strategy_or_replay_context` | `event, turn` | `observed_in_latest` | `-` |
| `imprint_failed` | `yes` | `0` | `ignored_with_reason` | `skip_guardrail_or_state_cleanup` | `event` | `static_contract_accepted_waiver` | `accepted_explicitly_ignored_event_contract` |
| `imprint_resolved` | `yes` | `1` | `strategy_signal` | `decision_strategy_or_replay_context` | `event, turn` | `observed_in_latest` | `-` |
| `instant_removal` | `yes` | `1` | `forensic_card_event` | `battle_forensic_audit.py` | `event, turn` | `observed_in_latest` | `-` |
| `jeskas_will_resolved` | `yes` | `3` | `strategy_signal` | `decision_strategy_or_replay_context` | `event, turn` | `observed_in_latest` | `-` |
| `land_played` | `yes` | `454` | `action_audited` | `battle_action_critic.py` | `event, turn` | `observed_in_latest` | `-` |
| `land_ramp_resolved` | `yes` | `6` | `strategy_signal` | `decision_strategy_or_replay_context` | `event, turn` | `observed_in_latest` | `-` |
| `land_recursion_creature_resolved` | `yes` | `0` | `strategy_signal` | `decision_strategy_or_replay_context` | `event, turn` | `static_contract_accepted_waiver` | `accepted_strategy_context_signal_static_contract` |
| `land_recursion_resolved` | `yes` | `0` | `strategy_signal` | `decision_strategy_or_replay_context` | `event, turn` | `static_contract_accepted_waiver` | `accepted_strategy_context_signal_static_contract` |
| `land_tax_trigger_resolved` | `yes` | `22` | `strategy_signal` | `decision_strategy_or_replay_context` | `event, turn` | `observed_in_latest` | `-` |
| `land_tax_trigger_skipped` | `yes` | `13` | `ignored_with_reason` | `skip_guardrail_or_state_cleanup` | `event` | `observed_in_latest` | `-` |
| `lander_token_created` | `yes` | `0` | `renderer_only` | `battle_replay_v10_3.py` | `event` | `static_contract_accepted_waiver` | `accepted_renderer_only_event_no_guardrail_consumer` |
| `life_artifact_resolved` | `yes` | `0` | `strategy_signal` | `decision_strategy_or_replay_context` | `event, turn` | `static_contract_accepted_waiver` | `accepted_strategy_context_signal_static_contract` |
| `life_totals_redistributed` | `yes` | `0` | `strategy_signal` | `decision_strategy_or_replay_context` | `event, turn` | `static_contract_accepted_waiver` | `accepted_strategy_context_signal_static_contract` |
| `loot_resolved` | `yes` | `7` | `strategy_signal` | `decision_strategy_or_replay_context` | `event, turn` | `observed_in_latest` | `-` |
| `lorehold_upkeep_rummage` | `yes` | `51` | `strategy_signal` | `decision_strategy_or_replay_context` | `event, turn` | `observed_in_latest` | `-` |
| `lorehold_upkeep_rummage_skipped` | `yes` | `285` | `ignored_with_reason` | `skip_guardrail_or_state_cleanup` | `event` | `observed_in_latest` | `-` |
| `loyalty_ability_activated` | `yes` | `0` | `strategy_signal` | `decision_strategy_or_replay_context` | `event, turn` | `static_contract_accepted_waiver` | `accepted_strategy_context_signal_static_contract` |
| `mana_refreshed` | `yes` | `747` | `technical` | `structured_replay_ledger` | `event` | `observed_in_latest` | `-` |
| `mill_resolved` | `yes` | `0` | `strategy_signal` | `decision_strategy_or_replay_context` | `event, turn` | `static_contract_accepted_waiver` | `accepted_strategy_context_signal_static_contract` |
| `miracle_cast` | `yes` | `20` | `action_audited` | `battle_action_critic.py` | `event, turn` | `observed_in_latest` | `-` |
| `mizzix_mastery_copy_cast` | `yes` | `3` | `strategy_signal` | `decision_strategy_or_replay_context` | `event, turn` | `observed_in_latest` | `-` |
| `mizzix_mastery_resolved` | `yes` | `3` | `strategy_signal` | `decision_strategy_or_replay_context` | `event, turn` | `observed_in_latest` | `-` |
| `modal_boros_charm_resolved` | `yes` | `2` | `strategy_signal` | `decision_strategy_or_replay_context` | `event, turn` | `observed_in_latest` | `-` |
| `multi_defender_attack` | `yes` | `29` | `action_audited` | `battle_action_critic.py` | `event, turn` | `observed_in_latest` | `-` |
| `multi_target_resolution` | `yes` | `0` | `forensic_card_event` | `battle_forensic_audit.py` | `event, turn` | `static_contract_accepted_waiver` | `accepted_forensic_card_event_static_contract_until_observed` |
| `multikicker_paid` | `yes` | `1` | `technical` | `structured_replay_ledger` | `event` | `observed_in_latest` | `-` |
| `one_ring_burden_life_loss` | `yes` | `1` | `strategy_signal` | `decision_strategy_or_replay_context` | `event, turn` | `observed_in_latest` | `-` |
| `paradigm_exiled` | `yes` | `0` | `renderer_only` | `battle_replay_v10_3.py` | `event` | `static_contract_accepted_waiver` | `accepted_renderer_only_event_no_guardrail_consumer` |
| `permanent_moved_by_sba` | `yes` | `0` | `ignored_with_reason` | `skip_guardrail_or_state_cleanup` | `event` | `static_contract_accepted_waiver` | `accepted_explicitly_ignored_event_contract` |
| `phase_creatures_resolved` | `yes` | `0` | `strategy_signal` | `decision_strategy_or_replay_context` | `event, turn` | `static_contract_accepted_waiver` | `accepted_strategy_context_signal_static_contract` |
| `phase_out_resolved` | `yes` | `3` | `strategy_signal` | `decision_strategy_or_replay_context` | `event, turn` | `observed_in_latest` | `-` |
| `planeswalker_damage` | `yes` | `0` | `renderer_only` | `battle_replay_v10_3.py` | `event` | `static_contract_accepted_waiver` | `accepted_renderer_only_event_no_guardrail_consumer` |
| `player_eliminated` | `yes` | `13` | `action_audited` | `battle_action_critic.py` | `event, turn` | `observed_in_latest` | `-` |
| `prepared_copies_removed` | `yes` | `0` | `technical` | `structured_replay_ledger` | `event` | `static_contract_accepted_waiver` | `accepted_technical_ledger_event_no_forced_replay_required` |
| `prepared_copy_created` | `yes` | `0` | `renderer_only` | `battle_replay_v10_3.py` | `event` | `static_contract_accepted_waiver` | `accepted_renderer_only_event_no_guardrail_consumer` |
| `priority_pass` | `yes` | `8431` | `technical` | `structured_replay_ledger` | `event` | `observed_in_latest` | `-` |
| `protection_from_everything_granted` | `yes` | `3` | `strategy_signal` | `decision_strategy_or_replay_context` | `event, turn` | `observed_in_latest` | `-` |
| `protection_resolved` | `yes` | `3` | `strategy_signal` | `decision_strategy_or_replay_context` | `event, turn` | `observed_in_latest` | `-` |
| `random_discard_after_tutor` | `yes` | `7` | `strategy_signal` | `decision_strategy_or_replay_context` | `event, turn` | `observed_in_latest` | `-` |
| `recursion_resolved` | `yes` | `18` | `action_audited` | `battle_action_critic.py` | `event, turn` | `observed_in_latest` | `-` |
| `redirect_removal_resolved` | `yes` | `5` | `action_audited` | `battle_action_critic.py` | `event, turn` | `observed_in_latest` | `-` |
| `removal_countered_by_ward` | `yes` | `0` | `strategy_signal` | `decision_strategy_or_replay_context` | `event, turn` | `static_contract_accepted_waiver` | `accepted_strategy_context_signal_static_contract` |
| `removal_resolved` | `yes` | `46` | `action_audited` | `battle_action_critic.py` | `event, turn` | `observed_in_latest` | `-` |
| `replacement_applied` | `yes` | `113` | `action_audited` | `battle_action_critic.py` | `event, turn` | `observed_in_latest` | `-` |
| `ripple_trigger_resolved` | `yes` | `0` | `strategy_signal` | `decision_strategy_or_replay_context` | `event, turn` | `static_contract_accepted_waiver` | `accepted_strategy_context_signal_static_contract` |
| `ritual_mana_added` | `yes` | `7` | `strategy_signal` | `decision_strategy_or_replay_context` | `event, turn` | `observed_in_latest` | `-` |
| `saga_chapter_progressed` | `yes` | `8` | `strategy_signal` | `decision_strategy_or_replay_context` | `event, turn` | `observed_in_latest` | `-` |
| `saga_chapter_resolved` | `yes` | `4` | `strategy_signal` | `decision_strategy_or_replay_context` | `event, turn` | `observed_in_latest` | `-` |
| `saga_sacrificed_by_sba` | `yes` | `4` | `ignored_with_reason` | `skip_guardrail_or_state_cleanup` | `event` | `observed_in_latest` | `-` |
| `self_exiled_on_resolution` | `yes` | `5` | `technical` | `structured_replay_ledger` | `event` | `observed_in_latest` | `-` |
| `spell_cast` | `yes` | `545` | `action_audited` | `battle_action_critic.py` | `event, turn` | `observed_in_latest` | `-` |
| `spell_copied` | `yes` | `10` | `strategy_signal` | `decision_strategy_or_replay_context` | `event, turn` | `observed_in_latest` | `-` |
| `spell_copy_ceased_to_exist` | `yes` | `11` | `technical` | `structured_replay_ledger` | `event` | `observed_in_latest` | `-` |
| `spell_countered` | `yes` | `29` | `action_audited` | `battle_action_critic.py` | `event, turn` | `observed_in_latest` | `-` |
| `spell_resolved` | `yes` | `408` | `action_audited` | `battle_action_critic.py` | `cast_pipeline, destination, event, from_zone, locked_cost, phase, priority_window, resolved_from_stack, result, source_zone, stack_depth, stack_object, to_zone, turn, zone_after` | `observed_in_latest` | `-` |
| `static_enter_tapped_applied` | `yes` | `0` | `technical` | `structured_replay_ledger` | `event` | `static_contract_accepted_waiver` | `accepted_technical_ledger_event_no_forced_replay_required` |
| `station_activated` | `yes` | `0` | `strategy_signal` | `decision_strategy_or_replay_context` | `event, turn` | `static_contract_accepted_waiver` | `accepted_strategy_context_signal_static_contract` |
| `thassa_oracle_resolved` | `yes` | `0` | `strategy_signal` | `decision_strategy_or_replay_context` | `event, turn` | `static_contract_accepted_waiver` | `accepted_strategy_context_signal_static_contract` |
| `token_ceased_to_exist` | `yes` | `0` | `renderer_only` | `battle_replay_v10_3.py` | `event` | `static_contract_accepted_waiver` | `accepted_renderer_only_event_no_guardrail_consumer` |
| `topdeck_manipulation_activated` | `yes` | `45` | `strategy_signal` | `decision_strategy_or_replay_context` | `event, turn` | `observed_in_latest` | `-` |
| `treasure_created` | `yes` | `6` | `renderer_only` | `battle_replay_v10_3.py` | `event` | `observed_in_latest` | `-` |
| `trigger_put_on_stack` | `yes` | `359` | `action_audited` | `battle_action_critic.py` | `event, turn` | `observed_in_latest` | `-` |
| `trigger_resolved` | `yes` | `359` | `action_audited` | `battle_action_critic.py` | `event, turn` | `observed_in_latest` | `-` |
| `trigger_skipped` | `yes` | `0` | `ignored_with_reason` | `skip_guardrail_or_state_cleanup` | `event` | `static_contract_accepted_waiver` | `accepted_explicitly_ignored_event_contract` |
| `turn_end` | `yes` | `726` | `action_audited` | `battle_action_critic.py` | `event, turn` | `observed_in_latest` | `-` |
| `turn_start` | `yes` | `747` | `action_audited` | `battle_action_critic.py` | `event, turn` | `observed_in_latest` | `-` |
| `tutor_resolved` | `yes` | `82` | `action_audited` | `battle_action_critic.py` | `event, turn` | `observed_in_latest` | `-` |
| `utility_artifact_activated` | `yes` | `7` | `strategy_signal` | `decision_strategy_or_replay_context` | `event, turn` | `observed_in_latest` | `-` |
| `utility_land_activated` | `yes` | `22` | `strategy_signal` | `decision_strategy_or_replay_context` | `event, turn` | `observed_in_latest` | `-` |
| `utility_land_triggered` | `yes` | `8` | `strategy_signal` | `decision_strategy_or_replay_context` | `event, turn` | `observed_in_latest` | `-` |
| `ward_countered` | `yes` | `0` | `strategy_signal` | `decision_strategy_or_replay_context` | `event, turn` | `static_contract_accepted_waiver` | `accepted_strategy_context_signal_static_contract` |
| `ward_paid` | `yes` | `0` | `technical` | `structured_replay_ledger` | `event` | `static_contract_accepted_waiver` | `accepted_technical_ledger_event_no_forced_replay_required` |
| `warp_cast` | `yes` | `0` | `strategy_signal` | `decision_strategy_or_replay_context` | `event, turn` | `static_contract_accepted_waiver` | `accepted_strategy_context_signal_static_contract` |
| `warp_exiled_end_step` | `yes` | `0` | `technical` | `structured_replay_ledger` | `event` | `static_contract_accepted_waiver` | `accepted_technical_ledger_event_no_forced_replay_required` |
| `warp_recast_from_exile` | `yes` | `0` | `strategy_signal` | `decision_strategy_or_replay_context` | `event, turn` | `static_contract_accepted_waiver` | `accepted_strategy_context_signal_static_contract` |
| `wheel_resolved` | `yes` | `3` | `strategy_signal` | `decision_strategy_or_replay_context` | `event, turn` | `observed_in_latest` | `-` |
| `worldfire_resolved` | `yes` | `0` | `strategy_signal` | `decision_strategy_or_replay_context` | `event, turn` | `static_contract_accepted_waiver` | `accepted_strategy_context_signal_static_contract` |

## Field Findings

- `medium` `spell_resolved` missing `['priority_window', 'resolved_from_stack', 'stack_depth']` at `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260623_065316/seed_64270200/replay.events.jsonl:142`
- `medium` `spell_resolved` missing `['cast_pipeline', 'from_zone', 'locked_cost', 'phase', 'source_zone']` at `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260623_065316/seed_64270204/replay.events.jsonl:534`
- `medium` `spell_resolved` missing `['cast_pipeline', 'from_zone', 'locked_cost', 'phase', 'priority_window', 'resolved_from_stack', 'source_zone', 'stack_depth']` at `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260623_065316/seed_64270205/replay.events.jsonl:769`
- `medium` `spell_resolved` missing `['cast_pipeline', 'from_zone', 'locked_cost', 'phase', 'source_zone']` at `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260623_065316/seed_64270205/replay.events.jsonl:1033`
- `medium` `spell_resolved` missing `['cast_pipeline', 'from_zone', 'locked_cost', 'phase', 'source_zone']` at `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260623_065316/seed_64270205/replay.events.jsonl:1157`
- `medium` `spell_resolved` missing `['cast_pipeline', 'from_zone', 'locked_cost', 'phase', 'source_zone']` at `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260623_065316/seed_64270206/replay.events.jsonl:719`
- `medium` `spell_resolved` missing `['cast_pipeline', 'from_zone', 'locked_cost', 'phase', 'source_zone']` at `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260623_065316/seed_64270206/replay.events.jsonl:2409`
- `medium` `spell_resolved` missing `['cast_pipeline', 'from_zone', 'locked_cost', 'phase', 'source_zone']` at `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260623_065316/seed_64270207/replay.events.jsonl:1039`
- `medium` `spell_resolved` missing `['cast_pipeline', 'from_zone', 'locked_cost', 'phase', 'source_zone']` at `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260623_065316/seed_64270211/replay.events.jsonl:663`
- `medium` `spell_resolved` missing `['cast_pipeline', 'from_zone', 'locked_cost', 'phase', 'priority_window', 'resolved_from_stack', 'source_zone', 'stack_depth']` at `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260623_065316/seed_64270212/replay.events.jsonl:740`
- `medium` `spell_resolved` missing `['cast_pipeline', 'from_zone', 'locked_cost', 'phase', 'source_zone']` at `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260623_065316/seed_64270213/replay.events.jsonl:1565`
- `medium` `spell_resolved` missing `['cast_pipeline', 'from_zone', 'locked_cost', 'phase', 'source_zone']` at `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260623_065316/seed_64270213/replay.events.jsonl:2109`
- `medium` `spell_resolved` missing `['cast_pipeline', 'from_zone', 'locked_cost', 'phase', 'priority_window', 'resolved_from_stack', 'source_zone', 'stack_depth']` at `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260623_065316/seed_64270215/replay.events.jsonl:1381`
