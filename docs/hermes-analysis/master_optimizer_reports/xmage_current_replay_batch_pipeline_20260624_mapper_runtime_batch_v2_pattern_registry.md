# XMage Shadow Pattern Registry

- Generated at: `2026-06-24T19:22:50+00:00`
- Status: `ready`
- Mutations performed: `[]`
- Promotion status: `shadow_only`

## Summary

- `proposal_count`: `446`
- `pattern_count`: `48`
- `lane_counts`: `{"blocked_missing_xmage_source": 2, "manual_mapper_backlog": 337, "package_ready_unprepared": 2, "runtime_family_backlog": 24, "split_scope_backlog": 81}`
- `pattern_status_counts`: `{"blocked_missing_xmage_source": 1, "candidate_template_requires_review_tests": 11, "fragmented_runtime_observation_only": 20, "manual_model_observation_only": 2, "ready_for_pg_package_generation": 2, "requires_subpattern_split_before_promotion": 10, "runtime_template_candidate_requires_executor_tests": 2}`
- `card_counts_by_pattern_status`: `{"blocked_missing_xmage_source": 2, "candidate_template_requires_review_tests": 11, "fragmented_runtime_observation_only": 20, "manual_model_observation_only": 337, "ready_for_pg_package_generation": 2, "requires_subpattern_split_before_promotion": 70, "runtime_template_candidate_requires_executor_tests": 4}`
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
| `mill_spell/brain_freeze/storm_target_player_mill_fixed_count_v1` | `package_ready_unprepared` | `ready_for_pg_package_generation` | 1 | 1 | Generate a PG package before any runtime work. |
| `ramp_ritual/ramp_ritual/threshold_three_or_five_black_mana_ritual_v1` | `package_ready_unprepared` | `ready_for_pg_package_generation` | 1 | 1 | Generate a PG package before any runtime work. |
| `targeted_interaction/direct_damage/targeted_damage_variant_v1` | `split_scope_backlog` | `requires_subpattern_split_before_promotion` | 21 | 14 | Split by ability kind, target constraints, triggers, costs, and secondary effects before promotion. |
| `targeted_interaction/draw_cards/source_controller_draw_variant_v1` | `split_scope_backlog` | `requires_subpattern_split_before_promotion` | 17 | 5 | Split by ability kind, target constraints, triggers, costs, and secondary effects before promotion. |
| `targeted_interaction/add_counters/source_add_counters_variant_v1` | `split_scope_backlog` | `requires_subpattern_split_before_promotion` | 11 | 8 | Split by ability kind, target constraints, triggers, costs, and secondary effects before promotion. |
| `targeted_interaction/removal_destroy/targeted_destroy_variant_v1` | `split_scope_backlog` | `requires_subpattern_split_before_promotion` | 10 | 6 | Split by ability kind, target constraints, triggers, costs, and secondary effects before promotion. |
| `targeted_interaction/recursion/graveyard_to_battlefield_variant_v1` | `split_scope_backlog` | `requires_subpattern_split_before_promotion` | 4 | 4 | Split by ability kind, target constraints, triggers, costs, and secondary effects before promotion. |
| `creature/creature/etb_tutor_to_hand_creature_variant_v1` | `split_scope_backlog` | `requires_subpattern_split_before_promotion` | 2 | 2 | Split by ability kind, target constraints, triggers, costs, and secondary effects before promotion. |
| `static_cost_reducer/static_cost_reduction/static_self_spell_cost_reduction_variant_v1` | `split_scope_backlog` | `requires_subpattern_split_before_promotion` | 2 | 1 | Split by ability kind, target constraints, triggers, costs, and secondary effects before promotion. |
| `copy_spell_engine/copy_spell/copy_target_instant_or_sorcery_spell_may_choose_new_targets_v1` | `split_scope_backlog` | `candidate_template_requires_review_tests` | 1 | 1 | Review before promotion. |
| `creature/creature/activated_pay_life_sacrifice_creature_any_tutor_to_hand_v1` | `split_scope_backlog` | `candidate_template_requires_review_tests` | 1 | 1 | Review before promotion. |
| `creature/creature/another_creature_dies_target_player_loses_life_you_gain_life_v1` | `split_scope_backlog` | `candidate_template_requires_review_tests` | 1 | 1 | Review before promotion. |
| `mill_spell/mill_engine/artifact_tap_sacrifice_permanent_target_player_mill_v1` | `split_scope_backlog` | `candidate_template_requires_review_tests` | 1 | 1 | Review before promotion. |
| `modal_spell/modal_spell/modal_artifact_tutor_or_artifact_graveyard_to_hand_v1` | `split_scope_backlog` | `candidate_template_requires_review_tests` | 1 | 1 | Review before promotion. |
| `targeted_interaction/bounce/return_target_nonland_permanent_controller_may_sacrifice_land_copy_v1` | `split_scope_backlog` | `candidate_template_requires_review_tests` | 1 | 1 | Review before promotion. |
| `targeted_interaction/counter_spell/storm_counter_instant_or_sorcery_unless_controller_pays_one_v1` | `split_scope_backlog` | `candidate_template_requires_review_tests` | 1 | 1 | Review before promotion. |
| `targeted_interaction/add_counters/targeted_add_counters_variant_v1` | `split_scope_backlog` | `requires_subpattern_split_before_promotion` | 1 | 1 | Split by ability kind, target constraints, triggers, costs, and secondary effects before promotion. |
| `targeted_interaction/removal_exile/targeted_exile_variant_v1` | `split_scope_backlog` | `requires_subpattern_split_before_promotion` | 1 | 1 | Split by ability kind, target constraints, triggers, costs, and secondary effects before promotion. |
| `targeted_interaction/bounce/targeted_return_to_hand_variant_v1` | `split_scope_backlog` | `requires_subpattern_split_before_promotion` | 1 | 1 | Split by ability kind, target constraints, triggers, costs, and secondary effects before promotion. |
| `tutor/tutor/any_tutor_to_hand_controller_loses_life_v1` | `split_scope_backlog` | `candidate_template_requires_review_tests` | 1 | 1 | Review before promotion. |
| `tutor/tutor/artifact_tutor_to_hand_random_discard_damage_if_artifact_discarded_v1` | `split_scope_backlog` | `candidate_template_requires_review_tests` | 1 | 1 | Review before promotion. |
| `tutor/tutor/conditional_delirium_restricted_or_any_tutor_to_hand_v1` | `split_scope_backlog` | `candidate_template_requires_review_tests` | 1 | 1 | Review before promotion. |
| `tutor/tutor/pact_green_creature_tutor_to_hand_delayed_payment_v1` | `split_scope_backlog` | `candidate_template_requires_review_tests` | 1 | 1 | Review before promotion. |
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
| `manual_model/external_reference_required_manual_model/xmage_reference_requires_manual_model_review_v1` | `manual_mapper_backlog` | `manual_model_observation_only` | 336 | 53 | Keep after package, split-scope, and homogeneous-runtime lanes. |
| `token_maker/token_maker/xmage_create_token_variant_spikedcorridortorturepit_v1` | `manual_mapper_backlog` | `manual_model_observation_only` | 1 | 1 | Keep after package, split-scope, and homogeneous-runtime lanes. |
| `manual_model//` | `blocked_missing_xmage_source` | `blocked_missing_xmage_source` | 2 | 1 | Isolate as exception lane; do not contaminate main XMage queue. |

## Top Pattern Details

### mill_spell / brain_freeze / storm_target_player_mill_fixed_count_v1

- Pattern id: `xmage_pattern:ba657fd9faa70cec9d3f`
- Lane: `package_ready_unprepared`
- Status: `ready_for_pg_package_generation`
- Cards: `1` (Brain Freeze)
- Subpatterns: `1`
- Required evidence: `["package precheck", "approved exact PostgreSQL apply command", "postcheck", "PG -> Hermes sync"]`

### ramp_ritual / ramp_ritual / threshold_three_or_five_black_mana_ritual_v1

- Pattern id: `xmage_pattern:dcae6690db4c5b617f45`
- Lane: `package_ready_unprepared`
- Status: `ready_for_pg_package_generation`
- Cards: `1` (Cabal Ritual)
- Subpatterns: `1`
- Required evidence: `["package precheck", "approved exact PostgreSQL apply command", "postcheck", "PG -> Hermes sync"]`

### targeted_interaction / direct_damage / targeted_damage_variant_v1

- Pattern id: `xmage_pattern:790e60a5a18d85f335a9`
- Lane: `split_scope_backlog`
- Status: `requires_subpattern_split_before_promotion`
- Cards: `21` (Balefire Liege, Boros Reckoner, Brash Taunter, Caldera Pyremaw, Cemetery Gatekeeper, Eiganjo, Seat of the Empire, Firesong and Sunspeaker, Gleeful Arsonist, Harsh Mentor, Kederekt Parasite)
- Subpatterns: `14`
- Required evidence: `["subpattern split", "focused ManaLoom tests per subpattern", "package generation only for exact supported subpatterns"]`

### targeted_interaction / draw_cards / source_controller_draw_variant_v1

- Pattern id: `xmage_pattern:0dd5f9d566f02ce492c3`
- Lane: `split_scope_backlog`
- Status: `requires_subpattern_split_before_promotion`
- Cards: `17` (Arcane Denial, Archivist of Oghma, Bedlam Reveler, Blood Sun, Cool but Rude, Glint-Horn Buccaneer, Kefka, Court Mage // Kefka, Ruler of Ruin, Morbid Opportunist, Phyrexian Arena, Psychic Frog)
- Subpatterns: `5`
- Required evidence: `["subpattern split", "focused ManaLoom tests per subpattern", "package generation only for exact supported subpatterns"]`

### targeted_interaction / add_counters / source_add_counters_variant_v1

- Pattern id: `xmage_pattern:6423b1efbb7c1ffe105e`
- Lane: `split_scope_backlog`
- Status: `requires_subpattern_split_before_promotion`
- Cards: `11` (Bloodchief Ascension, Brallin, Skyshark Rider, Nightshade Harvester, Palantír of Orthanc, Primal Amulet // Primal Wellspring, Pyromancer Ascension, Solphim, Mayhem Dominus, Séance Board, Tezzeret, Cruel Captain, The Haunt of Hightower)
- Subpatterns: `8`
- Required evidence: `["subpattern split", "focused ManaLoom tests per subpattern", "package generation only for exact supported subpatterns"]`

### targeted_interaction / removal_destroy / targeted_destroy_variant_v1

- Pattern id: `xmage_pattern:329f97cc5643657813fe`
- Lane: `split_scope_backlog`
- Status: `requires_subpattern_split_before_promotion`
- Cards: `10` (Abrade, Erode, Infernal Grasp, Rakdos Charm, Sheoldred // The True Scriptures, Star of Extinction, Sundering Eruption // Volcanic Fissure, Suspended Sentence, Vandalblast, Withering Torment)
- Subpatterns: `6`
- Required evidence: `["subpattern split", "focused ManaLoom tests per subpattern", "package generation only for exact supported subpatterns"]`

### targeted_interaction / recursion / graveyard_to_battlefield_variant_v1

- Pattern id: `xmage_pattern:7ddfe3eecbf9a70e57c4`
- Lane: `split_scope_backlog`
- Status: `requires_subpattern_split_before_promotion`
- Cards: `4` (Forge Anew, Profound Journey, Sun Titan, The Soul Stone)
- Subpatterns: `4`
- Required evidence: `["subpattern split", "focused ManaLoom tests per subpattern", "package generation only for exact supported subpatterns"]`

### creature / creature / etb_tutor_to_hand_creature_variant_v1

- Pattern id: `xmage_pattern:48b4cc2fce343ae55c6f`
- Lane: `split_scope_backlog`
- Status: `requires_subpattern_split_before_promotion`
- Cards: `2` (Rune-Scarred Demon, Starfield Shepherd)
- Subpatterns: `2`
- Required evidence: `["subpattern split", "focused ManaLoom tests per subpattern", "package generation only for exact supported subpatterns"]`

### static_cost_reducer / static_cost_reduction / static_self_spell_cost_reduction_variant_v1

- Pattern id: `xmage_pattern:ace5f2346b48b243b1dd`
- Lane: `split_scope_backlog`
- Status: `requires_subpattern_split_before_promotion`
- Cards: `2` (Explosive Singularity, Vanquish the Horde)
- Subpatterns: `1`
- Required evidence: `["subpattern split", "focused ManaLoom tests per subpattern", "package generation only for exact supported subpatterns"]`

### copy_spell_engine / copy_spell / copy_target_instant_or_sorcery_spell_may_choose_new_targets_v1

- Pattern id: `xmage_pattern:c96e1ad7ca572d4ebfb9`
- Lane: `split_scope_backlog`
- Status: `candidate_template_requires_review_tests`
- Cards: `1` (Fury Storm)
- Subpatterns: `1`
- Required evidence: `["review", "focused test", "promotion gate"]`

### creature / creature / activated_pay_life_sacrifice_creature_any_tutor_to_hand_v1

- Pattern id: `xmage_pattern:5eb397a1265925e012ee`
- Lane: `split_scope_backlog`
- Status: `candidate_template_requires_review_tests`
- Cards: `1` (Razaketh, the Foulblooded)
- Subpatterns: `1`
- Required evidence: `["review", "focused test", "promotion gate"]`

### creature / creature / another_creature_dies_target_player_loses_life_you_gain_life_v1

- Pattern id: `xmage_pattern:b1f0bfcb5661cc922aa9`
- Lane: `split_scope_backlog`
- Status: `candidate_template_requires_review_tests`
- Cards: `1` (Blood Artist)
- Subpatterns: `1`
- Required evidence: `["review", "focused test", "promotion gate"]`
