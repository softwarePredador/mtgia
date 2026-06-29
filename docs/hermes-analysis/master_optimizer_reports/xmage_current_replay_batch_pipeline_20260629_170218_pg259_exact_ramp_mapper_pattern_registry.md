# XMage Shadow Pattern Registry

- Generated at: `2026-06-29T17:02:19+00:00`
- Status: `ready`
- Mutations performed: `[]`
- Promotion status: `shadow_only`

## Summary

- `proposal_count`: `148`
- `pattern_count`: `29`
- `lane_counts`: `{"manual_mapper_backlog": 63, "package_ready_unprepared": 8, "split_scope_backlog": 77}`
- `pattern_status_counts`: `{"candidate_template_requires_review_tests": 7, "manual_model_observation_only": 1, "ready_for_pg_package_generation": 8, "requires_subpattern_split_before_promotion": 13}`
- `card_counts_by_pattern_status`: `{"candidate_template_requires_review_tests": 10, "manual_model_observation_only": 63, "ready_for_pg_package_generation": 8, "requires_subpattern_split_before_promotion": 67}`
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
| `ramp_permanent/ramp_permanent/colorless_mana_rock_planar_die_annotation_v1` | `package_ready_unprepared` | `ready_for_pg_package_generation` | 1 | 1 | Generate a PG package before any runtime work. |
| `ramp_permanent/ramp_permanent/colorless_or_legendary_any_color_uncounterable_mana_dork_v1` | `package_ready_unprepared` | `ready_for_pg_package_generation` | 1 | 1 | Generate a PG package before any runtime work. |
| `ramp_permanent/ramp_permanent/greatest_power_any_color_mana_dork_etb_draw_annotation_v1` | `package_ready_unprepared` | `ready_for_pg_package_generation` | 1 | 1 | Generate a PG package before any runtime work. |
| `ramp_permanent/ramp_permanent/green_mana_dork_minus_counter_self_untap_v1` | `package_ready_unprepared` | `ready_for_pg_package_generation` | 1 | 1 | Generate a PG package before any runtime work. |
| `ramp_permanent/ramp_permanent/land_type_mana_dork_plus_counter_triples_adapt_v1` | `package_ready_unprepared` | `ready_for_pg_package_generation` | 1 | 1 | Generate a PG package before any runtime work. |
| `ramp_permanent/ramp_permanent/mdfc_blue_land_pay_three_life_flash_redirect_creature_annotation_v1` | `package_ready_unprepared` | `ready_for_pg_package_generation` | 1 | 1 | Generate a PG package before any runtime work. |
| `ramp_permanent/ramp_permanent/mdfc_green_land_pay_three_life_spell_fight_annotation_v1` | `package_ready_unprepared` | `ready_for_pg_package_generation` | 1 | 1 | Generate a PG package before any runtime work. |
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
- Cards: `1` (Birgi, God of Storytelling)
- Subpatterns: `1`
- Required evidence: `["package precheck", "approved exact PostgreSQL apply command", "postcheck", "PG -> Hermes sync"]`

### ramp_permanent / ramp_permanent / colorless_mana_rock_planar_die_annotation_v1

- Pattern id: `xmage_pattern:612de0ba3bb54f7497a8`
- Lane: `package_ready_unprepared`
- Status: `ready_for_pg_package_generation`
- Cards: `1` (Fractured Powerstone)
- Subpatterns: `1`
- Required evidence: `["package precheck", "approved exact PostgreSQL apply command", "postcheck", "PG -> Hermes sync"]`

### ramp_permanent / ramp_permanent / colorless_or_legendary_any_color_uncounterable_mana_dork_v1

- Pattern id: `xmage_pattern:4bbe93bb5b98c622c2ba`
- Lane: `package_ready_unprepared`
- Status: `ready_for_pg_package_generation`
- Cards: `1` (Delighted Halfling)
- Subpatterns: `1`
- Required evidence: `["package precheck", "approved exact PostgreSQL apply command", "postcheck", "PG -> Hermes sync"]`

### ramp_permanent / ramp_permanent / greatest_power_any_color_mana_dork_etb_draw_annotation_v1

- Pattern id: `xmage_pattern:d5fb8a36de74127032ff`
- Lane: `package_ready_unprepared`
- Status: `ready_for_pg_package_generation`
- Cards: `1` (Selvala, Heart of the Wilds)
- Subpatterns: `1`
- Required evidence: `["package precheck", "approved exact PostgreSQL apply command", "postcheck", "PG -> Hermes sync"]`

### ramp_permanent / ramp_permanent / green_mana_dork_minus_counter_self_untap_v1

- Pattern id: `xmage_pattern:7509b0be417680caece3`
- Lane: `package_ready_unprepared`
- Status: `ready_for_pg_package_generation`
- Cards: `1` (Devoted Druid)
- Subpatterns: `1`
- Required evidence: `["package precheck", "approved exact PostgreSQL apply command", "postcheck", "PG -> Hermes sync"]`

### ramp_permanent / ramp_permanent / land_type_mana_dork_plus_counter_triples_adapt_v1

- Pattern id: `xmage_pattern:cd8134d22370efa1fcfc`
- Lane: `package_ready_unprepared`
- Status: `ready_for_pg_package_generation`
- Cards: `1` (Incubation Druid)
- Subpatterns: `1`
- Required evidence: `["package precheck", "approved exact PostgreSQL apply command", "postcheck", "PG -> Hermes sync"]`

### ramp_permanent / ramp_permanent / mdfc_blue_land_pay_three_life_flash_redirect_creature_annotation_v1

- Pattern id: `xmage_pattern:b562e3d99cb415caa6af`
- Lane: `package_ready_unprepared`
- Status: `ready_for_pg_package_generation`
- Cards: `1` (Hydroelectric Specimen)
- Subpatterns: `1`
- Required evidence: `["package precheck", "approved exact PostgreSQL apply command", "postcheck", "PG -> Hermes sync"]`

### ramp_permanent / ramp_permanent / mdfc_green_land_pay_three_life_spell_fight_annotation_v1

- Pattern id: `xmage_pattern:f8de8261358f82653c2c`
- Lane: `package_ready_unprepared`
- Status: `ready_for_pg_package_generation`
- Cards: `1` (Bridgeworks Battle)
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
