# XMage Shadow Pattern Registry

- Generated at: `2026-06-26T03:00:06+00:00`
- Status: `ready`
- Mutations performed: `[]`
- Promotion status: `shadow_only`

## Summary

- `proposal_count`: `303`
- `pattern_count`: `22`
- `lane_counts`: `{"manual_mapper_backlog": 269, "package_already_prepared": 1, "package_ready_unprepared": 3, "runtime_family_backlog": 3, "split_scope_backlog": 27}`
- `pattern_status_counts`: `{"candidate_template_requires_review_tests": 7, "fragmented_runtime_observation_only": 2, "governance_only_pending_pg_apply": 1, "manual_model_observation_only": 1, "ready_for_pg_package_generation": 3, "requires_subpattern_split_before_promotion": 7, "runtime_observation_requires_taxonomy": 1}`
- `card_counts_by_pattern_status`: `{"candidate_template_requires_review_tests": 7, "fragmented_runtime_observation_only": 2, "governance_only_pending_pg_apply": 1, "manual_model_observation_only": 269, "ready_for_pg_package_generation": 3, "requires_subpattern_split_before_promotion": 20, "runtime_observation_requires_taxonomy": 1}`
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
| `controlled_creature_etb_damage_engine/creature/controlled_creature_enters_damage_each_opponent_v1` | `package_already_prepared` | `governance_only_pending_pg_apply` | 1 | 1 | Do not remodel; move through the existing PostgreSQL approval/apply/sync/audit gate. |
| `targeted_interaction/remove_permanent/destroy_creature_or_planeswalker_target_controller_basic_land_tapped_annotation_v1` | `package_ready_unprepared` | `ready_for_pg_package_generation` | 1 | 1 | Generate a PG package before any runtime work. |
| `targeted_interaction/remove_permanent/destroy_target_land_target_controller_basic_land_tapped_nonfliers_cant_block_or_tapped_red_land_v1` | `package_ready_unprepared` | `ready_for_pg_package_generation` | 1 | 1 | Generate a PG package before any runtime work. |
| `targeted_interaction/remove_permanent/destroy_target_opponent_artifact_or_overload_all_opponent_artifacts_annotation_v1` | `package_ready_unprepared` | `ready_for_pg_package_generation` | 1 | 1 | Generate a PG package before any runtime work. |
| `targeted_interaction/direct_damage/targeted_damage_variant_v1` | `split_scope_backlog` | `requires_subpattern_split_before_promotion` | 8 | 6 | Split by ability kind, target constraints, triggers, costs, and secondary effects before promotion. |
| `targeted_interaction/add_counters/source_add_counters_variant_v1` | `split_scope_backlog` | `requires_subpattern_split_before_promotion` | 3 | 3 | Split by ability kind, target constraints, triggers, costs, and secondary effects before promotion. |
| `targeted_interaction/draw_cards/source_controller_draw_variant_v1` | `split_scope_backlog` | `requires_subpattern_split_before_promotion` | 3 | 1 | Split by ability kind, target constraints, triggers, costs, and secondary effects before promotion. |
| `static_cost_reducer/static_cost_reduction/static_self_spell_cost_reduction_variant_v1` | `split_scope_backlog` | `requires_subpattern_split_before_promotion` | 2 | 1 | Split by ability kind, target constraints, triggers, costs, and secondary effects before promotion. |
| `targeted_interaction/removal_destroy/targeted_destroy_variant_v1` | `split_scope_backlog` | `requires_subpattern_split_before_promotion` | 2 | 1 | Split by ability kind, target constraints, triggers, costs, and secondary effects before promotion. |
| `creature/creature/etb_tutor_to_hand_creature_variant_v1` | `split_scope_backlog` | `requires_subpattern_split_before_promotion` | 1 | 1 | Split by ability kind, target constraints, triggers, costs, and secondary effects before promotion. |
| `mill_spell/mill_engine/artifact_tap_sacrifice_permanent_target_player_mill_v1` | `split_scope_backlog` | `candidate_template_requires_review_tests` | 1 | 1 | Review before promotion. |
| `modal_spell/modal_spell/modal_artifact_tutor_or_artifact_graveyard_to_hand_v1` | `split_scope_backlog` | `candidate_template_requires_review_tests` | 1 | 1 | Review before promotion. |
| `targeted_interaction/bounce/return_target_nonland_permanent_controller_may_sacrifice_land_copy_v1` | `split_scope_backlog` | `candidate_template_requires_review_tests` | 1 | 1 | Review before promotion. |
| `targeted_interaction/counter_spell/storm_counter_instant_or_sorcery_unless_controller_pays_one_v1` | `split_scope_backlog` | `candidate_template_requires_review_tests` | 1 | 1 | Review before promotion. |
| `targeted_interaction/bounce/targeted_return_to_hand_variant_v1` | `split_scope_backlog` | `requires_subpattern_split_before_promotion` | 1 | 1 | Split by ability kind, target constraints, triggers, costs, and secondary effects before promotion. |
| `tutor/tutor/artifact_tutor_to_hand_random_discard_damage_if_artifact_discarded_v1` | `split_scope_backlog` | `candidate_template_requires_review_tests` | 1 | 1 | Review before promotion. |
| `tutor/tutor/conditional_delirium_restricted_or_any_tutor_to_hand_v1` | `split_scope_backlog` | `candidate_template_requires_review_tests` | 1 | 1 | Review before promotion. |
| `tutor/tutor/pact_green_creature_tutor_to_hand_delayed_payment_v1` | `split_scope_backlog` | `candidate_template_requires_review_tests` | 1 | 1 | Review before promotion. |
| `board_wipe_choice/sweeper_damage/damage_all_variant_v1` | `runtime_family_backlog` | `runtime_observation_requires_taxonomy` | 1 | 1 | Review before promotion. |
| `token_maker/token_maker/xmage_create_token_variant_adagiawindsweptbastion_v1` | `runtime_family_backlog` | `fragmented_runtime_observation_only` | 1 | 1 | Keep as registry evidence; wait for taxonomy/test-miner support before executor work. |
| `token_maker/token_maker/xmage_create_token_variant_hazelsbrewmaster_v1` | `runtime_family_backlog` | `fragmented_runtime_observation_only` | 1 | 1 | Keep as registry evidence; wait for taxonomy/test-miner support before executor work. |
| `manual_model/external_reference_required_manual_model/xmage_reference_requires_manual_model_review_v1` | `manual_mapper_backlog` | `manual_model_observation_only` | 269 | 52 | Keep after package, split-scope, and homogeneous-runtime lanes. |

## Top Pattern Details

### controlled_creature_etb_damage_engine / creature / controlled_creature_enters_damage_each_opponent_v1

- Pattern id: `xmage_pattern:ff3b507e4851dcc22233`
- Lane: `package_already_prepared`
- Status: `governance_only_pending_pg_apply`
- Cards: `1` (Purphoros, God of the Forge)
- Subpatterns: `1`
- Required evidence: `["approved exact PostgreSQL apply command", "precheck", "apply", "postcheck", "PG -> Hermes sync", "affected battle/deck audit"]`

### targeted_interaction / remove_permanent / destroy_creature_or_planeswalker_target_controller_basic_land_tapped_annotation_v1

- Pattern id: `xmage_pattern:724ded7c51beefcf72b7`
- Lane: `package_ready_unprepared`
- Status: `ready_for_pg_package_generation`
- Cards: `1` (Erode)
- Subpatterns: `1`
- Required evidence: `["package precheck", "approved exact PostgreSQL apply command", "postcheck", "PG -> Hermes sync"]`

### targeted_interaction / remove_permanent / destroy_target_land_target_controller_basic_land_tapped_nonfliers_cant_block_or_tapped_red_land_v1

- Pattern id: `xmage_pattern:7d55cec049d0b52a21ae`
- Lane: `package_ready_unprepared`
- Status: `ready_for_pg_package_generation`
- Cards: `1` (Sundering Eruption // Volcanic Fissure)
- Subpatterns: `1`
- Required evidence: `["package precheck", "approved exact PostgreSQL apply command", "postcheck", "PG -> Hermes sync"]`

### targeted_interaction / remove_permanent / destroy_target_opponent_artifact_or_overload_all_opponent_artifacts_annotation_v1

- Pattern id: `xmage_pattern:800940c4c0be66e40978`
- Lane: `package_ready_unprepared`
- Status: `ready_for_pg_package_generation`
- Cards: `1` (Vandalblast)
- Subpatterns: `1`
- Required evidence: `["package precheck", "approved exact PostgreSQL apply command", "postcheck", "PG -> Hermes sync"]`

### targeted_interaction / direct_damage / targeted_damage_variant_v1

- Pattern id: `xmage_pattern:790e60a5a18d85f335a9`
- Lane: `split_scope_backlog`
- Status: `requires_subpattern_split_before_promotion`
- Cards: `8` (Balefire Liege, Boros Reckoner, Eiganjo, Seat of the Empire, Firesong and Sunspeaker, Razorgrass Ambush // Razorgrass Field, Repercussion, Terror of the Peaks, Toralf, God of Fury // Toralf's Hammer)
- Subpatterns: `6`
- Required evidence: `["subpattern split", "focused ManaLoom tests per subpattern", "package generation only for exact supported subpatterns"]`

### targeted_interaction / add_counters / source_add_counters_variant_v1

- Pattern id: `xmage_pattern:6423b1efbb7c1ffe105e`
- Lane: `split_scope_backlog`
- Status: `requires_subpattern_split_before_promotion`
- Cards: `3` (Palantír of Orthanc, Primal Amulet // Primal Wellspring, Tezzeret, Cruel Captain)
- Subpatterns: `3`
- Required evidence: `["subpattern split", "focused ManaLoom tests per subpattern", "package generation only for exact supported subpatterns"]`

### targeted_interaction / draw_cards / source_controller_draw_variant_v1

- Pattern id: `xmage_pattern:0dd5f9d566f02ce492c3`
- Lane: `split_scope_backlog`
- Status: `requires_subpattern_split_before_promotion`
- Cards: `3` (Archivist of Oghma, Bedlam Reveler, Blood Sun)
- Subpatterns: `1`
- Required evidence: `["subpattern split", "focused ManaLoom tests per subpattern", "package generation only for exact supported subpatterns"]`

### static_cost_reducer / static_cost_reduction / static_self_spell_cost_reduction_variant_v1

- Pattern id: `xmage_pattern:ace5f2346b48b243b1dd`
- Lane: `split_scope_backlog`
- Status: `requires_subpattern_split_before_promotion`
- Cards: `2` (Explosive Singularity, Vanquish the Horde)
- Subpatterns: `1`
- Required evidence: `["subpattern split", "focused ManaLoom tests per subpattern", "package generation only for exact supported subpatterns"]`

### targeted_interaction / removal_destroy / targeted_destroy_variant_v1

- Pattern id: `xmage_pattern:329f97cc5643657813fe`
- Lane: `split_scope_backlog`
- Status: `requires_subpattern_split_before_promotion`
- Cards: `2` (Abrade, Star of Extinction)
- Subpatterns: `1`
- Required evidence: `["subpattern split", "focused ManaLoom tests per subpattern", "package generation only for exact supported subpatterns"]`

### creature / creature / etb_tutor_to_hand_creature_variant_v1

- Pattern id: `xmage_pattern:48b4cc2fce343ae55c6f`
- Lane: `split_scope_backlog`
- Status: `requires_subpattern_split_before_promotion`
- Cards: `1` (Starfield Shepherd)
- Subpatterns: `1`
- Required evidence: `["subpattern split", "focused ManaLoom tests per subpattern", "package generation only for exact supported subpatterns"]`

### mill_spell / mill_engine / artifact_tap_sacrifice_permanent_target_player_mill_v1

- Pattern id: `xmage_pattern:66611bf37756ed6a27eb`
- Lane: `split_scope_backlog`
- Status: `candidate_template_requires_review_tests`
- Cards: `1` (Grinding Station)
- Subpatterns: `1`
- Required evidence: `["review", "focused test", "promotion gate"]`

### modal_spell / modal_spell / modal_artifact_tutor_or_artifact_graveyard_to_hand_v1

- Pattern id: `xmage_pattern:a76c20bec936fa38b8b6`
- Lane: `split_scope_backlog`
- Status: `candidate_template_requires_review_tests`
- Cards: `1` (Scour for Scrap)
- Subpatterns: `1`
- Required evidence: `["review", "focused test", "promotion gate"]`
