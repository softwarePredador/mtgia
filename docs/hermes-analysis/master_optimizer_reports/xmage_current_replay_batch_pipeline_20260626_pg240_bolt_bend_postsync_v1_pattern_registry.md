# XMage Shadow Pattern Registry

- Generated at: `2026-06-26T10:42:50+00:00`
- Status: `ready`
- Mutations performed: `[]`
- Promotion status: `shadow_only`

## Summary

- `proposal_count`: `385`
- `pattern_count`: `27`
- `lane_counts`: `{"blocked_missing_xmage_source": 4, "manual_mapper_backlog": 317, "package_already_prepared": 1, "runtime_family_backlog": 4, "split_scope_backlog": 59}`
- `pattern_status_counts`: `{"blocked_missing_xmage_source": 1, "candidate_template_requires_review_tests": 10, "fragmented_runtime_observation_only": 3, "governance_only_pending_pg_apply": 1, "manual_model_observation_only": 2, "requires_subpattern_split_before_promotion": 9, "runtime_observation_requires_taxonomy": 1}`
- `card_counts_by_pattern_status`: `{"blocked_missing_xmage_source": 4, "candidate_template_requires_review_tests": 10, "fragmented_runtime_observation_only": 3, "governance_only_pending_pg_apply": 1, "manual_model_observation_only": 317, "requires_subpattern_split_before_promotion": 49, "runtime_observation_requires_taxonomy": 1}`
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
| `targeted_interaction/direct_damage/targeted_damage_variant_v1` | `split_scope_backlog` | `requires_subpattern_split_before_promotion` | 19 | 13 | Split by ability kind, target constraints, triggers, costs, and secondary effects before promotion. |
| `targeted_interaction/draw_cards/source_controller_draw_variant_v1` | `split_scope_backlog` | `requires_subpattern_split_before_promotion` | 11 | 5 | Split by ability kind, target constraints, triggers, costs, and secondary effects before promotion. |
| `targeted_interaction/add_counters/source_add_counters_variant_v1` | `split_scope_backlog` | `requires_subpattern_split_before_promotion` | 7 | 6 | Split by ability kind, target constraints, triggers, costs, and secondary effects before promotion. |
| `targeted_interaction/removal_destroy/targeted_destroy_variant_v1` | `split_scope_backlog` | `requires_subpattern_split_before_promotion` | 6 | 5 | Split by ability kind, target constraints, triggers, costs, and secondary effects before promotion. |
| `recursion/recursion/graveyard_to_battlefield_variant_v1` | `split_scope_backlog` | `requires_subpattern_split_before_promotion` | 2 | 2 | Split by ability kind, target constraints, triggers, costs, and secondary effects before promotion. |
| `creature/creature/activated_pay_life_sacrifice_creature_any_tutor_to_hand_v1` | `split_scope_backlog` | `candidate_template_requires_review_tests` | 1 | 1 | Review before promotion. |
| `creature/creature/another_creature_dies_target_player_loses_life_you_gain_life_v1` | `split_scope_backlog` | `candidate_template_requires_review_tests` | 1 | 1 | Review before promotion. |
| `creature/creature/etb_tutor_to_hand_creature_variant_v1` | `split_scope_backlog` | `requires_subpattern_split_before_promotion` | 1 | 1 | Split by ability kind, target constraints, triggers, costs, and secondary effects before promotion. |
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
| `board_wipe_choice/sweeper_damage/damage_all_variant_v1` | `runtime_family_backlog` | `runtime_observation_requires_taxonomy` | 1 | 1 | Review before promotion. |
| `token_maker/token_maker/xmage_create_token_variant_adagiawindsweptbastion_v1` | `runtime_family_backlog` | `fragmented_runtime_observation_only` | 1 | 1 | Keep as registry evidence; wait for taxonomy/test-miner support before executor work. |
| `token_maker/token_maker/xmage_create_token_variant_hazelsbrewmaster_v1` | `runtime_family_backlog` | `fragmented_runtime_observation_only` | 1 | 1 | Keep as registry evidence; wait for taxonomy/test-miner support before executor work. |
| `token_maker/token_maker/xmage_create_token_variant_maskwoodnexus_v1` | `runtime_family_backlog` | `fragmented_runtime_observation_only` | 1 | 1 | Keep as registry evidence; wait for taxonomy/test-miner support before executor work. |
| `manual_model/external_reference_required_manual_model/xmage_reference_requires_manual_model_review_v1` | `manual_mapper_backlog` | `manual_model_observation_only` | 316 | 52 | Keep after package, split-scope, and homogeneous-runtime lanes. |
| `token_maker/token_maker/xmage_create_token_variant_spikedcorridortorturepit_v1` | `manual_mapper_backlog` | `manual_model_observation_only` | 1 | 1 | Keep after package, split-scope, and homogeneous-runtime lanes. |
| `manual_model//` | `blocked_missing_xmage_source` | `blocked_missing_xmage_source` | 4 | 1 | Isolate as exception lane; do not contaminate main XMage queue. |

## Top Pattern Details

### controlled_creature_etb_damage_engine / creature / controlled_creature_enters_damage_each_opponent_v1

- Pattern id: `xmage_pattern:ff3b507e4851dcc22233`
- Lane: `package_already_prepared`
- Status: `governance_only_pending_pg_apply`
- Cards: `1` (Purphoros, God of the Forge)
- Subpatterns: `1`
- Required evidence: `["approved exact PostgreSQL apply command", "precheck", "apply", "postcheck", "PG -> Hermes sync", "affected battle/deck audit"]`

### targeted_interaction / direct_damage / targeted_damage_variant_v1

- Pattern id: `xmage_pattern:790e60a5a18d85f335a9`
- Lane: `split_scope_backlog`
- Status: `requires_subpattern_split_before_promotion`
- Cards: `19` (Balefire Liege, Boros Reckoner, Brash Taunter, Cemetery Gatekeeper, Eiganjo, Seat of the Empire, Firesong and Sunspeaker, Gleeful Arsonist, Harsh Mentor, Kederekt Parasite, Mayhem Devil)
- Subpatterns: `13`
- Required evidence: `["subpattern split", "focused ManaLoom tests per subpattern", "package generation only for exact supported subpatterns"]`

### targeted_interaction / draw_cards / source_controller_draw_variant_v1

- Pattern id: `xmage_pattern:0dd5f9d566f02ce492c3`
- Lane: `split_scope_backlog`
- Status: `requires_subpattern_split_before_promotion`
- Cards: `11` (Arcane Denial, Archivist of Oghma, Kefka, Court Mage // Kefka, Ruler of Ruin, Morbid Opportunist, Phyrexian Arena, Psychic Frog, Puresteel Paladin, Solemn Simulacrum, Sram, Senior Edificer, Tinybones, Trinket Thief)
- Subpatterns: `5`
- Required evidence: `["subpattern split", "focused ManaLoom tests per subpattern", "package generation only for exact supported subpatterns"]`

### targeted_interaction / add_counters / source_add_counters_variant_v1

- Pattern id: `xmage_pattern:6423b1efbb7c1ffe105e`
- Lane: `split_scope_backlog`
- Status: `requires_subpattern_split_before_promotion`
- Cards: `7` (Bloodchief Ascension, Brallin, Skyshark Rider, Nightshade Harvester, Solphim, Mayhem Dominus, Séance Board, Tezzeret, Cruel Captain, The Haunt of Hightower)
- Subpatterns: `6`
- Required evidence: `["subpattern split", "focused ManaLoom tests per subpattern", "package generation only for exact supported subpatterns"]`

### targeted_interaction / removal_destroy / targeted_destroy_variant_v1

- Pattern id: `xmage_pattern:329f97cc5643657813fe`
- Lane: `split_scope_backlog`
- Status: `requires_subpattern_split_before_promotion`
- Cards: `6` (Abrade, Infernal Grasp, Rakdos Charm, Sheoldred // The True Scriptures, Suspended Sentence, Withering Torment)
- Subpatterns: `5`
- Required evidence: `["subpattern split", "focused ManaLoom tests per subpattern", "package generation only for exact supported subpatterns"]`

### recursion / recursion / graveyard_to_battlefield_variant_v1

- Pattern id: `xmage_pattern:34254033bb5fb4aecbb6`
- Lane: `split_scope_backlog`
- Status: `requires_subpattern_split_before_promotion`
- Cards: `2` (Forge Anew, The Soul Stone)
- Subpatterns: `2`
- Required evidence: `["subpattern split", "focused ManaLoom tests per subpattern", "package generation only for exact supported subpatterns"]`

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

### creature / creature / etb_tutor_to_hand_creature_variant_v1

- Pattern id: `xmage_pattern:48b4cc2fce343ae55c6f`
- Lane: `split_scope_backlog`
- Status: `requires_subpattern_split_before_promotion`
- Cards: `1` (Rune-Scarred Demon)
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

### targeted_interaction / bounce / return_target_nonland_permanent_controller_may_sacrifice_land_copy_v1

- Pattern id: `xmage_pattern:1d35cfcec069fd538f67`
- Lane: `split_scope_backlog`
- Status: `candidate_template_requires_review_tests`
- Cards: `1` (Chain of Vapor)
- Subpatterns: `1`
- Required evidence: `["review", "focused test", "promotion gate"]`
