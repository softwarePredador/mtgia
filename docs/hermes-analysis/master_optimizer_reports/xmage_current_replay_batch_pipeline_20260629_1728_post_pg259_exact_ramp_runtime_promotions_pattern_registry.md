# XMage Shadow Pattern Registry

- Generated at: `2026-06-29T17:15:29+00:00`
- Status: `ready`
- Mutations performed: `[]`
- Promotion status: `shadow_only`

## Summary

- `proposal_count`: `141`
- `pattern_count`: `22`
- `lane_counts`: `{"manual_mapper_backlog": 63, "package_ready_unprepared": 1, "split_scope_backlog": 77}`
- `pattern_status_counts`: `{"candidate_template_requires_review_tests": 7, "manual_model_observation_only": 1, "ready_for_pg_package_generation": 1, "requires_subpattern_split_before_promotion": 13}`
- `card_counts_by_pattern_status`: `{"candidate_template_requires_review_tests": 10, "manual_model_observation_only": 63, "ready_for_pg_package_generation": 1, "requires_subpattern_split_before_promotion": 67}`
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
| `ramp_engine/ramp_engine/spell_cast_red_mana_trigger_boast_harnfel_annotation_v1` | `package_ready_unprepared` | `ready_for_pg_package_generation` | 1 | 1 | Generate a PG package before any runtime work. |
| `recursion/recursion/xmage_graveyard_return_variant_review_v1` | `split_scope_backlog` | `requires_subpattern_split_before_promotion` | 11 | 6 | Split by ability kind, target constraints, triggers, costs, and secondary effects before promotion. |
| `tutor/tutor/xmage_library_search_variant_review_v1` | `split_scope_backlog` | `requires_subpattern_split_before_promotion` | 10 | 10 | Split by ability kind, target constraints, triggers, costs, and secondary effects before promotion. |
| `free_cast/free_cast/xmage_cast_or_play_from_alternate_zone_variant_review_v1` | `split_scope_backlog` | `requires_subpattern_split_before_promotion` | 9 | 5 | Split by ability kind, target constraints, triggers, costs, and secondary effects before promotion. |
| `targeted_protection/grant_protection_from_chosen_color/xmage_targeted_protection_variant_review_v1` | `split_scope_backlog` | `requires_subpattern_split_before_promotion` | 8 | 6 | Split by ability kind, target constraints, triggers, costs, and secondary effects before promotion. |
| `targeted_interaction/untap_target/xmage_targeted_untap_variant_review_v1` | `split_scope_backlog` | `requires_subpattern_split_before_promotion` | 7 | 6 | Split by ability kind, target constraints, triggers, costs, and secondary effects before promotion. |
| `ramp_permanent/ramp_permanent/xmage_creature_mana_source_variant_review_v1` | `split_scope_backlog` | `requires_subpattern_split_before_promotion` | 5 | 3 | Split by ability kind, target constraints, triggers, costs, and secondary effects before promotion. |
| `draw_engine/draw_engine/xmage_draw_card_variant_review_v1` | `split_scope_backlog` | `requires_subpattern_split_before_promotion` | 4 | 3 | Split by ability kind, target constraints, triggers, costs, and secondary effects before promotion. |
| `board_wipe_choice/board_wipe/xmage_mass_removal_or_sacrifice_variant_review_v1` | `split_scope_backlog` | `requires_subpattern_split_before_promotion` | 3 | 2 | Split by ability kind, target constraints, triggers, costs, and secondary effects before promotion. |
| `passive/passive/xmage_static_rule_restriction_or_tax_variant_review_v1` | `split_scope_backlog` | `candidate_template_requires_review_tests` | 3 | 1 | Review before promotion. |
| `topdeck_play/topdeck_play/xmage_cast_or_play_from_alternate_zone_variant_review_v1` | `split_scope_backlog` | `requires_subpattern_split_before_promotion` | 3 | 2 | Split by ability kind, target constraints, triggers, costs, and secondary effects before promotion. |
| `passive/passive/static_cast_as_flash_permission_variant_review_v1` | `split_scope_backlog` | `candidate_template_requires_review_tests` | 2 | 1 | Review before promotion. |
| `ramp_permanent/ramp_permanent/xmage_artifact_mana_source_variant_review_v1` | `split_scope_backlog` | `requires_subpattern_split_before_promotion` | 2 | 2 | Split by ability kind, target constraints, triggers, costs, and secondary effects before promotion. |
| `ramp_ritual/ramp_ritual/xmage_spell_mana_ritual_variant_review_v1` | `split_scope_backlog` | `requires_subpattern_split_before_promotion` | 2 | 2 | Split by ability kind, target constraints, triggers, costs, and secondary effects before promotion. |
| `targeted_interaction/multi_target_damage/xmage_multi_target_damage_variant_review_v1` | `split_scope_backlog` | `requires_subpattern_split_before_promotion` | 2 | 2 | Split by ability kind, target constraints, triggers, costs, and secondary effects before promotion. |
| `copy_spell_engine/copy_spell/xmage_copy_stack_object_variant_review_v1` | `split_scope_backlog` | `candidate_template_requires_review_tests` | 1 | 1 | Review before promotion. |
| `life_total_change/life_gain/xmage_life_gain_variant_review_v1` | `split_scope_backlog` | `candidate_template_requires_review_tests` | 1 | 1 | Review before promotion. |
| `ramp_permanent/ramp_permanent/xmage_land_mana_source_variant_review_v1` | `split_scope_backlog` | `candidate_template_requires_review_tests` | 1 | 1 | Review before promotion. |
| `targeted_interaction/removal_destroy/targeted_destroy_variant_v1` | `split_scope_backlog` | `requires_subpattern_split_before_promotion` | 1 | 1 | Split by ability kind, target constraints, triggers, costs, and secondary effects before promotion. |
| `targeted_interaction/redirect_target/xmage_choose_new_targets_variant_review_v1` | `split_scope_backlog` | `candidate_template_requires_review_tests` | 1 | 1 | Review before promotion. |
| `targeted_interaction/draw_cards/xmage_draw_card_variant_review_v1` | `split_scope_backlog` | `candidate_template_requires_review_tests` | 1 | 1 | Review before promotion. |
| `manual_model/external_reference_required_manual_model/xmage_reference_requires_manual_model_review_v1` | `manual_mapper_backlog` | `manual_model_observation_only` | 63 | 30 | Keep after package, split-scope, and homogeneous-runtime lanes. |

## Top Pattern Details

### ramp_engine / ramp_engine / spell_cast_red_mana_trigger_boast_harnfel_annotation_v1

- Pattern id: `xmage_pattern:cc443abde09e5530552a`
- Lane: `package_ready_unprepared`
- Status: `ready_for_pg_package_generation`
- Cards: `1` (Birgi, God of Storytelling // Harnfel, Horn of Bounty)
- Subpatterns: `1`
- Required evidence: `["package precheck", "approved exact PostgreSQL apply command", "postcheck", "PG -> Hermes sync"]`

### recursion / recursion / xmage_graveyard_return_variant_review_v1

- Pattern id: `xmage_pattern:13c4c7948f2b787f7acd`
- Lane: `split_scope_backlog`
- Status: `requires_subpattern_split_before_promotion`
- Cards: `11` (Bond of Insight, Charmbreaker Devils, Codex Shredder, Endurance, Experimental Overload, Flashback, Gandalf's Sanction, Moonshadow, Perpetual Timepiece, Pulsemage Advocate)
- Subpatterns: `6`
- Required evidence: `["subpattern split", "focused ManaLoom tests per subpattern", "package generation only for exact supported subpatterns"]`

### tutor / tutor / xmage_library_search_variant_review_v1

- Pattern id: `xmage_pattern:826ded38ac7738fc5e9b`
- Lane: `split_scope_backlog`
- Status: `requires_subpattern_split_before_promotion`
- Cards: `10` (Beseech the Mirror, Deathbellow War Cry, Entomb, Gifts Ungiven, Intuition, Invasion of Ikoria, Opposition Agent, Oswald Fiddlebender, Praetor's Grasp, Transmute Artifact)
- Subpatterns: `10`
- Required evidence: `["subpattern split", "focused ManaLoom tests per subpattern", "package generation only for exact supported subpatterns"]`

### free_cast / free_cast / xmage_cast_or_play_from_alternate_zone_variant_review_v1

- Pattern id: `xmage_pattern:acc6128f873af5ee076e`
- Lane: `split_scope_backlog`
- Status: `requires_subpattern_split_before_promotion`
- Cards: `9` (Aminatou's Augury, Arcane Bombardment, Assemble the Players, Chaos Wand, Epic Experiment, Etali, Primal Conqueror, Radiant Scrollwielder, Squee, the Immortal, Summons of Saruman)
- Subpatterns: `5`
- Required evidence: `["subpattern split", "focused ManaLoom tests per subpattern", "package generation only for exact supported subpatterns"]`

### targeted_protection / grant_protection_from_chosen_color / xmage_targeted_protection_variant_review_v1

- Pattern id: `xmage_pattern:5f8c877ffd79caf5b6be`
- Lane: `split_scope_backlog`
- Status: `requires_subpattern_split_before_promotion`
- Cards: `8` (Akroma's Will, Clout of the Dominus, Eight-and-a-Half-Tails, Hellkite Courser, Protective Bubble, Sylvan Safekeeper, Volatile Stormdrake, Zephid's Embrace)
- Subpatterns: `6`
- Required evidence: `["subpattern split", "focused ManaLoom tests per subpattern", "package generation only for exact supported subpatterns"]`

### targeted_interaction / untap_target / xmage_targeted_untap_variant_review_v1

- Pattern id: `xmage_pattern:17bfdc5de1bd268961c2`
- Lane: `split_scope_backlog`
- Status: `requires_subpattern_split_before_promotion`
- Cards: `7` (Manifold Key, Nature's Chosen, Tezzeret the Seeker, Tezzeret, Cruel Captain, Thousand-Year Elixir, Tyvar, Jubilant Brawler, Voltaic Key)
- Subpatterns: `6`
- Required evidence: `["subpattern split", "focused ManaLoom tests per subpattern", "package generation only for exact supported subpatterns"]`

### ramp_permanent / ramp_permanent / xmage_creature_mana_source_variant_review_v1

- Pattern id: `xmage_pattern:b256332cd625a288e19d`
- Lane: `split_scope_backlog`
- Status: `requires_subpattern_split_before_promotion`
- Cards: `5` ("Name Sticker" Goblin, Ashling, Flame Dancer, Blazing Firesinger, Electro, Assaulting Battery, Neheb, the Eternal)
- Subpatterns: `3`
- Required evidence: `["subpattern split", "focused ManaLoom tests per subpattern", "package generation only for exact supported subpatterns"]`

### draw_engine / draw_engine / xmage_draw_card_variant_review_v1

- Pattern id: `xmage_pattern:360faa5d8dc0e38bd662`
- Lane: `split_scope_backlog`
- Status: `requires_subpattern_split_before_promotion`
- Cards: `4` (Alhammarret's Archive, Currency Converter, Naktamun Lorespinner // Wheel of Fortune, Tymna the Weaver)
- Subpatterns: `3`
- Required evidence: `["subpattern split", "focused ManaLoom tests per subpattern", "package generation only for exact supported subpatterns"]`

### board_wipe_choice / board_wipe / xmage_mass_removal_or_sacrifice_variant_review_v1

- Pattern id: `xmage_pattern:0536d374294086471dab`
- Lane: `split_scope_backlog`
- Status: `requires_subpattern_split_before_promotion`
- Cards: `3` (Culling Ritual, Dauntless Dismantler, Karn's Sylex)
- Subpatterns: `2`
- Required evidence: `["subpattern split", "focused ManaLoom tests per subpattern", "package generation only for exact supported subpatterns"]`

### passive / passive / xmage_static_rule_restriction_or_tax_variant_review_v1

- Pattern id: `xmage_pattern:d82c95d9e316c01aa6e2`
- Lane: `split_scope_backlog`
- Status: `candidate_template_requires_review_tests`
- Cards: `3` (Aven Interrupter, Hope of Ghirapur, Void Winnower)
- Subpatterns: `1`
- Required evidence: `["review", "focused test", "promotion gate"]`

### topdeck_play / topdeck_play / xmage_cast_or_play_from_alternate_zone_variant_review_v1

- Pattern id: `xmage_pattern:75bb38142301fb533e61`
- Lane: `split_scope_backlog`
- Status: `requires_subpattern_split_before_promotion`
- Cards: `3` (Bolas's Citadel, Lens of Clarity, Mystic Forge)
- Subpatterns: `2`
- Required evidence: `["subpattern split", "focused ManaLoom tests per subpattern", "package generation only for exact supported subpatterns"]`

### passive / passive / static_cast_as_flash_permission_variant_review_v1

- Pattern id: `xmage_pattern:aabdfb3e2398480521ad`
- Lane: `split_scope_backlog`
- Status: `candidate_template_requires_review_tests`
- Cards: `2` (Tidal Barracuda, Valley Floodcaller)
- Subpatterns: `1`
- Required evidence: `["review", "focused test", "promotion gate"]`
