# XMage Shadow Pattern Registry

- Generated at: `2026-06-29T12:20:48+00:00`
- Status: `ready`
- Mutations performed: `[]`
- Promotion status: `shadow_only`

## Summary

- `proposal_count`: `139`
- `pattern_count`: `19`
- `lane_counts`: `{"manual_mapper_backlog": 63, "runtime_family_backlog": 1, "split_scope_backlog": 75}`
- `pattern_status_counts`: `{"candidate_template_requires_review_tests": 8, "fragmented_runtime_observation_only": 1, "manual_model_observation_only": 1, "requires_subpattern_split_before_promotion": 9}`
- `card_counts_by_pattern_status`: `{"candidate_template_requires_review_tests": 14, "fragmented_runtime_observation_only": 1, "manual_model_observation_only": 63, "requires_subpattern_split_before_promotion": 61}`
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
| `ramp_permanent/ramp_permanent/xmage_creature_mana_source_variant_review_v1` | `split_scope_backlog` | `requires_subpattern_split_before_promotion` | 11 | 7 | Split by ability kind, target constraints, triggers, costs, and secondary effects before promotion. |
| `ramp_permanent/ramp_permanent/xmage_land_mana_source_variant_review_v1` | `split_scope_backlog` | `requires_subpattern_split_before_promotion` | 10 | 10 | Split by ability kind, target constraints, triggers, costs, and secondary effects before promotion. |
| `tutor/tutor/xmage_library_search_variant_review_v1` | `split_scope_backlog` | `requires_subpattern_split_before_promotion` | 10 | 10 | Split by ability kind, target constraints, triggers, costs, and secondary effects before promotion. |
| `ramp_permanent/ramp_permanent/xmage_artifact_mana_source_variant_review_v1` | `split_scope_backlog` | `requires_subpattern_split_before_promotion` | 8 | 8 | Split by ability kind, target constraints, triggers, costs, and secondary effects before promotion. |
| `free_cast/free_cast/xmage_cast_or_play_from_alternate_zone_variant_review_v1` | `split_scope_backlog` | `requires_subpattern_split_before_promotion` | 6 | 4 | Split by ability kind, target constraints, triggers, costs, and secondary effects before promotion. |
| `recursion/recursion/xmage_graveyard_return_variant_review_v1` | `split_scope_backlog` | `requires_subpattern_split_before_promotion` | 6 | 4 | Split by ability kind, target constraints, triggers, costs, and secondary effects before promotion. |
| `targeted_protection/grant_protection_from_chosen_color/xmage_targeted_protection_variant_review_v1` | `split_scope_backlog` | `requires_subpattern_split_before_promotion` | 6 | 4 | Split by ability kind, target constraints, triggers, costs, and secondary effects before promotion. |
| `passive/passive/xmage_static_rule_restriction_or_tax_variant_review_v1` | `split_scope_backlog` | `candidate_template_requires_review_tests` | 5 | 1 | Review before promotion. |
| `board_wipe_choice/board_wipe/xmage_mass_removal_or_sacrifice_variant_review_v1` | `split_scope_backlog` | `requires_subpattern_split_before_promotion` | 2 | 2 | Split by ability kind, target constraints, triggers, costs, and secondary effects before promotion. |
| `draw_engine/draw_engine/xmage_draw_card_variant_review_v1` | `split_scope_backlog` | `candidate_template_requires_review_tests` | 2 | 1 | Review before promotion. |
| `targeted_interaction/draw_cards/xmage_draw_card_variant_review_v1` | `split_scope_backlog` | `candidate_template_requires_review_tests` | 2 | 1 | Review before promotion. |
| `untap_land_engine/untap_land_engine/xmage_land_untap_variant_review_v1` | `split_scope_backlog` | `requires_subpattern_split_before_promotion` | 2 | 2 | Split by ability kind, target constraints, triggers, costs, and secondary effects before promotion. |
| `mill_spell/mill_engine/artifact_tap_sacrifice_permanent_target_player_mill_v1` | `split_scope_backlog` | `candidate_template_requires_review_tests` | 1 | 1 | Review before promotion. |
| `modal_spell/modal_spell/modal_artifact_tutor_or_artifact_graveyard_to_hand_v1` | `split_scope_backlog` | `candidate_template_requires_review_tests` | 1 | 1 | Review before promotion. |
| `topdeck_play/topdeck_play/xmage_cast_or_play_from_alternate_zone_variant_review_v1` | `split_scope_backlog` | `candidate_template_requires_review_tests` | 1 | 1 | Review before promotion. |
| `tutor/tutor/conditional_delirium_restricted_or_any_tutor_to_hand_v1` | `split_scope_backlog` | `candidate_template_requires_review_tests` | 1 | 1 | Review before promotion. |
| `tutor/tutor/pact_green_creature_tutor_to_hand_delayed_payment_v1` | `split_scope_backlog` | `candidate_template_requires_review_tests` | 1 | 1 | Review before promotion. |
| `token_maker/token_maker/xmage_create_token_variant_hazelsbrewmaster_v1` | `runtime_family_backlog` | `fragmented_runtime_observation_only` | 1 | 1 | Keep as registry evidence; wait for taxonomy/test-miner support before executor work. |
| `manual_model/external_reference_required_manual_model/xmage_reference_requires_manual_model_review_v1` | `manual_mapper_backlog` | `manual_model_observation_only` | 63 | 29 | Keep after package, split-scope, and homogeneous-runtime lanes. |

## Top Pattern Details

### ramp_permanent / ramp_permanent / xmage_creature_mana_source_variant_review_v1

- Pattern id: `xmage_pattern:b256332cd625a288e19d`
- Lane: `split_scope_backlog`
- Status: `requires_subpattern_split_before_promotion`
- Cards: `11` ("Name Sticker" Goblin, Blazing Firesinger, Delighted Halfling, Devoted Druid, Faeburrow Elder, Incubation Druid, Mardu Devotee, Orcish Lumberjack, Reckless Barbarian, Selvala, Heart of the Wilds)
- Subpatterns: `7`
- Required evidence: `["subpattern split", "focused ManaLoom tests per subpattern", "package generation only for exact supported subpatterns"]`

### ramp_permanent / ramp_permanent / xmage_land_mana_source_variant_review_v1

- Pattern id: `xmage_pattern:6204ec24b582c06a65e9`
- Lane: `split_scope_backlog`
- Status: `requires_subpattern_split_before_promotion`
- Cards: `10` (Bridgeworks Battle, Cavern of Souls, City of Traitors, Crystal Vein, Emergence Zone, Forbidden Orchard, Growing Rites of Itlimoc, Hydroelectric Specimen, Spinerock Knoll, Starting Town)
- Subpatterns: `10`
- Required evidence: `["subpattern split", "focused ManaLoom tests per subpattern", "package generation only for exact supported subpatterns"]`

### tutor / tutor / xmage_library_search_variant_review_v1

- Pattern id: `xmage_pattern:826ded38ac7738fc5e9b`
- Lane: `split_scope_backlog`
- Status: `requires_subpattern_split_before_promotion`
- Cards: `10` (Beseech the Mirror, Entomb, Gifts Ungiven, Intuition, Invasion of Ikoria, Neoform, Opposition Agent, Praetor's Grasp, Tezzeret the Seeker, Transmute Artifact)
- Subpatterns: `10`
- Required evidence: `["subpattern split", "focused ManaLoom tests per subpattern", "package generation only for exact supported subpatterns"]`

### ramp_permanent / ramp_permanent / xmage_artifact_mana_source_variant_review_v1

- Pattern id: `xmage_pattern:ca27b6a9e2c974306bab`
- Lane: `split_scope_backlog`
- Status: `requires_subpattern_split_before_promotion`
- Cards: `8` (Ashnod's Altar, Birgi, God of Storytelling, Chrome Mox, Cursed Mirror, Fractured Powerstone, Lion's Eye Diamond, Mox Diamond, Prismatic Lens)
- Subpatterns: `8`
- Required evidence: `["subpattern split", "focused ManaLoom tests per subpattern", "package generation only for exact supported subpatterns"]`

### free_cast / free_cast / xmage_cast_or_play_from_alternate_zone_variant_review_v1

- Pattern id: `xmage_pattern:acc6128f873af5ee076e`
- Lane: `split_scope_backlog`
- Status: `requires_subpattern_split_before_promotion`
- Cards: `6` (Aminatou's Augury, Epic Experiment, Etali, Primal Conqueror, One with the Multiverse, Squee, the Immortal, Summons of Saruman)
- Subpatterns: `4`
- Required evidence: `["subpattern split", "focused ManaLoom tests per subpattern", "package generation only for exact supported subpatterns"]`

### recursion / recursion / xmage_graveyard_return_variant_review_v1

- Pattern id: `xmage_pattern:13c4c7948f2b787f7acd`
- Lane: `split_scope_backlog`
- Status: `requires_subpattern_split_before_promotion`
- Cards: `6` (Bond of Insight, Endurance, Experimental Overload, Gandalf's Sanction, Moonshadow, Pulsemage Advocate)
- Subpatterns: `4`
- Required evidence: `["subpattern split", "focused ManaLoom tests per subpattern", "package generation only for exact supported subpatterns"]`

### targeted_protection / grant_protection_from_chosen_color / xmage_targeted_protection_variant_review_v1

- Pattern id: `xmage_pattern:5f8c877ffd79caf5b6be`
- Lane: `split_scope_backlog`
- Status: `requires_subpattern_split_before_promotion`
- Cards: `6` (Clout of the Dominus, Hellkite Courser, Protective Bubble, Sylvan Safekeeper, Volatile Stormdrake, Zephid's Embrace)
- Subpatterns: `4`
- Required evidence: `["subpattern split", "focused ManaLoom tests per subpattern", "package generation only for exact supported subpatterns"]`

### passive / passive / xmage_static_rule_restriction_or_tax_variant_review_v1

- Pattern id: `xmage_pattern:d82c95d9e316c01aa6e2`
- Lane: `split_scope_backlog`
- Status: `candidate_template_requires_review_tests`
- Cards: `5` (Aven Interrupter, Deafening Silence, Hope of Ghirapur, Phyrexian Censor, Void Winnower)
- Subpatterns: `1`
- Required evidence: `["review", "focused test", "promotion gate"]`

### board_wipe_choice / board_wipe / xmage_mass_removal_or_sacrifice_variant_review_v1

- Pattern id: `xmage_pattern:0536d374294086471dab`
- Lane: `split_scope_backlog`
- Status: `requires_subpattern_split_before_promotion`
- Cards: `2` (Culling Ritual, Dauntless Dismantler)
- Subpatterns: `2`
- Required evidence: `["subpattern split", "focused ManaLoom tests per subpattern", "package generation only for exact supported subpatterns"]`

### draw_engine / draw_engine / xmage_draw_card_variant_review_v1

- Pattern id: `xmage_pattern:360faa5d8dc0e38bd662`
- Lane: `split_scope_backlog`
- Status: `candidate_template_requires_review_tests`
- Cards: `2` (Breena, the Demagogue, Tymna the Weaver)
- Subpatterns: `1`
- Required evidence: `["review", "focused test", "promotion gate"]`

### targeted_interaction / draw_cards / xmage_draw_card_variant_review_v1

- Pattern id: `xmage_pattern:6ca1acf96dd5dd6f6b05`
- Lane: `split_scope_backlog`
- Status: `candidate_template_requires_review_tests`
- Cards: `2` (Decaying Time Loop, Drown in Dreams)
- Subpatterns: `1`
- Required evidence: `["review", "focused test", "promotion gate"]`

### untap_land_engine / untap_land_engine / xmage_land_untap_variant_review_v1

- Pattern id: `xmage_pattern:a7864c74e7ca1b02a168`
- Lane: `split_scope_backlog`
- Status: `requires_subpattern_split_before_promotion`
- Cards: `2` (Cloud of Faeries, Nature's Chosen)
- Subpatterns: `2`
- Required evidence: `["subpattern split", "focused ManaLoom tests per subpattern", "package generation only for exact supported subpatterns"]`
