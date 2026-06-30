# XMage Shadow Pattern Registry

- Generated at: `2026-06-30T16:13:42+00:00`
- Status: `ready`
- Mutations performed: `[]`
- Promotion status: `shadow_only`

## Summary

- `proposal_count`: `109`
- `pattern_count`: `20`
- `lane_counts`: `{"split_scope_backlog": 109}`
- `pattern_status_counts`: `{"candidate_template_requires_review_tests": 10, "requires_subpattern_split_before_promotion": 10}`
- `card_counts_by_pattern_status`: `{"candidate_template_requires_review_tests": 14, "requires_subpattern_split_before_promotion": 95}`
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
| `manual_model/external_reference_required_manual_model/xmage_reference_requires_manual_model_review_v1` | `split_scope_backlog` | `requires_subpattern_split_before_promotion` | 49 | 27 | Split by ability kind, target constraints, triggers, costs, and secondary effects before promotion. |
| `tutor/tutor/xmage_library_search_variant_review_v1` | `split_scope_backlog` | `requires_subpattern_split_before_promotion` | 9 | 9 | Split by ability kind, target constraints, triggers, costs, and secondary effects before promotion. |
| `recursion/recursion/xmage_graveyard_return_variant_review_v1` | `split_scope_backlog` | `requires_subpattern_split_before_promotion` | 8 | 5 | Split by ability kind, target constraints, triggers, costs, and secondary effects before promotion. |
| `free_cast/free_cast/xmage_cast_or_play_from_alternate_zone_variant_review_v1` | `split_scope_backlog` | `requires_subpattern_split_before_promotion` | 7 | 4 | Split by ability kind, target constraints, triggers, costs, and secondary effects before promotion. |
| `targeted_interaction/untap_target/xmage_targeted_untap_variant_review_v1` | `split_scope_backlog` | `requires_subpattern_split_before_promotion` | 7 | 6 | Split by ability kind, target constraints, triggers, costs, and secondary effects before promotion. |
| `targeted_protection/grant_protection_from_chosen_color/xmage_targeted_protection_variant_review_v1` | `split_scope_backlog` | `requires_subpattern_split_before_promotion` | 7 | 5 | Split by ability kind, target constraints, triggers, costs, and secondary effects before promotion. |
| `passive/passive/xmage_static_rule_restriction_or_tax_variant_review_v1` | `split_scope_backlog` | `candidate_template_requires_review_tests` | 3 | 1 | Review before promotion. |
| `ramp_permanent/ramp_permanent/xmage_creature_mana_source_variant_review_v1` | `split_scope_backlog` | `requires_subpattern_split_before_promotion` | 3 | 3 | Split by ability kind, target constraints, triggers, costs, and secondary effects before promotion. |
| `board_wipe_choice/board_wipe/xmage_mass_removal_or_sacrifice_variant_review_v1` | `split_scope_backlog` | `requires_subpattern_split_before_promotion` | 2 | 2 | Split by ability kind, target constraints, triggers, costs, and secondary effects before promotion. |
| `passive/passive/static_cast_as_flash_permission_variant_review_v1` | `split_scope_backlog` | `candidate_template_requires_review_tests` | 2 | 1 | Review before promotion. |
| `targeted_interaction/multi_target_damage/xmage_multi_target_damage_variant_review_v1` | `split_scope_backlog` | `requires_subpattern_split_before_promotion` | 2 | 2 | Split by ability kind, target constraints, triggers, costs, and secondary effects before promotion. |
| `topdeck_play/topdeck_play/xmage_cast_or_play_from_alternate_zone_variant_review_v1` | `split_scope_backlog` | `candidate_template_requires_review_tests` | 2 | 1 | Review before promotion. |
| `copy_spell_engine/copy_spell/xmage_copy_stack_object_variant_review_v1` | `split_scope_backlog` | `candidate_template_requires_review_tests` | 1 | 1 | Review before promotion. |
| `draw_engine/draw_engine/xmage_draw_card_variant_review_v1` | `split_scope_backlog` | `candidate_template_requires_review_tests` | 1 | 1 | Review before promotion. |
| `life_total_change/life_gain/xmage_life_gain_variant_review_v1` | `split_scope_backlog` | `candidate_template_requires_review_tests` | 1 | 1 | Review before promotion. |
| `ramp_permanent/ramp_permanent/xmage_artifact_mana_source_variant_review_v1` | `split_scope_backlog` | `candidate_template_requires_review_tests` | 1 | 1 | Review before promotion. |
| `ramp_permanent/ramp_permanent/xmage_land_mana_source_variant_review_v1` | `split_scope_backlog` | `candidate_template_requires_review_tests` | 1 | 1 | Review before promotion. |
| `targeted_interaction/removal_destroy/targeted_destroy_variant_v1` | `split_scope_backlog` | `requires_subpattern_split_before_promotion` | 1 | 1 | Split by ability kind, target constraints, triggers, costs, and secondary effects before promotion. |
| `targeted_interaction/redirect_target/xmage_choose_new_targets_variant_review_v1` | `split_scope_backlog` | `candidate_template_requires_review_tests` | 1 | 1 | Review before promotion. |
| `targeted_interaction/draw_cards/xmage_draw_card_variant_review_v1` | `split_scope_backlog` | `candidate_template_requires_review_tests` | 1 | 1 | Review before promotion. |

## Top Pattern Details

### manual_model / external_reference_required_manual_model / xmage_reference_requires_manual_model_review_v1

- Pattern id: `xmage_pattern:451bb2376a371c20ff2c`
- Lane: `split_scope_backlog`
- Status: `requires_subpattern_split_before_promotion`
- Cards: `49` (All Is Dust, Altar of Dementia, Amphibian Downpour, Autumn's Veil, Carpet of Flowers, Collector Ouphe, Colonel Autumn, Commandeer, Defense Grid, Delney, Streetwise Lookout)
- Subpatterns: `27`
- Required evidence: `["subpattern split", "focused ManaLoom tests per subpattern", "package generation only for exact supported subpatterns"]`

### tutor / tutor / xmage_library_search_variant_review_v1

- Pattern id: `xmage_pattern:826ded38ac7738fc5e9b`
- Lane: `split_scope_backlog`
- Status: `requires_subpattern_split_before_promotion`
- Cards: `9` (Beseech the Mirror, Entomb, Gifts Ungiven, Intuition, Invasion of Ikoria, Opposition Agent, Oswald Fiddlebender, Praetor's Grasp, Transmute Artifact)
- Subpatterns: `9`
- Required evidence: `["subpattern split", "focused ManaLoom tests per subpattern", "package generation only for exact supported subpatterns"]`

### recursion / recursion / xmage_graveyard_return_variant_review_v1

- Pattern id: `xmage_pattern:13c4c7948f2b787f7acd`
- Lane: `split_scope_backlog`
- Status: `requires_subpattern_split_before_promotion`
- Cards: `8` (Bond of Insight, Endurance, Experimental Overload, Flashback, Gandalf's Sanction, Moonshadow, Pulsemage Advocate, Worldfire)
- Subpatterns: `5`
- Required evidence: `["subpattern split", "focused ManaLoom tests per subpattern", "package generation only for exact supported subpatterns"]`

### free_cast / free_cast / xmage_cast_or_play_from_alternate_zone_variant_review_v1

- Pattern id: `xmage_pattern:acc6128f873af5ee076e`
- Lane: `split_scope_backlog`
- Status: `requires_subpattern_split_before_promotion`
- Cards: `7` (Aminatou's Augury, Arcane Bombardment, Epic Experiment, Etali, Primal Conqueror, Radiant Scrollwielder, Squee, the Immortal, Summons of Saruman)
- Subpatterns: `4`
- Required evidence: `["subpattern split", "focused ManaLoom tests per subpattern", "package generation only for exact supported subpatterns"]`

### targeted_interaction / untap_target / xmage_targeted_untap_variant_review_v1

- Pattern id: `xmage_pattern:17bfdc5de1bd268961c2`
- Lane: `split_scope_backlog`
- Status: `requires_subpattern_split_before_promotion`
- Cards: `7` (Manifold Key, Nature's Chosen, Tezzeret the Seeker, Tezzeret, Cruel Captain, Thousand-Year Elixir, Tyvar, Jubilant Brawler, Voltaic Key)
- Subpatterns: `6`
- Required evidence: `["subpattern split", "focused ManaLoom tests per subpattern", "package generation only for exact supported subpatterns"]`

### targeted_protection / grant_protection_from_chosen_color / xmage_targeted_protection_variant_review_v1

- Pattern id: `xmage_pattern:5f8c877ffd79caf5b6be`
- Lane: `split_scope_backlog`
- Status: `requires_subpattern_split_before_promotion`
- Cards: `7` (Akroma's Will, Clout of the Dominus, Hellkite Courser, Protective Bubble, Sylvan Safekeeper, Volatile Stormdrake, Zephid's Embrace)
- Subpatterns: `5`
- Required evidence: `["subpattern split", "focused ManaLoom tests per subpattern", "package generation only for exact supported subpatterns"]`

### passive / passive / xmage_static_rule_restriction_or_tax_variant_review_v1

- Pattern id: `xmage_pattern:d82c95d9e316c01aa6e2`
- Lane: `split_scope_backlog`
- Status: `candidate_template_requires_review_tests`
- Cards: `3` (Aven Interrupter, Hope of Ghirapur, Void Winnower)
- Subpatterns: `1`
- Required evidence: `["review", "focused test", "promotion gate"]`

### ramp_permanent / ramp_permanent / xmage_creature_mana_source_variant_review_v1

- Pattern id: `xmage_pattern:b256332cd625a288e19d`
- Lane: `split_scope_backlog`
- Status: `requires_subpattern_split_before_promotion`
- Cards: `3` ("Name Sticker" Goblin, Ashling, Flame Dancer, Blazing Firesinger)
- Subpatterns: `3`
- Required evidence: `["subpattern split", "focused ManaLoom tests per subpattern", "package generation only for exact supported subpatterns"]`

### board_wipe_choice / board_wipe / xmage_mass_removal_or_sacrifice_variant_review_v1

- Pattern id: `xmage_pattern:0536d374294086471dab`
- Lane: `split_scope_backlog`
- Status: `requires_subpattern_split_before_promotion`
- Cards: `2` (Culling Ritual, Dauntless Dismantler)
- Subpatterns: `2`
- Required evidence: `["subpattern split", "focused ManaLoom tests per subpattern", "package generation only for exact supported subpatterns"]`

### passive / passive / static_cast_as_flash_permission_variant_review_v1

- Pattern id: `xmage_pattern:aabdfb3e2398480521ad`
- Lane: `split_scope_backlog`
- Status: `candidate_template_requires_review_tests`
- Cards: `2` (Tidal Barracuda, Valley Floodcaller)
- Subpatterns: `1`
- Required evidence: `["review", "focused test", "promotion gate"]`

### targeted_interaction / multi_target_damage / xmage_multi_target_damage_variant_review_v1

- Pattern id: `xmage_pattern:14e0677d968e9febefb0`
- Lane: `split_scope_backlog`
- Status: `requires_subpattern_split_before_promotion`
- Cards: `2` (Fury, Pyrokinesis)
- Subpatterns: `2`
- Required evidence: `["subpattern split", "focused ManaLoom tests per subpattern", "package generation only for exact supported subpatterns"]`

### topdeck_play / topdeck_play / xmage_cast_or_play_from_alternate_zone_variant_review_v1

- Pattern id: `xmage_pattern:75bb38142301fb533e61`
- Lane: `split_scope_backlog`
- Status: `candidate_template_requires_review_tests`
- Cards: `2` (Bolas's Citadel, Mystic Forge)
- Subpatterns: `1`
- Required evidence: `["review", "focused test", "promotion gate"]`
