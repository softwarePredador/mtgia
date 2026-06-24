# XMage Shadow Pattern Registry

- Generated at: `2026-06-24T15:32:14+00:00`
- Status: `ready`
- Mutations performed: `[]`
- Promotion status: `shadow_only`

## Summary

- `proposal_count`: `446`
- `pattern_count`: `34`
- `lane_counts`: `{"blocked_missing_xmage_source": 2, "manual_mapper_backlog": 352, "runtime_family_backlog": 24, "split_scope_backlog": 68}`
- `pattern_status_counts`: `{"blocked_missing_xmage_source": 1, "fragmented_runtime_observation_only": 20, "manual_model_observation_only": 2, "requires_subpattern_split_before_promotion": 9, "runtime_template_candidate_requires_executor_tests": 2}`
- `card_counts_by_pattern_status`: `{"blocked_missing_xmage_source": 2, "fragmented_runtime_observation_only": 20, "manual_model_observation_only": 352, "requires_subpattern_split_before_promotion": 68, "runtime_template_candidate_requires_executor_tests": 4}`
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
| `manual_model/external_reference_required_manual_model/xmage_reference_requires_manual_model_review_v1` | `manual_mapper_backlog` | `manual_model_observation_only` | 351 | 53 | Keep after package, split-scope, and homogeneous-runtime lanes. |
| `token_maker/token_maker/xmage_create_token_variant_spikedcorridortorturepit_v1` | `manual_mapper_backlog` | `manual_model_observation_only` | 1 | 1 | Keep after package, split-scope, and homogeneous-runtime lanes. |
| `manual_model//` | `blocked_missing_xmage_source` | `blocked_missing_xmage_source` | 2 | 1 | Isolate as exception lane; do not contaminate main XMage queue. |

## Top Pattern Details

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

### static_cost_reducer / static_cost_reduction / static_self_spell_cost_reduction_variant_v1

- Pattern id: `xmage_pattern:ace5f2346b48b243b1dd`
- Lane: `split_scope_backlog`
- Status: `requires_subpattern_split_before_promotion`
- Cards: `2` (Explosive Singularity, Vanquish the Horde)
- Subpatterns: `1`
- Required evidence: `["subpattern split", "focused ManaLoom tests per subpattern", "package generation only for exact supported subpatterns"]`

### targeted_interaction / add_counters / targeted_add_counters_variant_v1

- Pattern id: `xmage_pattern:462dd6bb77cd48eace60`
- Lane: `split_scope_backlog`
- Status: `requires_subpattern_split_before_promotion`
- Cards: `1` (Persistent Constrictor)
- Subpatterns: `1`
- Required evidence: `["subpattern split", "focused ManaLoom tests per subpattern", "package generation only for exact supported subpatterns"]`

### targeted_interaction / removal_exile / targeted_exile_variant_v1

- Pattern id: `xmage_pattern:ec9570ef72dcc9efea4b`
- Lane: `split_scope_backlog`
- Status: `requires_subpattern_split_before_promotion`
- Cards: `1` (Whip of Erebos)
- Subpatterns: `1`
- Required evidence: `["subpattern split", "focused ManaLoom tests per subpattern", "package generation only for exact supported subpatterns"]`

### targeted_interaction / bounce / targeted_return_to_hand_variant_v1

- Pattern id: `xmage_pattern:ac0dbd58d94d364dd9e1`
- Lane: `split_scope_backlog`
- Status: `requires_subpattern_split_before_promotion`
- Cards: `1` (Reprieve)
- Subpatterns: `1`
- Required evidence: `["subpattern split", "focused ManaLoom tests per subpattern", "package generation only for exact supported subpatterns"]`

### board_wipe_choice / sweeper_damage / damage_all_variant_v1

- Pattern id: `xmage_pattern:2184dfbf365f935ee8a7`
- Lane: `runtime_family_backlog`
- Status: `runtime_template_candidate_requires_executor_tests`
- Cards: `2` (Ashling, Flame Dancer, Soul Immolation)
- Subpatterns: `2`
- Required evidence: `["runtime executor implementation", "focused runtime tests", "queue delta report"]`

### board_wipe_choice / board_wipe / destroy_all_permanents_or_creatures_variant_v1

- Pattern id: `xmage_pattern:8830b1a89c4c10491056`
- Lane: `runtime_family_backlog`
- Status: `runtime_template_candidate_requires_executor_tests`
- Cards: `2` (Armageddon, Ultima)
- Subpatterns: `2`
- Required evidence: `["runtime executor implementation", "focused runtime tests", "queue delta report"]`

### token_maker / token_maker / xmage_create_token_variant_aclazotzdeepestbetrayal_v1

- Pattern id: `xmage_pattern:f3f6890135e546660c3d`
- Lane: `runtime_family_backlog`
- Status: `fragmented_runtime_observation_only`
- Cards: `1` (Aclazotz, Deepest Betrayal // Temple of the Dead)
- Subpatterns: `1`
- Required evidence: `["taxonomy support", "test miner coverage", "do not open broad runtime by raw family count"]`
