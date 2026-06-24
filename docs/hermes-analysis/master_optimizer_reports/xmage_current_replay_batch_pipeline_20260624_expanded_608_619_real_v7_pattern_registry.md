# XMage Shadow Pattern Registry

- Generated at: `2026-06-24T15:19:10+00:00`
- Status: `ready`
- Mutations performed: `[]`
- Promotion status: `shadow_only`

## Summary

- `proposal_count`: `504`
- `pattern_count`: `77`
- `lane_counts`: `{"blocked_missing_xmage_source": 2, "manual_mapper_backlog": 359, "package_already_prepared": 51, "runtime_family_backlog": 24, "split_scope_backlog": 68}`
- `pattern_status_counts`: `{"blocked_missing_xmage_source": 1, "fragmented_runtime_observation_only": 20, "governance_only_pending_pg_apply": 40, "manual_model_observation_only": 5, "requires_subpattern_split_before_promotion": 9, "runtime_template_candidate_requires_executor_tests": 2}`
- `card_counts_by_pattern_status`: `{"blocked_missing_xmage_source": 2, "fragmented_runtime_observation_only": 20, "governance_only_pending_pg_apply": 51, "manual_model_observation_only": 359, "requires_subpattern_split_before_promotion": 68, "runtime_template_candidate_requires_executor_tests": 4}`
- `executable_pattern_count`: `0`
- `auto_promotable_pattern_count`: `0`

## Boundary

- Registry rows are advisory evidence only.
- Executable battle behavior still belongs in reviewed/tested `card_battle_rules`.
- Do not join registry rows directly into deck-card consumers.
- PostgreSQL/Hermes writes remain approval-gated.

## Patterns

| Pattern | Lane | Status | Cards | Subpatterns | Action |
| --- | --- | --- | ---: | ---: | --- |
| `copy_permanent_etb/copy_permanent_etb/etb_copy_target_permanent_with_optional_extra_type_v1` | `package_already_prepared` | `governance_only_pending_pg_apply` | 5 | 5 | Do not remodel; move through the existing PostgreSQL approval/apply/sync/audit gate. |
| `copy_permanent_etb/copy_permanent_etb/etb_copy_target_creature_with_copy_applier_modifiers_v1` | `package_already_prepared` | `governance_only_pending_pg_apply` | 4 | 4 | Do not remodel; move through the existing PostgreSQL approval/apply/sync/audit gate. |
| `creature/creature/one_mana_zero_one_exalted_tricolor_mana_dork_v1` | `package_already_prepared` | `governance_only_pending_pg_apply` | 2 | 2 | Do not remodel; move through the existing PostgreSQL approval/apply/sync/audit gate. |
| `land/land/basic_one_color_land_v1` | `package_already_prepared` | `governance_only_pending_pg_apply` | 2 | 2 | Do not remodel; move through the existing PostgreSQL approval/apply/sync/audit gate. |
| `ramp_permanent/ramp_permanent/pain_talisman_color_pair_partial_v1` | `package_already_prepared` | `governance_only_pending_pg_apply` | 2 | 2 | Do not remodel; move through the existing PostgreSQL approval/apply/sync/audit gate. |
| `ramp_permanent/ramp_permanent/three_colorless_monolith_mana_rock_v1` | `package_already_prepared` | `governance_only_pending_pg_apply` | 2 | 2 | Do not remodel; move through the existing PostgreSQL approval/apply/sync/audit gate. |
| `copy_spell_engine/copy_spell/first_instant_sorcery_cast_each_turn_copy_own_spell_v1` | `package_already_prepared` | `governance_only_pending_pg_apply` | 1 | 1 | Do not remodel; move through the existing PostgreSQL approval/apply/sync/audit gate. |
| `copy_spell_engine/copy_spell/instant_sorcery_cast_copy_own_spell_v1` | `package_already_prepared` | `governance_only_pending_pg_apply` | 1 | 1 | Do not remodel; move through the existing PostgreSQL approval/apply/sync/audit gate. |
| `creature/creature/activated_land_tutor_with_land_sacrifice_and_graveyard_growth_v1` | `package_already_prepared` | `governance_only_pending_pg_apply` | 1 | 1 | Do not remodel; move through the existing PostgreSQL approval/apply/sync/audit gate. |
| `creature/creature/one_mana_one_one_black_pain_mana_dork_v1` | `package_already_prepared` | `governance_only_pending_pg_apply` | 1 | 1 | Do not remodel; move through the existing PostgreSQL approval/apply/sync/audit gate. |
| `creature/creature/one_one_color_diversity_mana_dork_v1` | `package_already_prepared` | `governance_only_pending_pg_apply` | 1 | 1 | Do not remodel; move through the existing PostgreSQL approval/apply/sync/audit gate. |
| `creature/creature/opponent_draws_card_damage_that_player_v1` | `package_already_prepared` | `governance_only_pending_pg_apply` | 1 | 1 | Do not remodel; move through the existing PostgreSQL approval/apply/sync/audit gate. |
| `creature/creature/two_one_green_per_creature_mana_dork_v1` | `package_already_prepared` | `governance_only_pending_pg_apply` | 1 | 1 | Do not remodel; move through the existing PostgreSQL approval/apply/sync/audit gate. |
| `creature/creature/vigilance_three_three_creatures_tap_any_color_v1` | `package_already_prepared` | `governance_only_pending_pg_apply` | 1 | 1 | Do not remodel; move through the existing PostgreSQL approval/apply/sync/audit gate. |
| `draw_engine/draw_engine/opponent_noncreature_spell_pay_four_draw_engine_with_cumulative_upkeep_v1` | `package_already_prepared` | `governance_only_pending_pg_apply` | 1 | 1 | Do not remodel; move through the existing PostgreSQL approval/apply/sync/audit gate. |
| `draw_engine/draw_engine/opponent_spell_pay_one_or_draw_engine_v1` | `package_already_prepared` | `governance_only_pending_pg_apply` | 1 | 1 | Do not remodel; move through the existing PostgreSQL approval/apply/sync/audit gate. |
| `land/land/any_color_from_opponent_land_production_v1` | `package_already_prepared` | `governance_only_pending_pg_apply` | 1 | 1 | Do not remodel; move through the existing PostgreSQL approval/apply/sync/audit gate. |
| `land/land/colorless_or_any_color_pain_land_v1` | `package_already_prepared` | `governance_only_pending_pg_apply` | 1 | 1 | Do not remodel; move through the existing PostgreSQL approval/apply/sync/audit gate. |
| `land_ramp/land_ramp/sacrifice_land_for_any_land_to_battlefield_untapped_v1` | `package_already_prepared` | `governance_only_pending_pg_apply` | 1 | 1 | Do not remodel; move through the existing PostgreSQL approval/apply/sync/audit gate. |
| `passive/passive/creatures_tap_any_color_static_enchantment_v1` | `package_already_prepared` | `governance_only_pending_pg_apply` | 1 | 1 | Do not remodel; move through the existing PostgreSQL approval/apply/sync/audit gate. |
| `passive/passive/opponent_draws_card_damage_that_player_v1` | `package_already_prepared` | `governance_only_pending_pg_apply` | 1 | 1 | Do not remodel; move through the existing PostgreSQL approval/apply/sync/audit gate. |
| `ramp_permanent/ramp_permanent/artifact_or_creature_support_colorless_mana_rock_v1` | `package_already_prepared` | `governance_only_pending_pg_apply` | 1 | 1 | Do not remodel; move through the existing PostgreSQL approval/apply/sync/audit gate. |
| `ramp_permanent/ramp_permanent/creature_support_any_color_mana_rock_v1` | `package_already_prepared` | `governance_only_pending_pg_apply` | 1 | 1 | Do not remodel; move through the existing PostgreSQL approval/apply/sync/audit gate. |
| `ramp_permanent/ramp_permanent/one_any_color_mana_rock_v1` | `package_already_prepared` | `governance_only_pending_pg_apply` | 1 | 1 | Do not remodel; move through the existing PostgreSQL approval/apply/sync/audit gate. |
| `ramp_ritual/ramp_ritual/hand_exile_add_one_green_mana_ritual_v1` | `package_already_prepared` | `governance_only_pending_pg_apply` | 1 | 1 | Do not remodel; move through the existing PostgreSQL approval/apply/sync/audit gate. |
| `static_cost_reducer/static_cost_reduction/static_cost_reduction_for_matching_spells_v1` | `package_already_prepared` | `governance_only_pending_pg_apply` | 1 | 1 | Do not remodel; move through the existing PostgreSQL approval/apply/sync/audit gate. |
| `targeted_interaction/recursion/graveyard_to_battlefield_variant_v1` | `package_already_prepared` | `governance_only_pending_pg_apply` | 1 | 1 | Do not remodel; move through the existing PostgreSQL approval/apply/sync/audit gate. |
| `targeted_interaction/draw_cards/source_controller_draw_variant_v1` | `package_already_prepared` | `governance_only_pending_pg_apply` | 1 | 1 | Do not remodel; move through the existing PostgreSQL approval/apply/sync/audit gate. |
| `targeted_interaction/direct_damage/targeted_damage_variant_v1` | `package_already_prepared` | `governance_only_pending_pg_apply` | 1 | 1 | Do not remodel; move through the existing PostgreSQL approval/apply/sync/audit gate. |
| `targeted_interaction/removal_destroy/targeted_destroy_variant_v1` | `package_already_prepared` | `governance_only_pending_pg_apply` | 1 | 1 | Do not remodel; move through the existing PostgreSQL approval/apply/sync/audit gate. |
| `treasure_maker/treasure_maker/single_treasure_creation_v1` | `package_already_prepared` | `governance_only_pending_pg_apply` | 1 | 1 | Do not remodel; move through the existing PostgreSQL approval/apply/sync/audit gate. |
| `tutor/tutor/any_tutor_to_hand_v1` | `package_already_prepared` | `governance_only_pending_pg_apply` | 1 | 1 | Do not remodel; move through the existing PostgreSQL approval/apply/sync/audit gate. |
| `tutor/tutor/convoke_creature_tutor_to_battlefield_mana_value_x_or_less_v1` | `package_already_prepared` | `governance_only_pending_pg_apply` | 1 | 1 | Do not remodel; move through the existing PostgreSQL approval/apply/sync/audit gate. |
| `tutor/tutor/creature_tutor_to_battlefield_mana_value_x_or_less_harmonize_v1` | `package_already_prepared` | `governance_only_pending_pg_apply` | 1 | 1 | Do not remodel; move through the existing PostgreSQL approval/apply/sync/audit gate. |
| `tutor/tutor/green_creature_tutor_to_battlefield_mana_value_x_or_less_then_shuffle_self_v1` | `package_already_prepared` | `governance_only_pending_pg_apply` | 1 | 1 | Do not remodel; move through the existing PostgreSQL approval/apply/sync/audit gate. |
| `tutor/tutor/improvise_artifact_tutor_to_battlefield_mana_value_x_or_less_v1` | `package_already_prepared` | `governance_only_pending_pg_apply` | 1 | 1 | Do not remodel; move through the existing PostgreSQL approval/apply/sync/audit gate. |
| `untap_land_engine/untap_land_engine/creature_x_tap_untap_x_lands_v1` | `package_already_prepared` | `governance_only_pending_pg_apply` | 1 | 1 | Do not remodel; move through the existing PostgreSQL approval/apply/sync/audit gate. |
| `untap_land_engine/untap_land_engine/pay_two_return_land_untap_target_land_v1` | `package_already_prepared` | `governance_only_pending_pg_apply` | 1 | 1 | Do not remodel; move through the existing PostgreSQL approval/apply/sync/audit gate. |
| `untap_land_engine/untap_land_engine/tap_untapped_creature_untap_target_basic_land_v1` | `package_already_prepared` | `governance_only_pending_pg_apply` | 1 | 1 | Do not remodel; move through the existing PostgreSQL approval/apply/sync/audit gate. |
| `untap_land_engine/untap_land_engine/x_tap_untap_x_lands_v1` | `package_already_prepared` | `governance_only_pending_pg_apply` | 1 | 1 | Do not remodel; move through the existing PostgreSQL approval/apply/sync/audit gate. |
| `targeted_interaction/direct_damage/targeted_damage_variant_v1` | `split_scope_backlog` | `requires_subpattern_split_before_promotion` | 21 | 14 | Split by ability kind, target constraints, triggers, costs, and secondary effects before promotion. |
| `targeted_interaction/draw_cards/source_controller_draw_variant_v1` | `split_scope_backlog` | `requires_subpattern_split_before_promotion` | 17 | 5 | Split by ability kind, target constraints, triggers, costs, and secondary effects before promotion. |
| `targeted_interaction/add_counters/source_add_counters_variant_v1` | `split_scope_backlog` | `requires_subpattern_split_before_promotion` | 11 | 8 | Split by ability kind, target constraints, triggers, costs, and secondary effects before promotion. |
| `targeted_interaction/removal_destroy/targeted_destroy_variant_v1` | `split_scope_backlog` | `requires_subpattern_split_before_promotion` | 10 | 6 | Split by ability kind, target constraints, triggers, costs, and secondary effects before promotion. |
| `targeted_interaction/recursion/graveyard_to_battlefield_variant_v1` | `split_scope_backlog` | `requires_subpattern_split_before_promotion` | 4 | 4 | Split by ability kind, target constraints, triggers, costs, and secondary effects before promotion. |
| `static_cost_reducer/static_cost_reduction/static_self_spell_cost_reduction_variant_v1` | `split_scope_backlog` | `requires_subpattern_split_before_promotion` | 2 | 1 | Split by ability kind, target constraints, triggers, costs, and secondary effects before promotion. |
| `targeted_interaction/add_counters/targeted_add_counters_variant_v1` | `split_scope_backlog` | `requires_subpattern_split_before_promotion` | 1 | 1 | Split by ability kind, target constraints, triggers, costs, and secondary effects before promotion. |
| `targeted_interaction/removal_exile/targeted_exile_variant_v1` | `split_scope_backlog` | `requires_subpattern_split_before_promotion` | 1 | 1 | Split by ability kind, target constraints, triggers, costs, and secondary effects before promotion. |
| `targeted_interaction/bounce/targeted_return_to_hand_variant_v1` | `split_scope_backlog` | `requires_subpattern_split_before_promotion` | 1 | 1 | Split by ability kind, target constraints, triggers, costs, and secondary effects before promotion. |
| `board_wipe_choice/sweeper_damage/damage_all_variant_v1` | `runtime_family_backlog` | `runtime_template_candidate_requires_executor_tests` | 2 | 2 | Implement only the exact homogeneous runtime scope with focused tests. |
| `board_wipe_choice/board_wipe/destroy_all_permanents_or_creatures_variant_v1` | `runtime_family_backlog` | `runtime_template_candidate_requires_executor_tests` | 2 | 2 | Implement only the exact homogeneous runtime scope with focused tests. |
| `token_maker/token_maker/xmage_create_token_variant_aclazotzdeepestbetrayal_v1` | `runtime_family_backlog` | `fragmented_runtime_observation_only` | 1 | 1 | Keep as registry evidence; wait for taxonomy/test-miner support before executor work. |
| `token_maker/token_maker/xmage_create_token_variant_adagiawindsweptbastion_v1` | `runtime_family_backlog` | `fragmented_runtime_observation_only` | 1 | 1 | Keep as registry evidence; wait for taxonomy/test-miner support before executor work. |
| `token_maker/token_maker/xmage_create_token_variant_biotransference_v1` | `runtime_family_backlog` | `fragmented_runtime_observation_only` | 1 | 1 | Keep as registry evidence; wait for taxonomy/test-miner support before executor work. |
| `token_maker/token_maker/xmage_create_token_variant_blackmarketconnections_v1` | `runtime_family_backlog` | `fragmented_runtime_observation_only` | 1 | 1 | Keep as registry evidence; wait for taxonomy/test-miner support before executor work. |
| `token_maker/token_maker/xmage_create_token_variant_blazecommando_v1` | `runtime_family_backlog` | `fragmented_runtime_observation_only` | 1 | 1 | Keep as registry evidence; wait for taxonomy/test-miner support before executor work. |
| `token_maker/token_maker/xmage_create_token_variant_bonemiser_v1` | `runtime_family_backlog` | `fragmented_runtime_observation_only` | 1 | 1 | Keep as registry evidence; wait for taxonomy/test-miner support before executor work. |
| `token_maker/token_maker/xmage_create_token_variant_davrosdalekcreator_v1` | `runtime_family_backlog` | `fragmented_runtime_observation_only` | 1 | 1 | Keep as registry evidence; wait for taxonomy/test-miner support before executor work. |
| `token_maker/token_maker/xmage_create_token_variant_fableofthemirrorbreaker_v1` | `runtime_family_backlog` | `fragmented_runtime_observation_only` | 1 | 1 | Keep as registry evidence; wait for taxonomy/test-miner support before executor work. |
| `token_maker/token_maker/xmage_create_token_variant_goldspandragon_v1` | `runtime_family_backlog` | `fragmented_runtime_observation_only` | 1 | 1 | Keep as registry evidence; wait for taxonomy/test-miner support before executor work. |
| `token_maker/token_maker/xmage_create_token_variant_greengoblinnemesis_v1` | `runtime_family_backlog` | `fragmented_runtime_observation_only` | 1 | 1 | Keep as registry evidence; wait for taxonomy/test-miner support before executor work. |
| `token_maker/token_maker/xmage_create_token_variant_maskwoodnexus_v1` | `runtime_family_backlog` | `fragmented_runtime_observation_only` | 1 | 1 | Keep as registry evidence; wait for taxonomy/test-miner support before executor work. |
| `token_maker/token_maker/xmage_create_token_variant_monasterymentor_v1` | `runtime_family_backlog` | `fragmented_runtime_observation_only` | 1 | 1 | Keep as registry evidence; wait for taxonomy/test-miner support before executor work. |
| `token_maker/token_maker/xmage_create_token_variant_perchprotection_v1` | `runtime_family_backlog` | `fragmented_runtime_observation_only` | 1 | 1 | Keep as registry evidence; wait for taxonomy/test-miner support before executor work. |
| `token_maker/token_maker/xmage_create_token_variant_sandscout_v1` | `runtime_family_backlog` | `fragmented_runtime_observation_only` | 1 | 1 | Keep as registry evidence; wait for taxonomy/test-miner support before executor work. |
| `token_maker/token_maker/xmage_create_token_variant_smugglersshare_v1` | `runtime_family_backlog` | `fragmented_runtime_observation_only` | 1 | 1 | Keep as registry evidence; wait for taxonomy/test-miner support before executor work. |
| `token_maker/token_maker/xmage_create_token_variant_surlybadgersaur_v1` | `runtime_family_backlog` | `fragmented_runtime_observation_only` | 1 | 1 | Keep as registry evidence; wait for taxonomy/test-miner support before executor work. |
| `token_maker/token_maker/xmage_create_token_variant_thelocustgod_v1` | `runtime_family_backlog` | `fragmented_runtime_observation_only` | 1 | 1 | Keep as registry evidence; wait for taxonomy/test-miner support before executor work. |
| `token_maker/token_maker/xmage_create_token_variant_utvarahellkite_v1` | `runtime_family_backlog` | `fragmented_runtime_observation_only` | 1 | 1 | Keep as registry evidence; wait for taxonomy/test-miner support before executor work. |
| `token_maker/token_maker/xmage_create_token_variant_wastenot_v1` | `runtime_family_backlog` | `fragmented_runtime_observation_only` | 1 | 1 | Keep as registry evidence; wait for taxonomy/test-miner support before executor work. |
| `token_maker/token_maker/xmage_create_token_variant_youngpyromancer_v1` | `runtime_family_backlog` | `fragmented_runtime_observation_only` | 1 | 1 | Keep as registry evidence; wait for taxonomy/test-miner support before executor work. |
| `manual_model/external_reference_required_manual_model/xmage_reference_requires_manual_model_review_v1` | `manual_mapper_backlog` | `manual_model_observation_only` | 355 | 53 | Keep after package, split-scope, and homogeneous-runtime lanes. |
| `draw_engine/draw_engine/opponent_discards_card_may_draw_v1` | `manual_mapper_backlog` | `manual_model_observation_only` | 1 | 1 | Keep after package, split-scope, and homogeneous-runtime lanes. |
| `passive/passive/controller_discards_card_damage_any_target_and_gain_life_v1` | `manual_mapper_backlog` | `manual_model_observation_only` | 1 | 1 | Keep after package, split-scope, and homogeneous-runtime lanes. |
| `passive/passive/opponent_discards_card_damage_that_player_v1` | `manual_mapper_backlog` | `manual_model_observation_only` | 1 | 1 | Keep after package, split-scope, and homogeneous-runtime lanes. |
| `token_maker/token_maker/xmage_create_token_variant_spikedcorridortorturepit_v1` | `manual_mapper_backlog` | `manual_model_observation_only` | 1 | 1 | Keep after package, split-scope, and homogeneous-runtime lanes. |
| `manual_model//` | `blocked_missing_xmage_source` | `blocked_missing_xmage_source` | 2 | 1 | Isolate as exception lane; do not contaminate main XMage queue. |

## Top Pattern Details

### copy_permanent_etb / copy_permanent_etb / etb_copy_target_permanent_with_optional_extra_type_v1

- Pattern id: `xmage_pattern:f14db638016364677865`
- Lane: `package_already_prepared`
- Status: `governance_only_pending_pg_apply`
- Cards: `5` (Clever Impersonator, Copy Artifact, Copy Enchantment, Mirrormade, Phyrexian Metamorph)
- Subpatterns: `5`
- Required evidence: `["approved exact PostgreSQL apply command", "precheck", "apply", "postcheck", "PG -> Hermes sync", "affected battle/deck audit"]`

### copy_permanent_etb / copy_permanent_etb / etb_copy_target_creature_with_copy_applier_modifiers_v1

- Pattern id: `xmage_pattern:87ac482ad2d3e9781178`
- Lane: `package_already_prepared`
- Status: `governance_only_pending_pg_apply`
- Cards: `4` (Flesh Duplicate, Imposter Mech, Mockingbird, Phantasmal Image)
- Subpatterns: `4`
- Required evidence: `["approved exact PostgreSQL apply command", "precheck", "apply", "postcheck", "PG -> Hermes sync", "affected battle/deck audit"]`

### creature / creature / one_mana_zero_one_exalted_tricolor_mana_dork_v1

- Pattern id: `xmage_pattern:abb861865848bfc89cb8`
- Lane: `package_already_prepared`
- Status: `governance_only_pending_pg_apply`
- Cards: `2` (Ignoble Hierarch, Noble Hierarch)
- Subpatterns: `2`
- Required evidence: `["approved exact PostgreSQL apply command", "precheck", "apply", "postcheck", "PG -> Hermes sync", "affected battle/deck audit"]`

### land / land / basic_one_color_land_v1

- Pattern id: `xmage_pattern:20c2e90d8b03f9d2122a`
- Lane: `package_already_prepared`
- Status: `governance_only_pending_pg_apply`
- Cards: `2` (Mountain, Plains)
- Subpatterns: `2`
- Required evidence: `["approved exact PostgreSQL apply command", "precheck", "apply", "postcheck", "PG -> Hermes sync", "affected battle/deck audit"]`

### ramp_permanent / ramp_permanent / pain_talisman_color_pair_partial_v1

- Pattern id: `xmage_pattern:2325023e18628ee58030`
- Lane: `package_already_prepared`
- Status: `governance_only_pending_pg_apply`
- Cards: `2` (Talisman of Curiosity, Talisman of Indulgence)
- Subpatterns: `2`
- Required evidence: `["approved exact PostgreSQL apply command", "precheck", "apply", "postcheck", "PG -> Hermes sync", "affected battle/deck audit"]`

### ramp_permanent / ramp_permanent / three_colorless_monolith_mana_rock_v1

- Pattern id: `xmage_pattern:4ae1c57d0670bd226975`
- Lane: `package_already_prepared`
- Status: `governance_only_pending_pg_apply`
- Cards: `2` (Basalt Monolith, Grim Monolith)
- Subpatterns: `2`
- Required evidence: `["approved exact PostgreSQL apply command", "precheck", "apply", "postcheck", "PG -> Hermes sync", "affected battle/deck audit"]`

### copy_spell_engine / copy_spell / first_instant_sorcery_cast_each_turn_copy_own_spell_v1

- Pattern id: `xmage_pattern:f7a93cb91a97fa6fd00c`
- Lane: `package_already_prepared`
- Status: `governance_only_pending_pg_apply`
- Cards: `1` (Double Vision)
- Subpatterns: `1`
- Required evidence: `["approved exact PostgreSQL apply command", "precheck", "apply", "postcheck", "PG -> Hermes sync", "affected battle/deck audit"]`

### copy_spell_engine / copy_spell / instant_sorcery_cast_copy_own_spell_v1

- Pattern id: `xmage_pattern:eac60f4f1ed02e2fb5cf`
- Lane: `package_already_prepared`
- Status: `governance_only_pending_pg_apply`
- Cards: `1` (Swarm Intelligence)
- Subpatterns: `1`
- Required evidence: `["approved exact PostgreSQL apply command", "precheck", "apply", "postcheck", "PG -> Hermes sync", "affected battle/deck audit"]`

### creature / creature / activated_land_tutor_with_land_sacrifice_and_graveyard_growth_v1

- Pattern id: `xmage_pattern:b46e14c8bd0dcc8928a6`
- Lane: `package_already_prepared`
- Status: `governance_only_pending_pg_apply`
- Cards: `1` (Elvish Reclaimer)
- Subpatterns: `1`
- Required evidence: `["approved exact PostgreSQL apply command", "precheck", "apply", "postcheck", "PG -> Hermes sync", "affected battle/deck audit"]`

### creature / creature / one_mana_one_one_black_pain_mana_dork_v1

- Pattern id: `xmage_pattern:52b3ffc2f50b0ac0ce9a`
- Lane: `package_already_prepared`
- Status: `governance_only_pending_pg_apply`
- Cards: `1` (Elves of Deep Shadow)
- Subpatterns: `1`
- Required evidence: `["approved exact PostgreSQL apply command", "precheck", "apply", "postcheck", "PG -> Hermes sync", "affected battle/deck audit"]`

### creature / creature / one_one_color_diversity_mana_dork_v1

- Pattern id: `xmage_pattern:6d306d802faf5b92c641`
- Lane: `package_already_prepared`
- Status: `governance_only_pending_pg_apply`
- Cards: `1` (Bloom Tender)
- Subpatterns: `1`
- Required evidence: `["approved exact PostgreSQL apply command", "precheck", "apply", "postcheck", "PG -> Hermes sync", "affected battle/deck audit"]`

### creature / creature / opponent_draws_card_damage_that_player_v1

- Pattern id: `xmage_pattern:9a7d3af2cd64071a8584`
- Lane: `package_already_prepared`
- Status: `governance_only_pending_pg_apply`
- Cards: `1` (Fate Unraveler)
- Subpatterns: `1`
- Required evidence: `["approved exact PostgreSQL apply command", "precheck", "apply", "postcheck", "PG -> Hermes sync", "affected battle/deck audit"]`
