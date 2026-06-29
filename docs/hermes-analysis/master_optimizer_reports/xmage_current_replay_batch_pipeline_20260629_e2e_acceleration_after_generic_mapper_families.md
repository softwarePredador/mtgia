# XMage Semantic Family Classification

Generated at: `2026-06-29T12:20:48+00:00`

Read-only artifact. `mutations_performed=[]`.

- Summary: `{"batch_metadata_candidate_count": 0, "card_count": 139, "family_count": 15, "family_counts": {"board_wipe_choice": 2, "draw_engine": 2, "free_cast": 6, "manual_model": 63, "mill_spell": 1, "modal_spell": 1, "passive": 5, "ramp_permanent": 29, "recursion": 6, "targeted_interaction": 2, "targeted_protection": 6, "token_maker": 1, "topdeck_play": 1, "tutor": 12, "untap_land_engine": 2}, "manual_or_blocked_count": 138, "promotion_lane_counts": {"mapper_metadata_or_test_scenario_required": 63, "runtime_family_implementation_required": 1, "split_family_scope_review_required": 75}, "runtime_family_required_count": 1}`

| Family | Cards | Support | Lane counts | Implementation unit |
| --- | ---: | --- | --- | --- |
| `board_wipe_choice` | 2 | `runtime_family_required` | `{"split_family_scope_review_required": 2}` | multi-player choice/wipe/sacrifice resolution |
| `draw_engine` | 2 | `runtime_family_partially_supported_review_required` | `{"split_family_scope_review_required": 2}` | static and activated draw-engine bookkeeping with delayed card movement |
| `free_cast` | 6 | `runtime_family_partially_supported_review_required` | `{"split_family_scope_review_required": 6}` | cast-without-paying resolvers with source-zone, timing-bypass, and replacement-destination bookkeeping |
| `manual_model` | 63 | `manual_model_required` | `{"mapper_metadata_or_test_scenario_required": 63}` | manual Oracle/reference review |
| `mill_spell` | 1 | `runtime_family_partially_supported_review_required` | `{"split_family_scope_review_required": 1}` | target-player library milling, storm copy counting, and activated mill engines |
| `modal_spell` | 1 | `runtime_family_partially_supported_review_required` | `{"split_family_scope_review_required": 1}` | exact-scope modal resolution with repeated mode selection when the card allows it |
| `passive` | 5 | `runtime_family_partially_supported_review_required` | `{"split_family_scope_review_required": 5}` | static battlefield annotation and passive support execution |
| `ramp_permanent` | 29 | `runtime_family_partially_supported_review_required` | `{"split_family_scope_review_required": 29}` | battlefield mana artifacts and triggered resource permanents |
| `recursion` | 6 | `runtime_family_partially_supported_review_required` | `{"split_family_scope_review_required": 6}` | graveyard target selection, zone movement to hand or battlefield, and replacement-cost annotations |
| `targeted_interaction` | 2 | `runtime_family_partially_supported_review_required` | `{"split_family_scope_review_required": 2}` | target legality, resolution, zone transition, and event provenance |
| `targeted_protection` | 6 | `runtime_supported_family` | `{"split_family_scope_review_required": 6}` | targeted own-creature protection grant and cleanup-aware target legality |
| `token_maker` | 1 | `runtime_family_required` | `{"runtime_family_implementation_required": 1}` | token creation with stats, abilities, duration, and zone cleanup |
| `topdeck_play` | 1 | `runtime_supported_family` | `{"split_family_scope_review_required": 1}` | top-of-library visibility and permission to play cards from library under board-state conditions |
| `tutor` | 12 | `runtime_family_partially_supported_review_required` | `{"split_family_scope_review_required": 12}` | library search, constrained target selection, and zone movement to hand, top, graveyard, or battlefield |
| `untap_land_engine` | 2 | `runtime_family_partially_supported_review_required` | `{"split_family_scope_review_required": 2}` | activated land-untap engines that convert board resources into contextual extra mana |

## Work Units

### board_wipe_choice

- Support: `runtime_family_required`
- Batch strategy: `implement_family_before_metadata_batch`
- Family tests: `[]`
- Cards: `["Culling Ritual", "Dauntless Dismantler"]`

### draw_engine

- Support: `runtime_family_partially_supported_review_required`
- Batch strategy: `split_by_scope_before_metadata_batch`
- Family tests: `[]`
- Cards: `["Tymna the Weaver", "Breena, the Demagogue"]`

### free_cast

- Support: `runtime_family_partially_supported_review_required`
- Batch strategy: `split_by_scope_before_metadata_batch`
- Family tests: `["test_pg102_creative_technique_demonstrates_top_nonland_free_casts", "test_pg191_invoke_calamity_casts_two_hand_or_graveyard_spells_and_exiles_them", "test_pg191_invoke_calamity_respects_total_mana_value_six_and_two_spell_limit"]`
- Cards: `["One with the Multiverse", "Squee, the Immortal", "Aminatou's Augury", "Epic Experiment", "Etali, Primal Conqueror", "Summons of Saruman"]`

### manual_model

- Support: `manual_model_required`
- Batch strategy: `not_batch_safe`
- Family tests: `[]`
- Cards: `["Lim-Dul's Vault", "Carpet of Flowers", "Amphibian Downpour", "Commandeer", "Dismember", "Food Chain", "Freed from the Real", "Jin-Gitaxias, Progress Tyrant"]`

### mill_spell

- Support: `runtime_family_partially_supported_review_required`
- Batch strategy: `split_by_scope_before_metadata_batch`
- Family tests: `["test_brain_freeze_mills_library_instead_of_dealing_life_damage"]`
- Cards: `["Grinding Station"]`

### modal_spell

- Support: `runtime_family_partially_supported_review_required`
- Batch strategy: `split_by_scope_before_metadata_batch`
- Family tests: `[]`
- Cards: `["Scour for Scrap"]`

### passive

- Support: `runtime_family_partially_supported_review_required`
- Batch strategy: `split_by_scope_before_metadata_batch`
- Family tests: `[]`
- Cards: `["Aven Interrupter", "Deafening Silence", "Hope of Ghirapur", "Phyrexian Censor", "Void Winnower"]`

### ramp_permanent

- Support: `runtime_family_partially_supported_review_required`
- Batch strategy: `split_by_scope_before_metadata_batch`
- Family tests: `[]`
- Cards: `["Bridgeworks Battle", "Growing Rites of Itlimoc", "Selvala, Heart of the Wilds", "Chrome Mox", "Mox Diamond", "Lion's Eye Diamond", "Devoted Druid", "Faeburrow Elder"]`

### recursion

- Support: `runtime_family_partially_supported_review_required`
- Batch strategy: `split_by_scope_before_metadata_batch`
- Family tests: `["test_profound_journey_rebounds_and_returns_permanents_to_battlefield", "test_pg202_redress_fate_returns_all_artifact_enchantment_cards"]`
- Cards: `["Endurance", "Moonshadow", "Bond of Insight", "Experimental Overload", "Gandalf's Sanction", "Pulsemage Advocate"]`

### targeted_interaction

- Support: `runtime_family_partially_supported_review_required`
- Batch strategy: `split_by_scope_before_metadata_batch`
- Family tests: `[]`
- Cards: `["Decaying Time Loop", "Drown in Dreams"]`

### targeted_protection

- Support: `runtime_supported_family`
- Batch strategy: `metadata_batch_after_pg_precheck`
- Family tests: `["test_pg204_gods_willing_grants_protection_to_best_creature_until_cleanup"]`
- Cards: `["Sylvan Safekeeper", "Volatile Stormdrake", "Clout of the Dominus", "Hellkite Courser", "Protective Bubble", "Zephid's Embrace"]`

### token_maker

- Support: `runtime_family_required`
- Batch strategy: `implement_family_before_metadata_batch`
- Family tests: `[]`
- Cards: `["Hazel's Brewmaster"]`

### topdeck_play

- Support: `runtime_supported_family`
- Batch strategy: `metadata_batch_after_pg_precheck`
- Family tests: `["test_verge_rangers_plays_top_library_land_when_opponent_has_more_lands"]`
- Cards: `["Bolas's Citadel"]`

### tutor

- Support: `runtime_family_partially_supported_review_required`
- Batch strategy: `split_by_scope_before_metadata_batch`
- Family tests: `[]`
- Cards: `["Beseech the Mirror", "Intuition", "Invasion of Ikoria", "Praetor's Grasp", "Tezzeret the Seeker", "Demonic Counsel", "Entomb", "Gifts Ungiven"]`

### untap_land_engine

- Support: `runtime_family_partially_supported_review_required`
- Batch strategy: `split_by_scope_before_metadata_batch`
- Family tests: `[]`
- Cards: `["Cloud of Faeries", "Nature's Chosen"]`
