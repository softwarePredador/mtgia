# Annotation Runtime Batch Probe - PGC063

- Generated UTC: `2026-06-29T10:10:25.563056+00:00`
- Input PGC060 cards: `39`
- Runtime clean cards: `8`
- Runtime still annotation cards: `31`
- Runtime executor present count: `31`

## Runtime Rows

| Card | Effect | Annotation fields | Runtime executor fields |
| --- | --- | --- | --- |
| `Aetherflux Reservoir` | `aetherflux_reservoir` | `activation_execution_status` | `none` |
| `Birgi, God of Storytelling // Harnfel, Horn of Bounty` | `creature` | `back_face.runtime_status, back_face_runtime_status, boast_runtime_status` | `none` |
| `Blind Obedience` | `passive` | `extort_execution_status` | `none` |
| `Boros Charm` | `modal_boros_charm` | `modes[0].mode_status` | `none` |
| `City of Brass` | `land` | `none` | `conditional_mana_modes[0].status, conditional_mana_modes[1].status, conditional_mana_modes[2].status, conditional_mana_modes[3].status, conditional_mana_modes[4].status, conditional_mana_modes_status, tap_damage_status` |
| `Clifftop Retreat` | `land` | `none` | `conditional_enters_tapped_status` |
| `Drannith Magistrate` | `passive` | `static_ability_status` | `none` |
| `Dualcaster Mage` | `copy_spell` | `choose_new_targets_status` | `none` |
| `Elves of Deep Shadow` | `creature` | `none` | `conditional_mana_modes[0].status, conditional_mana_modes_status, tap_damage_status` |
| `Enduring Vitality` | `creature` | `death_return_status` | `none` |
| `Erode` | `remove_permanent` | `none` | `basic_land_compensation_status` |
| `Flusterstorm` | `counter` | `counter_unless_pays_status, soft_counter_payment_status, storm_copy_status` | `none` |
| `Force of Negation` | `counter` | `alternate_cost_exile_blue_card_status` | `none` |
| `Formidable Speaker` | `creature` | `activated_untap_another_permanent_status, etb_discard_creature_tutor_status` | `none` |
| `Goblin Engineer` | `creature` | `activated_artifact_reanimation_status` | `none` |
| `Grand Abolisher` | `silence_opponents` | `activated_ability_lock_status` | `none` |
| `Inspiring Vantage` | `land` | `none` | `conditional_enters_tapped_status` |
| `Kinnan, Bonder Prodigy` | `creature` | `activated_top_five_nonhuman_creature_to_battlefield_status` | `none` |
| `Knuckles the Echidna` | `ramp_engine` | `upkeep_win_status` | `none` |
| `Magmakin Artillerist` | `creature` | `cycle_trigger_status, cycling_status` | `none` |
| `Mana Confluence` | `land` | `none` | `conditional_mana_modes[0].status, conditional_mana_modes[1].status, conditional_mana_modes[2].status, conditional_mana_modes[3].status, conditional_mana_modes[4].status, conditional_mana_modes_status, life_payment_status` |
| `Millikin` | `creature` | `mana_source_mill_status` | `none` |
| `Professional Face-Breaker` | `creature` | `combat_damage_treasure_trigger_status, treasure_impulse_draw_status` | `none` |
| `Ragavan, Nimble Pilferer` | `creature` | `combat_damage_exile_top_opponent_library_status, combat_damage_treasure_trigger_status, dash_status, temporary_cast_permission_status` | `none` |
| `Ranger-Captain of Eos` | `creature` | `library_shuffle_status, sacrifice_noncreature_silence_status` | `none` |
| `Reiterate` | `copy_spell` | `buyback_status, choose_new_targets_status` | `none` |
| `Return the Favor` | `copy_spell` | `change_target_mode_status, copy_activated_triggered_ability_status, spree_additional_cost_status` | `none` |
| `Reverberate` | `copy_spell` | `choose_new_targets_status` | `none` |
| `Rite of Flame` | `ramp_ritual` | `graveyard_named_copy_scaling_status` | `none` |
| `Skyclave Apparition` | `creature` | `leave_battlefield_illusion_token_status` | `none` |
| `Storm-Kiln Artist` | `creature` | `artifact_power_bonus_status, magecraft_treasure_status` | `none` |
| `Sundering Eruption // Volcanic Fissure` | `remove_permanent` | `cant_block_mode_status` | `basic_land_compensation_status` |
| `Sundown Pass` | `land` | `none` | `conditional_enters_tapped_status` |
| `Tablet of Discovery` | `ramp_permanent` | `conditional_instant_sorcery_mana_status, etb_milled_card_play_status` | `none` |
| `Tarnished Citadel` | `land` | `none` | `conditional_mana_modes[0].life_loss_status, conditional_mana_modes[0].status, conditional_mana_modes[1].status, conditional_mana_modes[2].status, conditional_mana_modes[3].status, conditional_mana_modes[4].status, conditional_mana_modes[5].status, conditional_mana_modes_status, life_loss_on_colored_mana_status` |
| `Touch the Spirit Realm` | `temporary_exile_return_next_end_step` | `etb_until_source_leaves_status` | `none` |
| `Underworld Breach` | `passive` | `end_step_sacrifice_status, escape_grant_status` | `none` |
| `Untimely Malfunction` | `remove_permanent` | `cant_block_mode_status, redirect_target_mode_status` | `none` |
| `Vandalblast` | `remove_permanent` | `overload_status` | `none` |

## Families

| Annotation fields | Count | Cards |
| --- | ---: | --- |
| `none` | 8 | `City of Brass`; `Clifftop Retreat`; `Elves of Deep Shadow`; `Erode`; `Inspiring Vantage`; `Mana Confluence`; `Sundown Pass`; `Tarnished Citadel` |
| `choose_new_targets_status` | 2 | `Dualcaster Mage`; `Reverberate` |
| `activated_ability_lock_status` | 1 | `Grand Abolisher` |
| `activated_artifact_reanimation_status` | 1 | `Goblin Engineer` |
| `activated_top_five_nonhuman_creature_to_battlefield_status` | 1 | `Kinnan, Bonder Prodigy` |
| `activated_untap_another_permanent_status + etb_discard_creature_tutor_status` | 1 | `Formidable Speaker` |
| `activation_execution_status` | 1 | `Aetherflux Reservoir` |
| `alternate_cost_exile_blue_card_status` | 1 | `Force of Negation` |
| `artifact_power_bonus_status + magecraft_treasure_status` | 1 | `Storm-Kiln Artist` |
| `back_face.runtime_status + back_face_runtime_status + boast_runtime_status` | 1 | `Birgi, God of Storytelling // Harnfel, Horn of Bounty` |
| `buyback_status + choose_new_targets_status` | 1 | `Reiterate` |
| `cant_block_mode_status` | 1 | `Sundering Eruption // Volcanic Fissure` |
| `cant_block_mode_status + redirect_target_mode_status` | 1 | `Untimely Malfunction` |
| `change_target_mode_status + copy_activated_triggered_ability_status + spree_additional_cost_status` | 1 | `Return the Favor` |
| `combat_damage_exile_top_opponent_library_status + combat_damage_treasure_trigger_status + dash_status + temporary_cast_permission_status` | 1 | `Ragavan, Nimble Pilferer` |
| `combat_damage_treasure_trigger_status + treasure_impulse_draw_status` | 1 | `Professional Face-Breaker` |
| `conditional_instant_sorcery_mana_status + etb_milled_card_play_status` | 1 | `Tablet of Discovery` |
| `counter_unless_pays_status + soft_counter_payment_status + storm_copy_status` | 1 | `Flusterstorm` |
| `cycle_trigger_status + cycling_status` | 1 | `Magmakin Artillerist` |
| `death_return_status` | 1 | `Enduring Vitality` |
| `end_step_sacrifice_status + escape_grant_status` | 1 | `Underworld Breach` |
| `etb_until_source_leaves_status` | 1 | `Touch the Spirit Realm` |
| `extort_execution_status` | 1 | `Blind Obedience` |
| `graveyard_named_copy_scaling_status` | 1 | `Rite of Flame` |
| `leave_battlefield_illusion_token_status` | 1 | `Skyclave Apparition` |
| `library_shuffle_status + sacrifice_noncreature_silence_status` | 1 | `Ranger-Captain of Eos` |
| `mana_source_mill_status` | 1 | `Millikin` |
| `modes[0].mode_status` | 1 | `Boros Charm` |
| `overload_status` | 1 | `Vandalblast` |
| `static_ability_status` | 1 | `Drannith Magistrate` |
| `upkeep_win_status` | 1 | `Knuckles the Echidna` |
