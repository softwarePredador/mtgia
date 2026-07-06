# XMage Authoritative Exact Scope Split

- Generated at: `2026-07-06T01:03:50+00:00`
- Status: `ready`
- Mutations performed: `[]`

## Summary

`{"adapter_work_unit_counts": {"ramp_permanent::xmage_artifact_mana_source_variant_review_v1": 97, "ramp_permanent::xmage_creature_mana_source_variant_review_v1": 46}, "blocked_reason_counts": {"activated_damage_oracle_not_simple": 32, "activated_damage_source_cost_not_supported": 7, "activated_damage_source_discard_cost_not_supported": 1, "activated_destroy_oracle_not_simple": 15, "activated_destroy_source_cost_not_supported": 20, "activated_destroy_source_not_simple_destroy_effect": 2, "activated_destroy_source_target_not_supported": 5, "activated_draw_discard_oracle_cost_not_supported": 1, "activated_draw_oracle_cost_not_supported": 8, "activated_draw_oracle_not_simple": 5, "activated_draw_source_cost_not_supported": 1, "activated_graveyard_exile_oracle_not_simple": 3, "activated_graveyard_to_library_oracle_not_simple": 1, "activated_library_tutor_oracle_cost_not_supported": 12, "activated_life_gain_oracle_cost_not_supported": 11, "activated_life_gain_oracle_not_simple": 10, "activated_recursion_battlefield_oracle_cost_not_supported": 4, "activated_recursion_oracle_cost_not_supported": 3, "activated_recursion_oracle_not_simple": 3, "activated_self_add_counters_oracle_not_simple": 1, "activated_self_add_counters_source_cost_not_supported": 5, "activated_self_boost_oracle_cost_not_supported": 18, "activated_self_boost_oracle_not_simple": 14, "activated_self_boost_source_oracle_cost_mismatch": 1, "activated_target_boost_oracle_cost_not_supported": 4, "activated_target_boost_oracle_not_simple": 14, "activated_target_keyword_oracle_cost_not_supported": 10, "activated_target_keyword_source_target_not_supported": 1, "activated_token_source_cost_not_supported": 11, "activated_token_source_create_token_not_fixed": 2, "activated_token_source_not_simple_activated": 2, "add_counters_ability_class_not_simple": 4, "add_counters_counter_not_fixed": 8, "add_counters_effect_class_not_pure": 63, "add_counters_oracle_not_simple": 1, "add_counters_target_not_supported": 2, "additional_cost_detected": 97, "attack_target_keyword_oracle_static_keyword_not_exact": 1, "attack_target_keyword_source_keyword_not_supported": 5, "attack_target_keyword_source_oracle_mismatch": 1, "aura_static_pt_oracle_not_exact_fixed": 19, "board_wipe_ability_class_not_simple": 67, "board_wipe_damage_amount_not_fixed": 9, "board_wipe_damage_scope_not_supported": 6, "board_wipe_destroy_scope_not_supported": 17, "board_wipe_effect_class_not_supported": 81, "board_wipe_oracle_not_simple": 37, "board_wipe_source_multiple_damage_all_effects": 1, "boost_all_source_not_single_fixed": 8, "boost_controlled_source_filter_not_supported": 1, "boost_controlled_source_not_single_fixed": 4, "boost_draw_oracle_not_exact_fixed": 2, "boost_keyword_draw_source_not_exact_fixed": 2, "boost_keyword_oracle_not_simple": 2, "boost_keyword_source_not_single_fixed": 14, "boost_target_source_not_single_fixed": 20, "bounce_ability_class_not_simple": 28, "bounce_draw_ability_class_not_simple": 3, "bounce_draw_oracle_not_exact_fixed": 1, "bounce_draw_oracle_not_simple": 1, "bounce_effect_class_not_pure": 41, "bounce_scry_oracle_not_exact_fixed": 1, "bounce_target_not_supported": 20, "combat_damage_draw_amount_damage_dealt_not_supported": 1, "combat_damage_draw_count_not_fixed": 1, "counter_ability_class_not_simple": 19, "counter_draw_oracle_not_simple": 1, "counter_draw_target_not_supported": 4, "counter_effect_class_not_pure": 35, "counter_oracle_not_simple": 2, "counter_target_not_supported": 11, "counter_unless_pays_oracle_not_exact_fixed_generic": 7, "damage_additional_cost_not_supported": 10, "damage_amount_not_fixed": 12, "damage_draw_oracle_not_exact_fixed": 6, "damage_effect_class_not_pure": 103, "damage_life_gain_oracle_not_simple": 7, "damage_life_gain_source_not_fixed": 18, "damage_target_not_supported": 8, "destroy_additional_cost_not_supported": 15, "destroy_draw_oracle_not_exact_fixed": 2, "destroy_effect_class_not_pure": 124, "destroy_life_gain_ability_class_not_simple": 2, "destroy_life_gain_source_not_fixed": 14, "destroy_scry_ability_class_not_simple": 1, "destroy_target_not_supported": 33, "destroy_treasure_effect_classes_not_exact": 11, "dies_damage_amount_not_fixed": 1, "dies_damage_target_not_supported": 1, "dies_draw_count_not_fixed": 2, "dies_life_gain_amount_not_fixed": 3, "dies_recursion_optional_cost_not_supported": 1, "dies_token_oracle_not_simple": 3, "draw_additional_cost_not_supported": 5, "draw_discard_spell_ability_class_not_simple": 3, "draw_discard_spell_oracle_not_exact_fixed": 5, "draw_discard_spell_oracle_not_simple": 6, "draw_effect_class_not_pure": 428, "draw_lose_life_spell_ability_class_not_simple": 3, "draw_lose_life_spell_oracle_not_exact_fixed": 3, "draw_put_land_oracle_not_exact_fixed": 1, "draw_self_cost_reduction_condition_not_supported": 1, "draw_self_cost_reduction_oracle_not_exact_fixed": 1, "dynamic_count_damage_composite_count_not_supported": 1, "dynamic_count_damage_oracle_composite_count_not_supported": 3, "dynamic_count_damage_oracle_filter_not_supported": 1, "equipment_static_oracle_not_exact_fixed": 26, "equipment_static_source_oracle_mismatch": 2, "etb_add_counters_source_oracle_mismatch": 1, "etb_bounce_target_not_supported": 3, "etb_destroy_source_effect_count_not_supported": 1, "etb_draw_count_not_fixed": 2, "etb_draw_lose_life_oracle_not_exact_fixed": 1, "etb_library_pick_oracle_not_simple": 3, "etb_library_tutor_oracle_not_simple": 1, "etb_library_tutor_oracle_target_not_supported": 1, "etb_library_tutor_source_oracle_target_subtypes_mismatch": 2, "etb_library_tutor_to_hand_oracle_target_not_supported": 1, "etb_library_tutor_to_hand_source_oracle_count_mismatch": 3, "etb_library_tutor_to_hand_source_oracle_target_subtypes_mismatch": 2, "etb_library_tutor_to_hand_source_oracle_up_to_count_mismatch": 1, "etb_life_gain_amount_not_fixed": 12, "etb_recursion_battlefield_target_not_supported": 1, "etb_recursion_target_not_supported": 3, "exile_compensation_token_ability_class_not_simple": 1, "exile_compensation_token_oracle_not_simple": 1, "exile_compensation_token_target_not_supported": 1, "exile_effect_class_not_pure": 32, "exile_oracle_not_simple": 8, "exile_target_not_supported": 19, "graveyard_count_boost_source_not_single": 1, "graveyard_count_damage_adventure_filter_not_supported": 1, "graveyard_count_damage_exile_x_graveyard_cost_not_supported": 2, "graveyard_exile_ability_class_not_supported": 1, "graveyard_self_return_ability_class_not_simple": 4, "graveyard_self_return_oracle_not_simple": 4, "keyword_draw_source_not_exact_fixed": 2, "library_pick_ability_class_not_simple": 1, "library_tutor_oracle_not_simple": 1, "library_tutor_oracle_target_not_supported": 2, "library_tutor_source_distinct_names_not_supported": 2, "life_gain_amount_not_fixed": 19, "life_gain_draw_ability_class_not_simple": 3, "life_gain_draw_oracle_not_exact_fixed": 3, "life_gain_draw_oracle_not_simple": 1, "life_gain_effect_class_not_pure": 85, "life_gain_oracle_not_simple": 11, "look_library_pick_oracle_not_simple": 8, "look_library_pick_oracle_target_not_supported": 2, "look_library_pick_source_target_not_supported": 1, "mana_source_activated_draw_oracle_not_simple": 2, "mana_source_effect_class_not_simple": 24, "mana_source_oracle_not_simple": 98, "mana_source_sacrifice_oracle_not_simple": 1, "mana_source_safe_ability_missing": 125, "mana_source_simple_source_missing_tap_cost": 1, "mana_source_source_conditional_mana_not_supported": 11, "mana_source_source_discard_cost_not_supported": 5, "mana_source_source_exile_cost_not_supported": 1, "mana_source_source_pay_life_cost_not_supported": 4, "mana_source_source_sacrifice_cost_not_supported": 25, "mana_source_source_sacrifice_target_cost_not_supported": 6, "mana_source_spell_not_supported": 1, "mana_source_unsafe_ability_class": 133, "mill_return_ability_class_not_simple": 2, "not_instant_or_sorcery_spell": 3795, "not_one_shot_spell_ability": 254, "play_lands_from_graveyard_ability_class_not_simple_static": 1, "recursion_ability_class_not_simple": 9, "recursion_auxiliary_flashback_cost_not_supported": 1, "recursion_auxiliary_primary_oracle_not_simple": 1, "recursion_battlefield_ability_class_not_simple": 6, "recursion_battlefield_all_ability_class_not_simple": 2, "recursion_battlefield_all_oracle_not_supported": 1, "recursion_battlefield_counter_ability_class_not_simple": 2, "recursion_effect_class_not_pure": 374, "recursion_exile_self_ability_class_not_simple": 1, "recursion_exile_self_target_not_supported": 1, "scry_draw_oracle_not_exact_fixed": 1, "spell_cast_add_counters_oracle_filter_not_supported": 1, "spell_cast_draw_oracle_filter_not_supported": 3, "spell_cast_draw_source_oracle_mismatch": 1, "static_controlled_pt_oracle_filter_not_supported": 10, "static_controlled_pt_oracle_not_exact": 2, "static_controlled_pt_source_oracle_mismatch": 1, "static_cost_reduction_colored_mana_not_supported": 2, "static_global_pt_not_permanent": 1, "static_global_pt_oracle_dynamic_not_supported": 3, "static_global_pt_oracle_filter_not_supported": 2, "static_global_pt_source_dynamic_or_phase_not_supported": 1, "static_graveyard_count_boost_oracle_not_exact": 1, "static_graveyard_count_pt_oracle_not_exact": 35, "static_graveyard_threshold_boost_oracle_not_exact": 7, "static_keyword_not_creature": 1, "static_protection_oracle_not_color_or_card_type_or_subtype_exact": 4, "target_player_draw_spell_ability_class_not_simple": 4, "target_player_draw_spell_oracle_not_exact_fixed": 3, "token_description_keyword_not_supported": 27, "token_description_not_creature_token": 25, "token_land_token_runtime_not_supported": 1, "token_source_additional_tokens_not_supported": 5, "token_source_create_token_not_fixed": 28, "token_source_not_single_create_token_effect": 1, "tutor_ability_class_not_simple": 45, "tutor_effect_class_not_supported": 145, "unsupported_adapter_work_unit": 3, "x_damage_alternative_timing_not_supported": 1, "x_damage_buyback_not_supported": 1}, "considered_supported_work_unit_rows": 7390, "family_counts": {"xmage_simple_mana_source_with_unmodeled_auxiliary": 143}, "proposal_count": 143, "proposal_status_counts": {"batch_pg_candidate_after_precheck": 143}, "safe_for_batch_pg_package_count": 143, "scope_counts": {"xmage_simple_tap_mana_source_permanent_v1": 143}}`

## Selected Proposals

| Card | Family | Scope | Effect | Logical rule key |
| --- | --- | --- | --- | --- |
| `Aetheric Amplifier` | `xmage_simple_mana_source_with_unmodeled_auxiliary` | `xmage_simple_tap_mana_source_permanent_v1` | `ramp_permanent` | `battle_rule_v1:502dfefc50b843a5d2e74c532bcc8c73` |
| `Agility Bobblehead` | `xmage_simple_mana_source_with_unmodeled_auxiliary` | `xmage_simple_tap_mana_source_permanent_v1` | `ramp_permanent` | `battle_rule_v1:37f2bca6cab49aabc2d46393cebcde7c` |
| `Ancient Cornucopia` | `xmage_simple_mana_source_with_unmodeled_auxiliary` | `xmage_simple_tap_mana_source_permanent_v1` | `ramp_permanent` | `battle_rule_v1:4703e4c9151e7c1c263d85f89f9ac852` |
| `Arc Reactor` | `xmage_simple_mana_source_with_unmodeled_auxiliary` | `xmage_simple_tap_mana_source_permanent_v1` | `ramp_permanent` | `battle_rule_v1:8fb0857a957bdbc6678ac0f2d74a2ecc` |
| `Arixmethes, Slumbering Isle` | `xmage_simple_mana_source_with_unmodeled_auxiliary` | `xmage_simple_tap_mana_source_permanent_v1` | `ramp_permanent` | `battle_rule_v1:e38b296fb40bb7cc7ec45b261a98c9ae` |
| `Armored Scrapgorger` | `xmage_simple_mana_source_with_unmodeled_auxiliary` | `xmage_simple_tap_mana_source_permanent_v1` | `ramp_permanent` | `battle_rule_v1:e69094b295a4d4277c11beb8cb471a0e` |
| `Atarka Monument` | `xmage_simple_mana_source_with_unmodeled_auxiliary` | `xmage_simple_tap_mana_source_permanent_v1` | `ramp_permanent` | `battle_rule_v1:3c5f77b352e8e6464283f430495f3874` |
| `Azorius Keyrune` | `xmage_simple_mana_source_with_unmodeled_auxiliary` | `xmage_simple_tap_mana_source_permanent_v1` | `ramp_permanent` | `battle_rule_v1:caf09952e4a3ccca49e5bde51e4f30ba` |
| `Bandit's Haul` | `xmage_simple_mana_source_with_unmodeled_auxiliary` | `xmage_simple_tap_mana_source_permanent_v1` | `ramp_permanent` | `battle_rule_v1:8334a4cf3fd678c4af9da1c48b1d76a8` |
| `Bonder's Ornament` | `xmage_simple_mana_source_with_unmodeled_auxiliary` | `xmage_simple_tap_mana_source_permanent_v1` | `ramp_permanent` | `battle_rule_v1:8374caffe21b566c3c49f2059e01b71a` |
| `Boros Keyrune` | `xmage_simple_mana_source_with_unmodeled_auxiliary` | `xmage_simple_tap_mana_source_permanent_v1` | `ramp_permanent` | `battle_rule_v1:54e1e30b80600e4bd0d97aec628a741a` |
| `Bounty Board` | `xmage_simple_mana_source_with_unmodeled_auxiliary` | `xmage_simple_tap_mana_source_permanent_v1` | `ramp_permanent` | `battle_rule_v1:c9f7574445b6a9d978ad244a363f298a` |
| `Bronze Walrus` | `xmage_simple_mana_source_with_unmodeled_auxiliary` | `xmage_simple_tap_mana_source_permanent_v1` | `ramp_permanent` | `battle_rule_v1:b16868a806d66cc15edbab5db7321d70` |
| `Bugenhagen, Wise Elder` | `xmage_simple_mana_source_with_unmodeled_auxiliary` | `xmage_simple_tap_mana_source_permanent_v1` | `ramp_permanent` | `battle_rule_v1:685496ca5c940607dbf05224411fde9e` |
| `Canopy Tactician` | `xmage_simple_mana_source_with_unmodeled_auxiliary` | `xmage_simple_tap_mana_source_permanent_v1` | `ramp_permanent` | `battle_rule_v1:7854c5984172f30e5cbbff518fe011fa` |
| `Centaur Nurturer` | `xmage_simple_mana_source_with_unmodeled_auxiliary` | `xmage_simple_tap_mana_source_permanent_v1` | `ramp_permanent` | `battle_rule_v1:6d553988a25ab6b8b1d620d891f33964` |
| `Ceta Disciple` | `xmage_simple_mana_source_with_unmodeled_auxiliary` | `xmage_simple_tap_mana_source_permanent_v1` | `ramp_permanent` | `battle_rule_v1:a76cf15005eaf68735083be6355a75fe` |
| `Chronatog Totem` | `xmage_simple_mana_source_with_unmodeled_auxiliary` | `xmage_simple_tap_mana_source_permanent_v1` | `ramp_permanent` | `battle_rule_v1:9c1adc19b36d8c321d53bfd5a2999e1c` |
| `Crossroads Candleguide` | `xmage_simple_mana_source_with_unmodeled_auxiliary` | `xmage_simple_tap_mana_source_permanent_v1` | `ramp_permanent` | `battle_rule_v1:060bef5aafe8a3f4eab54d0033db00bc` |
| `Crystal Skull, Isu Spyglass` | `xmage_simple_mana_source_with_unmodeled_auxiliary` | `xmage_simple_tap_mana_source_permanent_v1` | `ramp_permanent` | `battle_rule_v1:d750fbdfc6e6bb778848127f5d8b7c63` |
| `Cultivator's Caravan` | `xmage_simple_mana_source_with_unmodeled_auxiliary` | `xmage_simple_tap_mana_source_permanent_v1` | `ramp_permanent` | `battle_rule_v1:7e8eb61ab716c7d82c2cbf2a56a786ab` |
| `Dawnhart Rejuvenator` | `xmage_simple_mana_source_with_unmodeled_auxiliary` | `xmage_simple_tap_mana_source_permanent_v1` | `ramp_permanent` | `battle_rule_v1:6d553988a25ab6b8b1d620d891f33964` |
| `Deathcap Cultivator` | `xmage_simple_mana_source_with_unmodeled_auxiliary` | `xmage_simple_tap_mana_source_permanent_v1` | `ramp_permanent` | `battle_rule_v1:0c0412bc29f02b8628b72852c459f018` |
| `Decanter of Endless Water` | `xmage_simple_mana_source_with_unmodeled_auxiliary` | `xmage_simple_tap_mana_source_permanent_v1` | `ramp_permanent` | `battle_rule_v1:11220ab224619a401fe23ef1288c1f89` |
| `Dimir Keyrune` | `xmage_simple_mana_source_with_unmodeled_auxiliary` | `xmage_simple_tap_mana_source_permanent_v1` | `ramp_permanent` | `battle_rule_v1:e5a1da6e8eabf83c748d675f81508c83` |
| `Dragon's Hoard` | `xmage_simple_mana_source_with_unmodeled_auxiliary` | `xmage_simple_tap_mana_source_permanent_v1` | `ramp_permanent` | `battle_rule_v1:8433b66fd37c7bc3a3de15ca6de33606` |
| `Dragonstorm Globe` | `xmage_simple_mana_source_with_unmodeled_auxiliary` | `xmage_simple_tap_mana_source_permanent_v1` | `ramp_permanent` | `battle_rule_v1:687eaff0fcf8eb414843892007f63122` |
| `Dromoka Monument` | `xmage_simple_mana_source_with_unmodeled_auxiliary` | `xmage_simple_tap_mana_source_permanent_v1` | `ramp_permanent` | `battle_rule_v1:3656c05932a01fa6c564ce37670866fe` |
| `Drover of the Mighty` | `xmage_simple_mana_source_with_unmodeled_auxiliary` | `xmage_simple_tap_mana_source_permanent_v1` | `ramp_permanent` | `battle_rule_v1:d4d0d6164b84e2ec2c458941420e91f3` |
| `Drumhunter` | `xmage_simple_mana_source_with_unmodeled_auxiliary` | `xmage_simple_tap_mana_source_permanent_v1` | `ramp_permanent` | `battle_rule_v1:564c99e3d2a59b3540c81137769970d6` |
| `Dungeon Map` | `xmage_simple_mana_source_with_unmodeled_auxiliary` | `xmage_simple_tap_mana_source_permanent_v1` | `ramp_permanent` | `battle_rule_v1:923316cbee71d0d4e188f25bfa9c69f1` |
| `Ebony Fly` | `xmage_simple_mana_source_with_unmodeled_auxiliary` | `xmage_simple_tap_mana_source_permanent_v1` | `ramp_permanent` | `battle_rule_v1:bfe318c2461b81a3873dfcb359e29d17` |
| `Elvish Aberration` | `xmage_simple_mana_source_with_unmodeled_auxiliary` | `xmage_simple_tap_mana_source_permanent_v1` | `ramp_permanent` | `battle_rule_v1:69901802e245f3d9a5a2463df3ca3afb` |
| `Elvish Harbinger` | `xmage_simple_mana_source_with_unmodeled_auxiliary` | `xmage_simple_tap_mana_source_permanent_v1` | `ramp_permanent` | `battle_rule_v1:77bbbd623af82ee07b2e3972d38510eb` |
| `Endurance Bobblehead` | `xmage_simple_mana_source_with_unmodeled_auxiliary` | `xmage_simple_tap_mana_source_permanent_v1` | `ramp_permanent` | `battle_rule_v1:83d4335a5a8a1bd64c6111e8659e90f2` |
| `Exuberant Firestoker` | `xmage_simple_mana_source_with_unmodeled_auxiliary` | `xmage_simple_tap_mana_source_permanent_v1` | `ramp_permanent` | `battle_rule_v1:3cc95e346b3939455b7433ae6eb86165` |
| `Eye of Ojer Taq // Apex Observatory` | `xmage_simple_mana_source_with_unmodeled_auxiliary` | `xmage_simple_tap_mana_source_permanent_v1` | `ramp_permanent` | `battle_rule_v1:3677a31264076d4d4957b900853dd85d` |
| `Fieldmist Borderpost` | `xmage_simple_mana_source_with_unmodeled_auxiliary` | `xmage_simple_tap_mana_source_permanent_v1` | `ramp_permanent` | `battle_rule_v1:2fde804a9c8937336c0560028d75ae2b` |
| `Firdoch Core` | `xmage_simple_mana_source_with_unmodeled_auxiliary` | `xmage_simple_tap_mana_source_permanent_v1` | `ramp_permanent` | `battle_rule_v1:59fa95f270c6bd6237760061c49eaf8d` |
| `Firewild Borderpost` | `xmage_simple_mana_source_with_unmodeled_auxiliary` | `xmage_simple_tap_mana_source_permanent_v1` | `ramp_permanent` | `battle_rule_v1:ba21f18eead830411f6ed6e76977d164` |
| `Foriysian Totem` | `xmage_simple_mana_source_with_unmodeled_auxiliary` | `xmage_simple_tap_mana_source_permanent_v1` | `ramp_permanent` | `battle_rule_v1:40134f0bd92207623c577ea144486ec7` |
| `Fountain of Ichor` | `xmage_simple_mana_source_with_unmodeled_auxiliary` | `xmage_simple_tap_mana_source_permanent_v1` | `ramp_permanent` | `battle_rule_v1:4848d3b218e558bf9219651d767f8deb` |
| `Frog Butler` | `xmage_simple_mana_source_with_unmodeled_auxiliary` | `xmage_simple_tap_mana_source_permanent_v1` | `ramp_permanent` | `battle_rule_v1:562709c7ab2d24c5069647bc7801f202` |
| `Gatewatch Beacon` | `xmage_simple_mana_source_with_unmodeled_auxiliary` | `xmage_simple_tap_mana_source_permanent_v1` | `ramp_permanent` | `battle_rule_v1:0d5dfd5f0a927d414d79867d7db17df9` |
| `Golgari Keyrune` | `xmage_simple_mana_source_with_unmodeled_auxiliary` | `xmage_simple_tap_mana_source_permanent_v1` | `ramp_permanent` | `battle_rule_v1:d0a00994273fe7248b3881496d939de0` |
| `Gruul Keyrune` | `xmage_simple_mana_source_with_unmodeled_auxiliary` | `xmage_simple_tap_mana_source_permanent_v1` | `ramp_permanent` | `battle_rule_v1:d5319ceede6e997047f550137e0043c7` |
| `Guardian Idol` | `xmage_simple_mana_source_with_unmodeled_auxiliary` | `xmage_simple_tap_mana_source_permanent_v1` | `ramp_permanent` | `battle_rule_v1:fba989bab95463c1e439c6257a3bc4b6` |
| `Guy in the Chair` | `xmage_simple_mana_source_with_unmodeled_auxiliary` | `xmage_simple_tap_mana_source_permanent_v1` | `ramp_permanent` | `battle_rule_v1:4f2913fa208810c45b91260b6b1c85c4` |
| `Hardbristle Bandit` | `xmage_simple_mana_source_with_unmodeled_auxiliary` | `xmage_simple_tap_mana_source_permanent_v1` | `ramp_permanent` | `battle_rule_v1:e45b1136b49b2b00de90d86f7c3b5c55` |
| `Hierophant's Chalice` | `xmage_simple_mana_source_with_unmodeled_auxiliary` | `xmage_simple_tap_mana_source_permanent_v1` | `ramp_permanent` | `battle_rule_v1:9e3a89d5c5aa7fd496fb045b949865c6` |
| `Honor-Worn Shaku` | `xmage_simple_mana_source_with_unmodeled_auxiliary` | `xmage_simple_tap_mana_source_permanent_v1` | `ramp_permanent` | `battle_rule_v1:e03b4fcca81b9b75dc165e880b456113` |
| `Honored Heirloom` | `xmage_simple_mana_source_with_unmodeled_auxiliary` | `xmage_simple_tap_mana_source_permanent_v1` | `ramp_permanent` | `battle_rule_v1:ea8afa0ed2e725bb7491e9444d49aaf2` |
| `Indatha Crystal` | `xmage_simple_mana_source_with_unmodeled_auxiliary` | `xmage_simple_tap_mana_source_permanent_v1` | `ramp_permanent` | `battle_rule_v1:775bd0cbe527435301f0a1c9ba934902` |
| `Inherited Envelope` | `xmage_simple_mana_source_with_unmodeled_auxiliary` | `xmage_simple_tap_mana_source_permanent_v1` | `ramp_permanent` | `battle_rule_v1:e01bf910673454c4c4ea2dbccfc0a466` |
| `Intrepid Paleontologist` | `xmage_simple_mana_source_with_unmodeled_auxiliary` | `xmage_simple_tap_mana_source_permanent_v1` | `ramp_permanent` | `battle_rule_v1:7bc9ff23b91ab4ac4cf90d8c076e19ae` |
| `Ketria Crystal` | `xmage_simple_mana_source_with_unmodeled_auxiliary` | `xmage_simple_tap_mana_source_permanent_v1` | `ramp_permanent` | `battle_rule_v1:d1011e9514943347f7150545964b3ae4` |
| `Kolaghan Monument` | `xmage_simple_mana_source_with_unmodeled_auxiliary` | `xmage_simple_tap_mana_source_permanent_v1` | `ramp_permanent` | `battle_rule_v1:13792d2d6c33fe8f171da553cbdad9a1` |
| `Lantern of Revealing` | `xmage_simple_mana_source_with_unmodeled_auxiliary` | `xmage_simple_tap_mana_source_permanent_v1` | `ramp_permanent` | `battle_rule_v1:561dc199d1854484375a99dfba65223c` |
| `Laser Screwdriver` | `xmage_simple_mana_source_with_unmodeled_auxiliary` | `xmage_simple_tap_mana_source_permanent_v1` | `ramp_permanent` | `battle_rule_v1:0721b82a83ff1062943ac75278c3360b` |
| `Lavabrink Floodgates` | `xmage_simple_mana_source_with_unmodeled_auxiliary` | `xmage_simple_tap_mana_source_permanent_v1` | `ramp_permanent` | `battle_rule_v1:d574a2cce4c9905f66829dd0239fa3d4` |
| `Llanowar Loamspeaker` | `xmage_simple_mana_source_with_unmodeled_auxiliary` | `xmage_simple_tap_mana_source_permanent_v1` | `ramp_permanent` | `battle_rule_v1:f9e0d1dc17362fe888df33b573a3ab44` |
| `Lullmage's Familiar` | `xmage_simple_mana_source_with_unmodeled_auxiliary` | `xmage_simple_tap_mana_source_permanent_v1` | `ramp_permanent` | `battle_rule_v1:065723ebcc5869d6342dcbfb0534dc87` |
| `Magnifying Glass` | `xmage_simple_mana_source_with_unmodeled_auxiliary` | `xmage_simple_tap_mana_source_permanent_v1` | `ramp_permanent` | `battle_rule_v1:91a67f81a20603de490f14fa5e796cc5` |
| `Magus of the Library` | `xmage_simple_mana_source_with_unmodeled_auxiliary` | `xmage_simple_tap_mana_source_permanent_v1` | `ramp_permanent` | `battle_rule_v1:fc0a7b1c3c0e4f98b0eed1abf98fdeb8` |
| `Mana Geode` | `xmage_simple_mana_source_with_unmodeled_auxiliary` | `xmage_simple_tap_mana_source_permanent_v1` | `ramp_permanent` | `battle_rule_v1:a600e272b62cf9faa415608d78601b6f` |
| `Meteorite` | `xmage_simple_mana_source_with_unmodeled_auxiliary` | `xmage_simple_tap_mana_source_permanent_v1` | `ramp_permanent` | `battle_rule_v1:9cf200eeeaa2ad2f96118dc357715b55` |
| `Midnight Clock` | `xmage_simple_mana_source_with_unmodeled_auxiliary` | `xmage_simple_tap_mana_source_permanent_v1` | `ramp_permanent` | `battle_rule_v1:e8f62e2f4d39071bee4a30c39d40aa56` |
| `Misleading Signpost` | `xmage_simple_mana_source_with_unmodeled_auxiliary` | `xmage_simple_tap_mana_source_permanent_v1` | `ramp_permanent` | `battle_rule_v1:e67f9475df243da9cc5e567ce9820e16` |
| `Mistvein Borderpost` | `xmage_simple_mana_source_with_unmodeled_auxiliary` | `xmage_simple_tap_mana_source_permanent_v1` | `ramp_permanent` | `battle_rule_v1:8df53a3da0eaf32947a886b91cf80ea6` |
| `Model of Unity` | `xmage_simple_mana_source_with_unmodeled_auxiliary` | `xmage_simple_tap_mana_source_permanent_v1` | `ramp_permanent` | `battle_rule_v1:d436a662d97f328873f49c4cdf7bec41` |
| `Mox Tantalite` | `xmage_simple_mana_source_with_unmodeled_auxiliary` | `xmage_simple_tap_mana_source_permanent_v1` | `ramp_permanent` | `battle_rule_v1:cfb4b68b9408f1713236782c7556d3be` |
| `Mystic Skull // Mystic Monstrosity` | `xmage_simple_mana_source_with_unmodeled_auxiliary` | `xmage_simple_tap_mana_source_permanent_v1` | `ramp_permanent` | `battle_rule_v1:84b5585eb8ab992334a23912261ff573` |
| `Necra Disciple` | `xmage_simple_mana_source_with_unmodeled_auxiliary` | `xmage_simple_tap_mana_source_permanent_v1` | `ramp_permanent` | `battle_rule_v1:a813c91a6f878a45f0e15754abd91f43` |
| `Oasis Gardener` | `xmage_simple_mana_source_with_unmodeled_auxiliary` | `xmage_simple_tap_mana_source_permanent_v1` | `ramp_permanent` | `battle_rule_v1:6d553988a25ab6b8b1d620d891f33964` |
| `Ojutai Monument` | `xmage_simple_mana_source_with_unmodeled_auxiliary` | `xmage_simple_tap_mana_source_permanent_v1` | `ramp_permanent` | `battle_rule_v1:caf09952e4a3ccca49e5bde51e4f30ba` |
| `Orzhov Keyrune` | `xmage_simple_mana_source_with_unmodeled_auxiliary` | `xmage_simple_tap_mana_source_permanent_v1` | `ramp_permanent` | `battle_rule_v1:f78007d46b5723e7ba3e22406d57f86a` |
| `Paradise Druid` | `xmage_simple_mana_source_with_unmodeled_auxiliary` | `xmage_simple_tap_mana_source_permanent_v1` | `ramp_permanent` | `battle_rule_v1:c58180fbaea273015475a2c1ae3d59f6` |
| `Patchwork Banner` | `xmage_simple_mana_source_with_unmodeled_auxiliary` | `xmage_simple_tap_mana_source_permanent_v1` | `ramp_permanent` | `battle_rule_v1:222ef988f305ae5dde3e28643d45e365` |
| `Patriar's Seal` | `xmage_simple_mana_source_with_unmodeled_auxiliary` | `xmage_simple_tap_mana_source_permanent_v1` | `ramp_permanent` | `battle_rule_v1:124d4ca9bdad9c75d25dd2be225bb1b2` |
| `Perception Bobblehead` | `xmage_simple_mana_source_with_unmodeled_auxiliary` | `xmage_simple_tap_mana_source_permanent_v1` | `ramp_permanent` | `battle_rule_v1:b31e53f380b825f334353133a02ff09b` |
| `Phial of Galadriel` | `xmage_simple_mana_source_with_unmodeled_auxiliary` | `xmage_simple_tap_mana_source_permanent_v1` | `ramp_permanent` | `battle_rule_v1:95eb6c1c0c5d94e74b1c318bfd07e611` |
| `Phyrexian Atlas` | `xmage_simple_mana_source_with_unmodeled_auxiliary` | `xmage_simple_tap_mana_source_permanent_v1` | `ramp_permanent` | `battle_rule_v1:a283274c8444650102c8cac9736ab057` |
| `Phyrexian Totem` | `xmage_simple_mana_source_with_unmodeled_auxiliary` | `xmage_simple_tap_mana_source_permanent_v1` | `ramp_permanent` | `battle_rule_v1:a3f599e45427b4fa17729729c28fe96e` |
| `Planar Atlas` | `xmage_simple_mana_source_with_unmodeled_auxiliary` | `xmage_simple_tap_mana_source_permanent_v1` | `ramp_permanent` | `battle_rule_v1:2ff2aada1adae08b07e044708cf63a4d` |
| `Poison Dart Frog` | `xmage_simple_mana_source_with_unmodeled_auxiliary` | `xmage_simple_tap_mana_source_permanent_v1` | `ramp_permanent` | `battle_rule_v1:562709c7ab2d24c5069647bc7801f202` |
| `Potioner's Trove` | `xmage_simple_mana_source_with_unmodeled_auxiliary` | `xmage_simple_tap_mana_source_permanent_v1` | `ramp_permanent` | `battle_rule_v1:763882defd4ee3d0ed703f7401daf287` |
| `Prize Pig` | `xmage_simple_mana_source_with_unmodeled_auxiliary` | `xmage_simple_tap_mana_source_permanent_v1` | `ramp_permanent` | `battle_rule_v1:8f514be34eab57bbab00be4a1156ed87` |
| `Progenitor's Icon` | `xmage_simple_mana_source_with_unmodeled_auxiliary` | `xmage_simple_tap_mana_source_permanent_v1` | `ramp_permanent` | `battle_rule_v1:bdc70a32ba4fb385f0f086398ee0a1dc` |
| `Radha, Heir to Keld` | `xmage_simple_mana_source_with_unmodeled_auxiliary` | `xmage_simple_tap_mana_source_permanent_v1` | `ramp_permanent` | `battle_rule_v1:9c1d17b20763cb2d6b641f521161515e` |
| `Rakdos Keyrune` | `xmage_simple_mana_source_with_unmodeled_auxiliary` | `xmage_simple_tap_mana_source_permanent_v1` | `ramp_permanent` | `battle_rule_v1:09029835918d15148bb3c58965384143` |
| `Rattleclaw Mystic` | `xmage_simple_mana_source_with_unmodeled_auxiliary` | `xmage_simple_tap_mana_source_permanent_v1` | `ramp_permanent` | `battle_rule_v1:47687077315e6c689b79ec9f93a9057d` |
| `Raugrin Crystal` | `xmage_simple_mana_source_with_unmodeled_auxiliary` | `xmage_simple_tap_mana_source_permanent_v1` | `ramp_permanent` | `battle_rule_v1:de49bab70037ead4d5398d18f755c38f` |
| `Reclusive Taxidermist` | `xmage_simple_mana_source_with_unmodeled_auxiliary` | `xmage_simple_tap_mana_source_permanent_v1` | `ramp_permanent` | `battle_rule_v1:0d1d8b85d3c1ced2e2b6897b0479ae78` |
| `Rift Sower` | `xmage_simple_mana_source_with_unmodeled_auxiliary` | `xmage_simple_tap_mana_source_permanent_v1` | `ramp_permanent` | `battle_rule_v1:e7b50ce425b113a084a8bf8cddb1fb67` |
| `Ruby, Daring Tracker` | `xmage_simple_mana_source_with_unmodeled_auxiliary` | `xmage_simple_tap_mana_source_permanent_v1` | `ramp_permanent` | `battle_rule_v1:e69ca3812e9411ae2874f1ed39697953` |
| `Runadi, Behemoth Caller` | `xmage_simple_mana_source_with_unmodeled_auxiliary` | `xmage_simple_tap_mana_source_permanent_v1` | `ramp_permanent` | `battle_rule_v1:2db61cdfc66709a57ab56fc7806d7dba` |
| `Savai Crystal` | `xmage_simple_mana_source_with_unmodeled_auxiliary` | `xmage_simple_tap_mana_source_permanent_v1` | `ramp_permanent` | `battle_rule_v1:56c926d2e30dbebdcadbe52cc77af7f3` |
| `Scorned Villager // Moonscarred Werewolf` | `xmage_simple_mana_source_with_unmodeled_auxiliary` | `xmage_simple_tap_mana_source_permanent_v1` | `ramp_permanent` | `battle_rule_v1:ba1c68e3141c669ea005efd03115c590` |
| `Scuttlemutt` | `xmage_simple_mana_source_with_unmodeled_auxiliary` | `xmage_simple_tap_mana_source_permanent_v1` | `ramp_permanent` | `battle_rule_v1:841ce8f70e3ca33dc401a2adb848c580` |
| `Seer's Lantern` | `xmage_simple_mana_source_with_unmodeled_auxiliary` | `xmage_simple_tap_mana_source_permanent_v1` | `ramp_permanent` | `battle_rule_v1:f18dd839b6c944349e81a889bf57deb6` |
| `Selesnya Keyrune` | `xmage_simple_mana_source_with_unmodeled_auxiliary` | `xmage_simple_tap_mana_source_permanent_v1` | `ramp_permanent` | `battle_rule_v1:08c3e69bfc9f43255a1df32fd9a2638c` |
| `Serum Powder` | `xmage_simple_mana_source_with_unmodeled_auxiliary` | `xmage_simple_tap_mana_source_permanent_v1` | `ramp_permanent` | `battle_rule_v1:2b13ed0b9334f2aa0dac617d4f8f19b7` |
| `Silumgar Monument` | `xmage_simple_mana_source_with_unmodeled_auxiliary` | `xmage_simple_tap_mana_source_permanent_v1` | `ramp_permanent` | `battle_rule_v1:e30791de448c53a22bba0d958c773469` |
| `Simic Keyrune` | `xmage_simple_mana_source_with_unmodeled_auxiliary` | `xmage_simple_tap_mana_source_permanent_v1` | `ramp_permanent` | `battle_rule_v1:eec51c4246d9e2e2eb909cee907986b8` |
| `Skull Prophet` | `xmage_simple_mana_source_with_unmodeled_auxiliary` | `xmage_simple_tap_mana_source_permanent_v1` | `ramp_permanent` | `battle_rule_v1:360e53cdaff5e8484d0bf652be395d35` |
| `Skyclave Relic` | `xmage_simple_mana_source_with_unmodeled_auxiliary` | `xmage_simple_tap_mana_source_permanent_v1` | `ramp_permanent` | `battle_rule_v1:f63c1b75a96992cffb7b0a550a82c0a1` |
| `Snapping Voidcraw` | `xmage_simple_mana_source_with_unmodeled_auxiliary` | `xmage_simple_tap_mana_source_permanent_v1` | `ramp_permanent` | `battle_rule_v1:7debb9077a12c4ed7084933d4c1d5338` |
| `Sol Talisman` | `xmage_simple_mana_source_with_unmodeled_auxiliary` | `xmage_simple_tap_mana_source_permanent_v1` | `ramp_permanent` | `battle_rule_v1:0b3d587a0bba09f53512bef3b3f00e3a` |
| `Sonic Screwdriver` | `xmage_simple_mana_source_with_unmodeled_auxiliary` | `xmage_simple_tap_mana_source_permanent_v1` | `ramp_permanent` | `battle_rule_v1:0cc07a3f98304c5c06b4daef35562094` |
| `Spider Manifestation` | `xmage_simple_mana_source_with_unmodeled_auxiliary` | `xmage_simple_tap_mana_source_permanent_v1` | `ramp_permanent` | `battle_rule_v1:a18fc4e742d67c9fc7d6931ca74d8b03` |
| `Spinning Wheel` | `xmage_simple_mana_source_with_unmodeled_auxiliary` | `xmage_simple_tap_mana_source_permanent_v1` | `ramp_permanent` | `battle_rule_v1:2a4609e5238968cb23e56e096ccfd8b2` |
| `Starnheim Memento` | `xmage_simple_mana_source_with_unmodeled_auxiliary` | `xmage_simple_tap_mana_source_permanent_v1` | `ramp_permanent` | `battle_rule_v1:614768ae16e945a7d203ac028bd8a7f8` |
| `Stonework Packbeast` | `xmage_simple_mana_source_with_unmodeled_auxiliary` | `xmage_simple_tap_mana_source_permanent_v1` | `ramp_permanent` | `battle_rule_v1:ea4c6cf82e5a917f9c04be33f947eeb2` |
| `Strength Bobblehead` | `xmage_simple_mana_source_with_unmodeled_auxiliary` | `xmage_simple_tap_mana_source_permanent_v1` | `ramp_permanent` | `battle_rule_v1:5395658eecf4bf359dd3cda7e4db6612` |
| `Sunbird Standard // Sunbird Effigy` | `xmage_simple_mana_source_with_unmodeled_auxiliary` | `xmage_simple_tap_mana_source_permanent_v1` | `ramp_permanent` | `battle_rule_v1:175da2fda86548f823129435c36f93fe` |
| `Sunseed Nurturer` | `xmage_simple_mana_source_with_unmodeled_auxiliary` | `xmage_simple_tap_mana_source_permanent_v1` | `ramp_permanent` | `battle_rule_v1:aec5f1a9ff7b37ca91cea1a0b655c9af` |
| `Tender Wildguide` | `xmage_simple_mana_source_with_unmodeled_auxiliary` | `xmage_simple_tap_mana_source_permanent_v1` | `ramp_permanent` | `battle_rule_v1:334c7aaa550ad22e025183387c891f6e` |
| `The Celestus` | `xmage_simple_mana_source_with_unmodeled_auxiliary` | `xmage_simple_tap_mana_source_permanent_v1` | `ramp_permanent` | `battle_rule_v1:30b93736e2a09df4672e4eb2457bcc2a` |
| `The Irencrag` | `xmage_simple_mana_source_with_unmodeled_auxiliary` | `xmage_simple_tap_mana_source_permanent_v1` | `ramp_permanent` | `battle_rule_v1:2d9f7c765a5edcb38a5b8d49475b2417` |
| `The Lion-Turtle` | `xmage_simple_mana_source_with_unmodeled_auxiliary` | `xmage_simple_tap_mana_source_permanent_v1` | `ramp_permanent` | `battle_rule_v1:e984ef28fdb70a96f847b60d99d23533` |
| `Thunder Totem` | `xmage_simple_mana_source_with_unmodeled_auxiliary` | `xmage_simple_tap_mana_source_permanent_v1` | `ramp_permanent` | `battle_rule_v1:3578f495f31658ac3bfd4c72f68ef296` |
| `Ticket Turbotubes` | `xmage_simple_mana_source_with_unmodeled_auxiliary` | `xmage_simple_tap_mana_source_permanent_v1` | `ramp_permanent` | `battle_rule_v1:88e9ccdad6b58328fe601ce1e3c82ace` |
| `Tome of the Guildpact` | `xmage_simple_mana_source_with_unmodeled_auxiliary` | `xmage_simple_tap_mana_source_permanent_v1` | `ramp_permanent` | `battle_rule_v1:30463da319e6fed5a5722a6a20c4b687` |
| `Torgal, A Fine Hound` | `xmage_simple_mana_source_with_unmodeled_auxiliary` | `xmage_simple_tap_mana_source_permanent_v1` | `ramp_permanent` | `battle_rule_v1:b4898a56a12a79af796d6e5c060b12e3` |
| `Trailtracker Scout` | `xmage_simple_mana_source_with_unmodeled_auxiliary` | `xmage_simple_tap_mana_source_permanent_v1` | `ramp_permanent` | `battle_rule_v1:a6d62fd9c5c4785c3496727c97b5f23a` |
| `Tunnel Tipster` | `xmage_simple_mana_source_with_unmodeled_auxiliary` | `xmage_simple_tap_mana_source_permanent_v1` | `ramp_permanent` | `battle_rule_v1:9c64beedfd617652f85bba55a49233a2` |
| `Ulvenwald Captive // Ulvenwald Abomination` | `xmage_simple_mana_source_with_unmodeled_auxiliary` | `xmage_simple_tap_mana_source_permanent_v1` | `ramp_permanent` | `battle_rule_v1:6c90dcdf7dd01682540c3b51e0809adb` |
| `Veinfire Borderpost` | `xmage_simple_mana_source_with_unmodeled_auxiliary` | `xmage_simple_tap_mana_source_permanent_v1` | `ramp_permanent` | `battle_rule_v1:f61a4d4208c63d0b2310ae3046e26a4c` |
| `Veloheart Bike` | `xmage_simple_mana_source_with_unmodeled_auxiliary` | `xmage_simple_tap_mana_source_permanent_v1` | `ramp_permanent` | `battle_rule_v1:ce742cde7d1a215c4339c68a1aea620a` |
| `Vessel of Endless Rest` | `xmage_simple_mana_source_with_unmodeled_auxiliary` | `xmage_simple_tap_mana_source_permanent_v1` | `ramp_permanent` | `battle_rule_v1:851a610d00cc63c01fbf6f0d44ab1c5d` |
| `Visage of Bolas` | `xmage_simple_mana_source_with_unmodeled_auxiliary` | `xmage_simple_tap_mana_source_permanent_v1` | `ramp_permanent` | `battle_rule_v1:fc8198addd21fdefa8e767ba7a301640` |
| `Wand of the Worldsoul` | `xmage_simple_mana_source_with_unmodeled_auxiliary` | `xmage_simple_tap_mana_source_permanent_v1` | `ramp_permanent` | `battle_rule_v1:e077981ce11695d433cb9503c0815128` |
| `Wandertale Mentor` | `xmage_simple_mana_source_with_unmodeled_auxiliary` | `xmage_simple_tap_mana_source_permanent_v1` | `ramp_permanent` | `battle_rule_v1:549f900d26d02b9bc2e232dc6f3811cc` |
| `Warden of the Wall` | `xmage_simple_mana_source_with_unmodeled_auxiliary` | `xmage_simple_tap_mana_source_permanent_v1` | `ramp_permanent` | `battle_rule_v1:a88a7cf240822cf8d232a5a4aedee04e` |
| `Weatherseed Totem` | `xmage_simple_mana_source_with_unmodeled_auxiliary` | `xmage_simple_tap_mana_source_permanent_v1` | `ramp_permanent` | `battle_rule_v1:6b0a1a8185646c00eb9fffb69b2db03e` |
| `Weaver of Blossoms // Blossom-Clad Werewolf` | `xmage_simple_mana_source_with_unmodeled_auxiliary` | `xmage_simple_tap_mana_source_permanent_v1` | `ramp_permanent` | `battle_rule_v1:71b7180d3b8d32355fbb526e3d4e9e5c` |
| `Werebear` | `xmage_simple_mana_source_with_unmodeled_auxiliary` | `xmage_simple_tap_mana_source_permanent_v1` | `ramp_permanent` | `battle_rule_v1:0ea31218b5260315e02ab6734dc2b2d0` |
| `White Auracite` | `xmage_simple_mana_source_with_unmodeled_auxiliary` | `xmage_simple_tap_mana_source_permanent_v1` | `ramp_permanent` | `battle_rule_v1:aaab1c1776e65d0d0b751c24420e39d1` |
| `Wildfield Borderpost` | `xmage_simple_mana_source_with_unmodeled_auxiliary` | `xmage_simple_tap_mana_source_permanent_v1` | `ramp_permanent` | `battle_rule_v1:9227b0b08c06c07edc4a4faabadfbd61` |
| `Wose Pathfinder` | `xmage_simple_mana_source_with_unmodeled_auxiliary` | `xmage_simple_tap_mana_source_permanent_v1` | `ramp_permanent` | `battle_rule_v1:c18cd1a89081890e70a211206520d44d` |
| `Zagoth Crystal` | `xmage_simple_mana_source_with_unmodeled_auxiliary` | `xmage_simple_tap_mana_source_permanent_v1` | `ramp_permanent` | `battle_rule_v1:2d7a3249d4daa4eb1ddc109e1a5b14bc` |
| `Zhur-Taa Druid` | `xmage_simple_mana_source_with_unmodeled_auxiliary` | `xmage_simple_tap_mana_source_permanent_v1` | `ramp_permanent` | `battle_rule_v1:6f08fa18eb8009b26a83d2bac1376b23` |
| `Zookeeper Mechan` | `xmage_simple_mana_source_with_unmodeled_auxiliary` | `xmage_simple_tap_mana_source_permanent_v1` | `ramp_permanent` | `battle_rule_v1:4b1ec8875101fa5e814fa634d003371d` |

## Blocked Samples

- `activated_damage_oracle_not_simple`: `["Airdrop Condor", "Ballista Squad", "Ben-Ben, Akki Hermit", "Bloodshot Cyclops", "Bosh, Iron Golem", "Brion Stoutarm", "Cinder Elemental", "Coalborn Entity", "Crimson Hellkite", "Cuombajj Witches", "Fervent Paincaster", "Fire Shrine Keeper"]`
- `activated_damage_source_cost_not_supported`: `["Arc-Slogger", "Bolrac-Clan Crusher", "Catapult Squad", "Ghirapur Aether Grid", "Ion Storm", "Kyren Negotiations", "Reckless Assault"]`
- `activated_damage_source_discard_cost_not_supported`: `["Meteor Storm"]`
- `activated_destroy_oracle_not_simple`: `["Boom Box", "Devout Harpist", "Gorilla Shaman", "Haazda Exonerator", "King Suleiman", "Miracle Worker", "Nezumi Shadow-Watcher", "Northern Paladin", "Nosy Goblin", "Orcish Settlers", "Plaguebearer", "Ramses Overdark"]`
- `activated_destroy_source_cost_not_supported`: `["Army Ants", "Attrition", "Aura Fracture", "Blaster Mage", "Devout Witness", "Earthblighter", "Elvish Skysweeper", "Hand of Justice", "Keldon Arsonist", "Krark-Clan Engineers", "Murderous Betrayal", "Notorious Assassin"]`
- `activated_destroy_source_not_simple_destroy_effect`: `["Despotic Scepter", "Seal of Doom"]`
- `activated_destroy_source_target_not_supported`: `["Deepfire Elemental", "Dogged Hunter", "Hearth Kami", "Knight of Dusk", "Rats of Rath"]`
- `activated_draw_discard_oracle_cost_not_supported`: `["Maestros Initiate"]`
- `activated_draw_oracle_cost_not_supported`: `["Azami, Lady of Scrolls", "Cobbled Lancer", "Illuminated Folio", "Jandor's Ring", "O'aka, Traveling Merchant", "Selhoff Entomber", "Soul Diviner", "Thraxodemon"]`
- `activated_draw_oracle_not_simple`: `["Compulsion", "Gristle Glutton", "Riptide Director", "Sea Gate Loremaster", "Slate of Ancestry"]`
- `activated_draw_source_cost_not_supported`: `["Sage of Lat-Nam"]`
- `activated_graveyard_exile_oracle_not_simple`: `["Martyr of Bones", "Mortiphobia", "Steamclaw"]`
- `activated_graveyard_to_library_oracle_not_simple`: `["Keeper of the Cadence"]`
- `activated_library_tutor_oracle_cost_not_supported`: `["Angel's Herald", "Behemoth's Herald", "Demon's Herald", "Dragon's Herald", "Dreamscape Artist", "Everbark Shaman", "Kuldotha Forgemaster", "Lifespinner", "Magus of the Order", "Perilous Forays", "Silverglade Pathfinder", "Sphinx's Herald"]`
- `activated_life_gain_oracle_cost_not_supported`: `["Ancestor's Prophet", "Claws of Gix", "Dark Heart of the Wood", "Dune Diviner", "Gutless Ghoul", "Overgrown Estate", "Peace of Mind", "Ravenous Baloth", "Royal Herbalist", "Soul Shepherd", "Starved Rusalka"]`
- `activated_life_gain_oracle_not_simple`: `["Children of Korlis", "Elvish Eulogist", "Faith Healer", "Keeper of the Light", "Martyr of Sands", "Oracle of Nectars", "Skullmead Cauldron", "Sophic Centaur", "Tainted Sigil", "Wellwisher"]`
- `activated_recursion_battlefield_oracle_cost_not_supported`: `["Gravespawn Sovereign", "Order of Whiteclay", "Sidisi, Regent of the Mire", "Whisper, Blood Liturgist"]`
- `activated_recursion_oracle_cost_not_supported`: `["Bonebind Orator", "Cabal Surgeon", "Skeleton Shard"]`
- `activated_recursion_oracle_not_simple`: `["Restoration Specialist", "Salvager of Ruin", "Soul of Innistrad"]`
- `activated_self_add_counters_oracle_not_simple`: `["Copper-Leaf Angel"]`
- `activated_self_add_counters_source_cost_not_supported`: `["Hungry Ghoul", "Markov Dreadknight", "Mold Folk", "Souldrinker", "Unburied Earthcarver"]`
- `activated_self_boost_oracle_cost_not_supported`: `["Aven Trooper", "Burning-Fist Minotaur", "Canyon Drake", "Carrion Howler", "Fleshgrafter", "Frenetic Ogre", "Grimclaw Bats", "Krosan Archer", "Llanowar Behemoth", "Moltensteel Dragon", "Noose Constrictor", "Pardic Swordsmith"]`
- `activated_self_boost_oracle_not_simple`: `["Chilling Shade", "Conifer Wurm", "Feral Animist", "Hailstorm Valkyrie", "Immolating Souleater", "Kitsune Loreweaver", "Reckless Amplimancer", "Safehold Sentry", "Stone Kavu", "Viashivan Dragon", "Volrath the Fallen", "Wandering Goblins"]`
- `activated_self_boost_source_oracle_cost_mismatch`: `["Darklit Gargoyle"]`
- `activated_target_boost_oracle_cost_not_supported`: `["Coral Helm", "Deepwood Drummer", "Goblin Sledder", "Plague Witch"]`
- `activated_target_boost_oracle_not_simple`: `["Armorer Guildmage", "Auriok Bladewarden", "Belbe's Armor", "Cackling Witch", "Dega Disciple", "Disciple of Tevesh Szat", "Elder of Laurels", "Lys Alana Scarblade", "Merrow Grimeblotter", "Narcissism", "Power Armor", "Silvergill Douser"]`
- `activated_target_keyword_oracle_cost_not_supported`: `["Balloon Peddler", "Heartwood Shard", "Need for Speed", "Ohran Yeti", "Selfless Savior", "Slobad, Goblin Tinkerer", "Spurred Wolverine", "Stonerise Spirit", "Torch Courier", "Vial of Poison"]`
- `activated_target_keyword_source_target_not_supported`: `["Veteran Cathar"]`
- `activated_token_source_cost_not_supported`: `["Eternal Student", "Goblin Warrens", "Goldmeadow Lookout", "Icatian Crier", "Illustrious Historian", "Llanowar Mentor", "Pegasus Refuge", "Selesnya Evangel", "Sliversmith", "Sparkspitter", "Thraben Standard Bearer"]`
- `activated_token_source_create_token_not_fixed`: `["Ant Queen", "Krenko, Mob Boss"]`
- `activated_token_source_not_simple_activated`: `["Steward of Solidarity", "Vessel of Ephemera"]`
- `add_counters_ability_class_not_simple`: `["Earthen Arms", "Nature's Panoply", "Stinging Shot", "Travel Preparations"]`
- `add_counters_counter_not_fixed`: `["Common Bond", "Gird for Battle", "Incremental Blight", "Incremental Growth", "Reap What Is Sown", "River Heralds' Boon", "Stand Together", "Strength of Solidarity"]`
- `add_counters_effect_class_not_pure`: `["Aggressive Negotiations", "Ajani's Influence", "Ancient Animus", "Awakening of Vitu-Ghazi", "Azula Always Lies", "Biogenic Upgrade", "Blur of Blades", "Boon of Safety", "Clash of the Eikons", "Clockspinning", "Courage in Crisis", "Domri's Ambush"]`
- `add_counters_oracle_not_simple`: `["Protection Magic"]`
- `add_counters_target_not_supported`: `["Thrive", "Unexpected Fangs"]`
- `additional_cost_detected`: `["Abjure", "Aether Tide", "Anchor to Reality", "Angelic Purge", "Betrayer's Bargain", "Blood for Bones", "Bogslither's Embrace", "Caught in the Crossfire", "Caustic Exhale", "Chill Haunting", "Cinder Strike", "Cloud's Limit Break"]`
- `attack_target_keyword_oracle_static_keyword_not_exact`: `["Ogre Errant"]`
- `attack_target_keyword_source_keyword_not_supported`: `["Appa, Aang's Companion", "Flesh Burrower", "Malamet Brawler", "Phyrexian Pegasus", "Poison-Blade Mentor"]`
- `attack_target_keyword_source_oracle_mismatch`: `["Mirkwood Spider"]`
- `aura_static_pt_oracle_not_exact_fixed`: `["All That Glitters", "Alpha Status", "Ancestral Mask", "Aspect of Wolf", "Blanchwood Armor", "Blessing of the Nephilim", "Death's Approach", "Empyrial Armor", "Exoskeletal Armor", "Exotic Curse", "Granite Grip", "Kagemaro's Clutch"]`
- `board_wipe_ability_class_not_simple`: `["Akroma's Vengeance", "Artistic Process", "Blasphemous Edict", "Boiling Earth", "Burn Down the House", "Cinderclasm", "Claws of Wirewood", "Crush the Weak", "Deafening Clarion", "Devastating Mastery", "Doomskar", "Dusk // Dawn"]`
- `board_wipe_damage_amount_not_fixed`: `["Calamitous Cave-In", "Chain Reaction", "Corrosive Gale", "Gates Ablaze", "Immolating Gyre", "Radiant Flames", "Savage Twister", "Skyreaping", "Windstorm"]`
- `board_wipe_damage_scope_not_supported`: `["Breath Weapon", "Evaporate", "Fiery Cannonade", "Incandescent Aria", "Inflame", "Warpath"]`
- `board_wipe_destroy_scope_not_supported`: `["Consume the Meek", "Culling Sun", "Damning Verdict", "Extinguish All Hope", "Fight to the Death", "Forced March", "Granulate", "In Garruk's Wake", "Iridian Maelstrom", "Jokulhaups", "Retaliate", "Ruinous Ultimatum"]`
- `board_wipe_effect_class_not_supported`: `["Balancing Act", "Barter in Blood", "Bend or Break", "Blood Money", "Bontu's Last Reckoning", "Burning of Xinye", "By Invitation Only", "Call to the Void", "Cataclysm", "Catastrophe", "Ceaseless Conflict", "Celestial Judgment"]`
- `board_wipe_oracle_not_simple`: `["Anger of the Gods", "Barrage of Boulders", "Blood on the Snow", "Breaking Point", "Brotherhood's End", "Calming Verse", "Cleansing Meditation", "Cleansing Nova", "Crisis of Conscience", "Crux of Fate", "Fated Retribution", "Final Act"]`
- `board_wipe_source_multiple_damage_all_effects`: `["Kaervek's Hex"]`
- `boost_all_source_not_single_fixed`: `["Cloudkill", "Dead of Winter", "Drag to the Bottom", "Final Revels", "Flowstone Slide", "Glistening Deluge", "Olivia's Wrath", "Planar Despair"]`
- `boost_controlled_source_filter_not_supported`: `["Guardians' Pledge"]`
- `boost_controlled_source_not_single_fixed`: `["Battle Frenzy", "Fortify", "In Oketra's Name", "Klothys's Design"]`
- `boost_draw_oracle_not_exact_fixed`: `["Aang's Defense", "Gallantry"]`
- `boost_keyword_draw_source_not_exact_fixed`: `["Ancestral Anger", "Fists of Flame"]`
- `boost_keyword_oracle_not_simple`: `["Fight as One", "Invigorated Rampage"]`
- `boost_keyword_source_not_single_fixed`: `["Arm the Cathars", "Armor of Shadows", "Blitzball Shot", "Chorus of Might", "Coordinated Assault", "Cutthroat Maneuver", "Get a Leg Up", "Massive Might", "Masterful Flourish", "Pedal to the Metal", "Press the Advantage", "Run Amok"]`
- `boost_target_source_not_single_fixed`: `["Accelerated Mutation", "Agony Warp", "Allied Assault", "Bloodcurdling Scream", "Bounty of Might", "Dauntless Onslaught", "Death Wind", "Enrage", "Hearts on Fire", "Howl from Beyond", "Martial Glory", "Might of the Nephilim"]`
- `bounce_ability_class_not_simple`: `["Alchemist's Retrieval", "Capsize", "Champion's Victory", "Clutch of Currents", "Command of Unsummoning", "Consuming Vortex", "Dematerialize", "Deny Reality", "Depart the Realm", "Essence Fracture", "Floodwaters", "Into Thin Air"]`
- `bounce_draw_ability_class_not_simple`: `["Eject", "Escape Detection", "Lunar Rejection"]`
- `bounce_draw_oracle_not_exact_fixed`: `["Repeal"]`
- `bounce_draw_oracle_not_simple`: `["Read the Tides"]`
- `bounce_effect_class_not_pure`: `["Absorb Identity", "Alley Evasion", "Applied Biomancy", "Banishing Betrayal", "Baral's Expertise", "Barrin's Unmaking", "Boing!", "Brutal Expulsion", "Callous Dismissal", "Clutch of the Undercity", "Consign // Oblivion", "Dead // Gone"]`
- `bounce_scry_oracle_not_exact_fixed`: `["Sea God's Revenge"]`
- `bounce_target_not_supported`: `["Aether Gale", "Aether Tradewinds", "Bounce Off", "Captivating Gyre", "Churning Eddy", "Counterintelligence", "Cut the Earthly Bond", "Distorting Wake", "Hoodwink", "Into the Void", "Peel from Reality", "Quicksilver Geyser"]`
- `combat_damage_draw_amount_damage_dealt_not_supported`: `["Fear of Failed Tests"]`
- `combat_damage_draw_count_not_fixed`: `["Impaler Shrike"]`
- `counter_ability_class_not_simple`: `["Admiral's Order", "Broken Concentration", "Consign to Memory", "Controvert", "Fervent Denial", "Forbid", "Forceful Denial", "Last Word", "Long River's Pull", "Muddle the Mixture", "Neutralize", "Out of Bounds"]`
- `counter_draw_oracle_not_simple`: `["School Daze"]`
- `counter_draw_target_not_supported`: `["Confound", "Hindering Light", "Keep Safe", "Laquatus's Disdain"]`
- `counter_effect_class_not_pure`: `["Amazing Acrobatics", "Bar the Gate", "Bring the Ending", "Confirm Suspicions", "Countersquall", "Dawn Charm", "Deny the Witch", "Didn't Say Please", "Discombobulate", "Dissolve", "Ertai's Trickery", "Essence Capture"]`
- `counter_oracle_not_simple`: `["Change the Equation", "Spell Blast"]`
- `counter_target_not_supported`: `["Avoid Fate", "Disallow", "Double Negative", "Intervene", "Outwit", "Rebuff the Wicked", "Second Guess", "Stern Scolding", "Tale's End", "Turn Aside", "Voidslime"]`
- `counter_unless_pays_oracle_not_exact_fixed_generic`: `["Clash of Wills", "Concerted Defense", "Evasive Action", "Ixidor's Will", "Spell Stutter", "Syncopate", "Thassa's Rebuff"]`
- `damage_additional_cost_not_supported`: `["Close Encounter", "Devour in Flames", "Final Flare", "Goblin Grenade", "Heartfire", "Lightning Axe", "Monstrous Emergence", "Nahiri's Wrath", "Pumpkin Bombardment", "Shrapnel Blast"]`
- `damage_amount_not_fixed`: `["Clan Defiance", "Devil's Play", "Electrostatic Bolt", "Fall of the Titans", "Final Strike", "Fling", "Jaya's Immolating Inferno", "Practiced Tactics", "Street Spasm", "Thud", "Torrent of Fire", "Triumphant Chomp"]`
- `damage_draw_oracle_not_exact_fixed`: `["Incinerating Blast", "Invoke the Firemind", "Master the Way", "Needle Drop", "Stensia Banquet", "Tweeze"]`
- `damage_effect_class_not_pure`: `["Aggressive Sabotage", "Arc Blade", "Arrow Storm", "Barrel Down Sokenzan", "Beacon of Destruction", "Bedeck // Bedazzle", "Blastfire Bolt", "Blightning", "Blooming Blast", "Brimstone Volley", "Bring Low", "Burning Cloak"]`
- `damage_life_gain_oracle_not_simple`: `["Covenant of Blood", "Lantern Flare", "Morbid Hunger", "Parasitic Grasp", "Sacred Fire", "Smiting Helix", "Zenith Flare"]`
- `damage_life_gain_source_not_fixed`: `["Consuming Corruption", "Deadly Riposte", "Death Grasp", "Feast of Flesh", "Harsh Sustenance", "Joust Through", "Kiss of Death", "Profane Prayers", "Simulacrum", "Sorin's Vengeance", "Soul Shred", "Soul Spike"]`
- `damage_target_not_supported`: `["Consuming Bonfire", "Dual Shot", "Furious Reprisal", "Jagged Lightning", "Meteor Blast", "Pinnacle of Rage", "Storm of Steel", "Swelter"]`
- `destroy_additional_cost_not_supported`: `["Annihilating Glare", "Bitter Triumph", "Bone Shards", "Deadly Precision", "Eliminate the Competition", "Feed the Cycle", "Final Payment", "Flowstone Flood", "Fumarole", "Immoral Bargain", "Lash of the Balrog", "Lethal Sting"]`
- `destroy_draw_oracle_not_exact_fixed`: `["Deadly Embrace", "Dregs of Sorrow"]`
- `destroy_effect_class_not_pure`: `["Active Volcano", "Aftershock", "Agonizing Demise", "Airbender's Reversal", "Assassin's Strike", "Atomize", "Bant Charm", "Blight Grenade", "Blood Curdle", "Blue Elemental Blast", "Breathe Your Last", "Broken Bond"]`
- `destroy_life_gain_ability_class_not_simple`: `["Aerial Assault", "Feast of Blood"]`
- `destroy_life_gain_source_not_fixed`: `["Aerial Predation", "Dark Offering", "Divine Offering", "Eriette's Lullaby", "Lucky Offering", "Molder", "Noxious Grasp", "Poison Arrow", "Radiant Strike", "Serene Offering", "Silverstrike", "Surge of Righteousness"]`
- `destroy_scry_ability_class_not_simple`: `["Shower of Arrows"]`
- `destroy_target_not_supported`: `["Assassin's Blade", "Avalanche", "By Force", "Consign to Dust", "Cradle to Grave", "Curtains' Call", "Cut Short", "Dark Withering", "Death Rattle", "Eightfold Maze", "Expunge", "Feast of Dreams"]`
- `destroy_treasure_effect_classes_not_exact`: `["Cataclysmic Prospecting", "Covetous Elegy", "Heartless Pillage", "Improvised Weaponry", "Inspired Tinkering", "Involuntary Employment", "Megaton's Fate", "Petty Larceny", "Swarming of Moria", "You Find a Cursed Idol", "You've Been Caught Stealing"]`
- `dies_damage_amount_not_fixed`: `["Blazing Effigy"]`
- `dies_damage_target_not_supported`: `["Ember-Fist Zubera"]`
- `dies_draw_count_not_fixed`: `["Floating-Dream Zubera", "Merfolk Seer"]`
- `dies_life_gain_amount_not_fixed`: `["Bottle Golems", "Centaur Safeguard", "Silent-Chant Zubera"]`
- `dies_recursion_optional_cost_not_supported`: `["Carrion Thrash"]`
- `dies_token_oracle_not_simple`: `["Deathknell Berserker", "Deathpact Angel", "Tuktuk the Explorer"]`
- `draw_additional_cost_not_supported`: `["Bankrupt in Blood", "Merciless Resolve", "Necrologia", "Scarscale Ritual", "Shared Discovery"]`
- `draw_discard_spell_ability_class_not_simple`: `["Faithless Salvaging", "Unexpected Assistance", "Winternight Stories"]`
- `draw_discard_spell_oracle_not_exact_fixed`: `["Brilliant Spectrum", "Control of the Court", "Flow of Knowledge", "Goblin Lore", "Pull from Tomorrow"]`
- `draw_discard_spell_oracle_not_simple`: `["Mystic Meditation", "Thirst for Discovery", "Thirst for Identity", "Thirst for Knowledge", "Thirst for Meaning", "Waterbending Lesson"]`
- `draw_effect_class_not_pure`: `["Abeyance", "Abzan Charm", "Adventure Awaits", "Afterlife Insurance", "Airbending Lesson", "Amass the Components", "Ambitious Assault", "Aphotic Wisps", "Archmage's Charm", "Argent Mutation", "Arrester's Admonition", "Artificer's Epiphany"]`
- `draw_lose_life_spell_ability_class_not_simple`: `["Cut of the Profits", "Decorum Dissertation", "Ominous Harvest"]`
- `draw_lose_life_spell_oracle_not_exact_fixed`: `["Monumental Corruption", "Painful Truths", "Sanguimancy"]`
- `draw_put_land_oracle_not_exact_fixed`: `["Mind into Matter"]`
- `draw_self_cost_reduction_condition_not_supported`: `["Seize the Secrets"]`
- `draw_self_cost_reduction_oracle_not_exact_fixed`: `["Even the Score"]`
- `dynamic_count_damage_composite_count_not_supported`: `["Road Rage"]`
- `dynamic_count_damage_oracle_composite_count_not_supported`: `["Focus Fire", "Hobbit's Sting", "Slash of Light"]`
- `dynamic_count_damage_oracle_filter_not_supported`: `["Kaleidoscorch"]`
- `equipment_static_oracle_not_exact_fixed`: `["Bearded Axe", "Blackblade Reforged", "Bloodthorn Flail", "Bramble Armor", "Civic Saber", "Darksteel Axe", "Demonmail Hauberk", "Empyrial Plate", "Glaive of the Guildpact", "Golem-Skin Gauntlets", "Helm of the Gods", "Manaforce Mace"]`
- `equipment_static_source_oracle_mismatch`: `["Boots of Speed", "Ranger's Longbow"]`
- `etb_add_counters_source_oracle_mismatch`: `["Angelic Quartermaster"]`
- `etb_bounce_target_not_supported`: `["Hoverguard Sweepers", "Sea Drake", "Venser, Shaper Savant"]`
- `etb_destroy_source_effect_count_not_supported`: `["Disruptive Stormbrood // Petty Revenge"]`
- `etb_draw_count_not_fixed`: `["Liliana's Standard Bearer", "Treetop Sentries"]`
- `etb_draw_lose_life_oracle_not_exact_fixed`: `["Champion of Dusk"]`
- `etb_library_pick_oracle_not_simple`: `["Gurmag Nightwatch", "Sage of Days", "Stirring Honormancer"]`
- `etb_library_tutor_oracle_not_simple`: `["Llanowar Sentinel"]`
- `etb_library_tutor_oracle_target_not_supported`: `["Scampering Surveyor"]`
- `etb_library_tutor_source_oracle_target_subtypes_mismatch`: `["Silverglade Elemental", "Wood Elves"]`
- `etb_library_tutor_to_hand_oracle_target_not_supported`: `["Micromancer"]`
- `etb_library_tutor_to_hand_source_oracle_count_mismatch`: `["Battalion Foot Soldier", "Gathering Throng", "Legion Conquistador"]`
- `etb_library_tutor_to_hand_source_oracle_target_subtypes_mismatch`: `["District Guide", "Skyshroud Sentinel"]`
- `etb_library_tutor_to_hand_source_oracle_up_to_count_mismatch`: `["Thalia's Lancers"]`
- `etb_life_gain_amount_not_fixed`: `["Ancestor's Chosen", "Angel of Renewal", "Archway Angel", "Aven Gagglemaster", "Dwarven Priest", "Flourishing Hunter", "Goldnight Redeemer", "Kraul Foragers", "Luminollusk", "Nylea's Disciple", "Setessan Petitioner", "Shepherd of Heroes"]`
- `etb_recursion_battlefield_target_not_supported`: `["Rot Hulk"]`
- `etb_recursion_target_not_supported`: `["Master Skald", "Mausoleum Turnkey", "Nucklavee"]`
- `exile_compensation_token_ability_class_not_simple`: `["Crib Swap"]`
- `exile_compensation_token_oracle_not_simple`: `["Ravenform"]`
- `exile_compensation_token_target_not_supported`: `["Resculpt"]`
- `exile_effect_class_not_pure`: `["Agate Assault", "Aim for the Head", "Anguished Unmaking", "Ashes to Ashes", "Break Down the Door", "Cast into the Fire", "Consuming Sinkhole", "Dispatch", "Divine Gambit", "Early Winter", "Eat to Extinction", "Excise"]`
- `exile_oracle_not_simple`: `["Barrier Breach", "Crush Contraband", "Devouring Light", "Forsake the Worldly", "Repel the Vile", "Tear Asunder", "Topple", "Wipe Clean"]`
- `exile_target_not_supported`: `["Blazing Hope", "Complete Disregard", "Dust to Dust", "Exorcise", "Glare of Heresy", "Gravkill", "Grip of Desolation", "Grotesque Demise", "Into the Core", "Oblivion Strike", "Pillar of Light", "Radiant Purge"]`
- `graveyard_count_boost_source_not_single`: `["Growth Cycle"]`
- `graveyard_count_damage_adventure_filter_not_supported`: `["Frantic Firebolt"]`
- `graveyard_count_damage_exile_x_graveyard_cost_not_supported`: `["Harvest Pyre", "Haunting Misery"]`
- `graveyard_exile_ability_class_not_supported`: `["Shred Memory"]`
- `graveyard_self_return_ability_class_not_simple`: `["Deathless Pilot", "Eldrazi Ravager", "Gilded Assault Cart", "Salvage Titan"]`
- `graveyard_self_return_oracle_not_simple`: `["Deathless Ancient", "Deathless Behemoth", "Dutiful Griffin", "Gangrenous Goliath"]`
- `keyword_draw_source_not_exact_fixed`: `["Poison the Blade", "Psychotic Fury"]`
- `library_pick_ability_class_not_simple`: `["Tracker's Instincts"]`
- `library_tutor_oracle_not_simple`: `["Beseech the Queen"]`
- `library_tutor_oracle_target_not_supported`: `["Conflux", "Reach the Horizon"]`
- `library_tutor_source_distinct_names_not_supported`: `["Shared Summons", "Three Dreams"]`
- `life_gain_amount_not_fixed`: `["Blessed Reversal", "Bountiful Harvest", "Festival of Trokin", "Fruition", "Gerrard's Wisdom", "Invigorating Falls", "Joyous Respite", "Landbind Ritual", "Nourishing Shoal", "Peach Garden Oath", "Predator's Rapport", "Presence of the Wise"]`
- `life_gain_draw_ability_class_not_simple`: `["Lifestream's Blessing", "Pursue the Past", "Voyage Home"]`
- `life_gain_draw_oracle_not_exact_fixed`: `["Shamanic Revelation", "Sphinx's Revelation", "Union of the Third Path"]`
- `life_gain_draw_oracle_not_simple`: `["Thrilling Discovery"]`
- `life_gain_effect_class_not_pure`: `["Aang's Journey", "Abuna's Chant", "Archangel's Light", "Bargain", "Basic Conjuration", "Battle at the Bridge", "Battlefield Promotion", "Blossoming Calm", "Blunt the Assault", "Bond of Flourishing", "Commune with Evil", "Cosmic Rebirth"]`
- `life_gain_oracle_not_simple`: `["Ancestral Tribute", "Benediction of Moons", "Captured Sunlight", "Folk Medicine", "Gnaw to the Bone", "Meditation Puzzle", "Reaping the Rewards", "Rejuvenate", "Sun's Bounty", "Vital Surge", "Weather the Storm"]`
- `look_library_pick_oracle_not_simple`: `["Board the Weatherlight", "Cartographer's Survey", "Collected Company", "Deploy the Gatewatch", "Diabolic Vision", "Machinate", "Seismic Sense", "United Battlefront"]`
- `look_library_pick_oracle_target_not_supported`: `["Commune with Dinosaurs", "Cowabunga!"]`
- `look_library_pick_source_target_not_supported`: `["Uncovered Clues"]`
- `mana_source_activated_draw_oracle_not_simple`: `["All-Fates Scroll", "Intelligence Bobblehead"]`
- `mana_source_effect_class_not_simple`: `["Animal Attendant", "Avid Reclaimer", "Biophagus", "Carnelian Orb of Dragonkind", "Darkwater Egg", "Doubling Cube // Doubling Cube", "Generator Servant", "Goblin Clearcutter", "Heritage Druid", "Ilysian Caryatid", "Leafkin Druid", "Mossfire Egg"]`
- `mana_source_oracle_not_simple`: `["Altar of the Pantheon", "Ashaya, Soul of the Wild", "Astral Cornucopia", "Baylen, the Haymaker", "Birchlore Rangers", "Brass Infiniscope", "Channeler Initiate", "Chromatic Lantern", "Citanul Hierophants", "Citanul Stalwart", "Coalition Relic", "Codie, Vociferous Codex"]`
- `mana_source_sacrifice_oracle_not_simple`: `["Overeager Apprentice"]`
- `mana_source_safe_ability_missing`: `["Abstract Paintmage", "Aetherflux Conduit", "Alluring Suitor // Deadly Dancer", "Ardent Electromancer", "Arvinox, the Mind Flail", "Azula, Cunning Usurper", "Barbflare Gremlin", "Benthic Explorers", "Berta, Wise Extrapolator", "Blazing Firesinger // Seething Song", "Boommobile", "Brazen Collector"]`
- `mana_source_simple_source_missing_tap_cost`: `["Skyshroud Elf"]`
- `mana_source_source_conditional_mana_not_supported`: `["Elementalist's Palette", "Helga, Skittish Seer", "Ice Cauldron", "Nardole, Resourceful Cyborg", "Redshift, Rocketeer Chief", "Rosheen, Roaring Prophet", "Sarevok's Tome", "S\u00e9ance Board", "Throne of Eldraine", "Undermountain Adventurer", "Vhal, Candlekeep Researcher"]`
- `mana_source_source_discard_cost_not_supported`: `["Bog Witch", "Bramble Familiar // Fetch Quest", "Izzet Keyrune", "Network Terminal", "Skirge Familiar"]`
- `mana_source_source_exile_cost_not_supported`: `["Hourglass of the Lost"]`
- `mana_source_source_pay_life_cost_not_supported`: `["Blightsoil Druid", "Blood Celebrant", "Haunted Screen", "Vesper Ghoul"]`
- `mana_source_source_sacrifice_cost_not_supported`: `["Astrolabe", "Atzocan Seer", "Barbed Sextant", "Basal Sliver", "Blitzball", "Buried Treasure", "Cryptex", "Elsewhere Flask", "Exploding Barrel", "Five Hundred Year Diary", "Golden Egg", "Guild Globe"]`
- `mana_source_source_sacrifice_target_cost_not_supported`: `["Evendo Brushrazer", "Krark-Clan Stoker", "Skirk Prospector", "The Golden Throne", "Thermopod", "Valleymaker"]`
- `mana_source_spell_not_supported`: `["Esper Origins // Summon: Esper Maduin"]`
- `mana_source_unsafe_ability_class`: `["Abzan Devotee", "Accomplished Alchemist", "Adarkar Unicorn", "Alena, Kessig Trapper", "Altar of the Lost", "Arbor Adherent", "Automated Artificer", "Axebane Guardian", "Barrels of Blasting Jelly", "Battery Bearer", "Beastcaller Savant", "Bighorner Rancher"]`
- `mill_return_ability_class_not_simple`: `["Dig Up the Body", "Incarnation Technique"]`
- `not_instant_or_sorcery_spell`: `["Aang, A Lot to Learn", "Abandoned Sarcophagus", "Aberrant", "Aberrant Mind Sorcerer", "Abhorrent Oculus", "Abiding Grace", "Abigale, Poet Laureate // Heroic Stanza", "Abomination", "Absolver Thrull", "Absolving Lammasu", "Abu Ja'far", "Abyssal Gatekeeper"]`
- `not_one_shot_spell_ability`: `["Ajani's Response", "Aleatory", "All Hallow's Eve", "Anzrag's Rampage", "Arm with Aether", "Arwen's Gift", "Astral Confrontation", "Back for More", "Balduvian Rage", "Banish from Edoras", "Benefactor's Draught", "Bind"]`
- `play_lands_from_graveyard_ability_class_not_simple_static`: `["Perennial Behemoth"]`
- `recursion_ability_class_not_simple`: `["Blood Beckoning", "Call to the Netherworld", "Dead Revels", "Disturbed Burial", "Grim Harvest", "Life from the Loam", "Peerless Recycling", "Soulless Revival", "Unmake the Graves"]`
- `recursion_auxiliary_flashback_cost_not_supported`: `["Dread Return"]`
- `recursion_auxiliary_primary_oracle_not_simple`: `["Sacred Excavation"]`
- `recursion_battlefield_ability_class_not_simple`: `["Endless Obedience", "Entreat the Dead", "Leonardo's Technique", "Proclamation of Rebirth", "Restart Sequence", "Return to the Ranks"]`
- `recursion_battlefield_all_ability_class_not_simple`: `["Primevals' Glorious Rebirth", "Resurgent Belief"]`
- `recursion_battlefield_all_oracle_not_supported`: `["Replenish"]`
- `recursion_battlefield_counter_ability_class_not_simple`: `["Prison Break", "Rite of the Moth"]`
- `recursion_effect_class_not_pure`: `["Abuelo's Awakening", "Accumulate Wisdom", "Aether Burst", "Aether Helix", "Afterlife from the Loam", "Agonizing Remorse", "All Suns' Dawn", "Animal Magnetism", "Animist's Awakening", "Another Chance", "Anticognition", "Ascend from Avernus"]`
- `recursion_exile_self_ability_class_not_simple`: `["Seeds of Renewal"]`
- `recursion_exile_self_target_not_supported`: `["Uncle's Musings"]`
- `scry_draw_oracle_not_exact_fixed`: `["Ugin's Insight"]`
- `spell_cast_add_counters_oracle_filter_not_supported`: `["Wandermare"]`
- `spell_cast_draw_oracle_filter_not_supported`: `["Dreamcatcher", "Edgewall Innkeeper", "Lunar Mystic"]`
- `spell_cast_draw_source_oracle_mismatch`: `["Emrakul's Influence"]`
- `static_controlled_pt_oracle_filter_not_supported`: `["A Tale for the Ages", "Builder's Blessing", "Castle", "Dire Fleet Neckbreaker", "Goblin Oriflamme", "Honor of the Pure", "Jacques le Vert", "Kaysa", "Orcish Oriflamme", "War Horn"]`
- `static_controlled_pt_oracle_not_exact`: `["Commander's Insignia", "Sporecrown Thallid"]`
- `static_controlled_pt_source_oracle_mismatch`: `["Glass of the Guildpact"]`
- `static_cost_reduction_colored_mana_not_supported`: `["Edgewalker", "Ragemonger"]`
- `static_global_pt_not_permanent`: `["Piety"]`
- `static_global_pt_oracle_dynamic_not_supported`: `["Knowledge Is Power", "Meishin, the Mind Cage", "Sliver Legion"]`
- `static_global_pt_oracle_filter_not_supported`: `["Mightstone", "Weakstone"]`
- `static_global_pt_source_dynamic_or_phase_not_supported`: `["Muraganda Petroglyphs"]`
- `static_graveyard_count_boost_oracle_not_exact`: `["Moon-Vigil Adherents"]`
- `static_graveyard_count_pt_oracle_not_exact`: `["Abomination of Llanowar", "Adamaro, First to Desire", "Ancient Ooze", "Awakened Amalgam", "Aysen Crusader", "Battle Squadron", "Beast of Burden", "Burrowguard Mentor", "Crusader of Odric", "Dakkon Blackblade", "Drove of Elves", "Dungrove Elder"]`
- `static_graveyard_threshold_boost_oracle_not_exact`: `["First-Time Flyer", "Gnarlwood Dryad", "Gorilla Titan", "Jace's Phantasm", "Moldgraf Scavenger", "Murasa Behemoth", "Syndicate Infiltrator"]`
- `static_keyword_not_creature`: `["Darksteel Relic"]`
- `static_protection_oracle_not_color_or_card_type_or_subtype_exact`: `["Enemy of the Guildpact", "Guardian of the Guildpact", "Mistmeadow Skulk", "Warren-Scourge Elf"]`
- `target_player_draw_spell_ability_class_not_simple`: `["Ancestral Vision", "Comparative Analysis", "Huddle Up", "Oona's Grace"]`
- `target_player_draw_spell_oracle_not_exact_fixed`: `["Allied Strategies", "Braingeyser", "Stroke of Genius"]`
- `token_description_keyword_not_supported`: `["Birthing Boughs", "Carrion Call", "Dance with Devils", "Devils' Playground", "Dragon Egg", "Errand of Duty", "Form a Posse", "Goblin Wizardry", "Harried Spearguard", "Hobbling Zombie", "Mage's Attendant", "Master of the Hunt"]`
- `token_description_not_creature_token`: `["Argothian Opportunist", "Beamsaw Prospector", "Blood Servitor", "Buy Your Silence", "Cartographer's Companion", "Common Crook", "Crustacean Commando", "Dire Fleet Hoarder", "Emergency Eject", "Forecasting Fortune Teller", "Galactic Wayfarer", "Gleaming Barrier"]`
- `token_land_token_runtime_not_supported`: `["Awaken the Woods"]`
- `token_source_additional_tokens_not_supported`: `["Farmer Cotton", "Triplicate Titan", "Trostani's Summoner", "Wurmcoil Engine", "Wurmcoil Larva"]`
- `token_source_create_token_not_fixed`: `["Crash the Party", "Deploy to the Front", "Dripping-Tongue Zubera", "Elven Ambush", "Elvish Promenade", "Evangel of Heliod", "Flurry of Wings", "Fresh Meat", "Fungal Sprouting", "Goblin Gathering", "Great Desert Prospector", "Hallowed Spiritkeeper"]`
- `token_source_not_single_create_token_effect`: `["Exhibition Magician"]`
- `tutor_ability_class_not_simple`: `["Beneath the Sands", "Bitter Ordeal", "Brave the Wilds", "Cosmium Confluence", "Crumble to Dust", "Deep Reconnaissance", "Dig Up", "Dire-Strain Rampage", "Dragonstorm", "Edge of Autumn", "Extirpate", "Flare of Cultivation"]`
- `tutor_effect_class_not_supported`: `["Acquire", "Ancient Vendetta", "Angrath's Fury", "Attune with Aether", "Avengers Disassembled", "Basri's Aegis", "Begin the Invasion", "Behold the Beyond", "Bifurcate", "Boundless Realms", "Bribery", "Bring to Light"]`
- `unsupported_adapter_work_unit`: `["Changeling Wayfinder", "Tiamat", "Yasharn, Implacable Earth"]`
- `x_damage_alternative_timing_not_supported`: `["Ghitu Fire"]`
- `x_damage_buyback_not_supported`: `["Fanning the Flames"]`
