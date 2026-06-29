# XMage Semantic Family Classification

Generated at: `2026-06-29T17:02:19+00:00`

Read-only artifact. `mutations_performed=[]`.

- Summary: `{"batch_metadata_candidate_count": 8, "card_count": 148, "family_count": 15, "family_counts": {"board_wipe_choice": 3, "copy_spell_engine": 1, "draw_engine": 4, "free_cast": 9, "life_total_change": 1, "manual_model": 63, "passive": 5, "ramp_engine": 1, "ramp_permanent": 15, "ramp_ritual": 2, "recursion": 11, "targeted_interaction": 12, "targeted_protection": 8, "topdeck_play": 3, "tutor": 10}, "manual_or_blocked_count": 140, "promotion_lane_counts": {"batch_metadata_candidate_requires_pg_precheck": 8, "mapper_metadata_or_test_scenario_required": 63, "split_family_scope_review_required": 77}, "runtime_family_required_count": 0}`

| Family | Cards | Support | Lane counts | Implementation unit |
| --- | ---: | --- | --- | --- |
| `board_wipe_choice` | 3 | `runtime_family_required` | `{"split_family_scope_review_required": 3}` | multi-player choice/wipe/sacrifice resolution |
| `copy_spell_engine` | 1 | `runtime_family_partially_supported_review_required` | `{"split_family_scope_review_required": 1}` | stack spell copying from ETB, instant responses, and spell-cast battlefield triggers |
| `draw_engine` | 4 | `runtime_family_partially_supported_review_required` | `{"split_family_scope_review_required": 4}` | static and activated draw-engine bookkeeping with delayed card movement |
| `free_cast` | 9 | `runtime_family_partially_supported_review_required` | `{"split_family_scope_review_required": 9}` | cast-without-paying resolvers with source-zone, timing-bypass, and replacement-destination bookkeeping |
| `life_total_change` | 1 | `runtime_family_partially_supported_review_required` | `{"split_family_scope_review_required": 1}` | life total gain, doubling, and set-to-derived-value effects |
| `manual_model` | 63 | `manual_model_required` | `{"mapper_metadata_or_test_scenario_required": 63}` | manual Oracle/reference review |
| `passive` | 5 | `runtime_family_partially_supported_review_required` | `{"split_family_scope_review_required": 5}` | static battlefield annotation and passive support execution |
| `ramp_engine` | 1 | `runtime_family_partially_supported_review_required` | `{"batch_metadata_candidate_requires_pg_precheck": 1}` | triggered battlefield resource engines and resource-event bookkeeping |
| `ramp_permanent` | 15 | `runtime_family_partially_supported_review_required` | `{"batch_metadata_candidate_requires_pg_precheck": 7, "split_family_scope_review_required": 8}` | battlefield mana artifacts and triggered resource permanents |
| `ramp_ritual` | 2 | `runtime_supported_by_local_artifact` | `{"split_family_scope_review_required": 2}` | one-shot and activated ritual mana bursts already modeled by the battle runtime |
| `recursion` | 11 | `runtime_family_partially_supported_review_required` | `{"split_family_scope_review_required": 11}` | graveyard target selection, zone movement to hand or battlefield, and replacement-cost annotations |
| `targeted_interaction` | 12 | `runtime_family_partially_supported_review_required` | `{"split_family_scope_review_required": 12}` | target legality, resolution, zone transition, and event provenance |
| `targeted_protection` | 8 | `runtime_supported_family` | `{"split_family_scope_review_required": 8}` | targeted own-creature protection grant and cleanup-aware target legality |
| `topdeck_play` | 3 | `runtime_supported_family` | `{"split_family_scope_review_required": 3}` | top-of-library visibility and permission to play cards from library under board-state conditions |
| `tutor` | 10 | `runtime_family_partially_supported_review_required` | `{"split_family_scope_review_required": 10}` | library search, constrained target selection, and zone movement to hand, top, graveyard, or battlefield |

## Work Units

### board_wipe_choice

- Support: `runtime_family_required`
- Batch strategy: `implement_family_before_metadata_batch`
- Family tests: `[]`
- Cards: `["Dauntless Dismantler", "Karn's Sylex", "Culling Ritual"]`

### copy_spell_engine

- Support: `runtime_family_partially_supported_review_required`
- Batch strategy: `split_by_scope_before_metadata_batch`
- Family tests: `[]`
- Cards: `["Jin-Gitaxias, Progress Tyrant"]`

### draw_engine

- Support: `runtime_family_partially_supported_review_required`
- Batch strategy: `split_by_scope_before_metadata_batch`
- Family tests: `[]`
- Cards: `["Tymna the Weaver", "Alhammarret's Archive", "Currency Converter", "Naktamun Lorespinner // Wheel of Fortune"]`

### free_cast

- Support: `runtime_family_partially_supported_review_required`
- Batch strategy: `split_by_scope_before_metadata_batch`
- Family tests: `["test_pg102_creative_technique_demonstrates_top_nonland_free_casts", "test_pg191_invoke_calamity_casts_two_hand_or_graveyard_spells_and_exiles_them", "test_pg191_invoke_calamity_respects_total_mana_value_six_and_two_spell_limit"]`
- Cards: `["Arcane Bombardment", "Aminatou's Augury", "Assemble the Players", "Chaos Wand", "Epic Experiment", "Etali, Primal Conqueror", "Summons of Saruman", "Squee, the Immortal"]`

### life_total_change

- Support: `runtime_family_partially_supported_review_required`
- Batch strategy: `split_by_scope_before_metadata_batch`
- Family tests: `["test_life_total_change_runtime"]`
- Cards: `["Archivist of Oghma"]`

### manual_model

- Support: `manual_model_required`
- Batch strategy: `not_batch_safe`
- Family tests: `[]`
- Cards: `["Lim-Dul's Vault", "All Is Dust", "Amphibian Downpour", "Ancient Gold Dragon", "Blood Moon", "Chandra's Ignition", "Commandeer", "Gisela, Blade of Goldnight"]`

### passive

- Support: `runtime_family_partially_supported_review_required`
- Batch strategy: `split_by_scope_before_metadata_batch`
- Family tests: `[]`
- Cards: `["Aven Interrupter", "Valley Floodcaller", "Hope of Ghirapur", "Tidal Barracuda", "Void Winnower"]`

### ramp_engine

- Support: `runtime_family_partially_supported_review_required`
- Batch strategy: `split_by_scope_before_metadata_batch`
- Family tests: `[]`
- Cards: `["Birgi, God of Storytelling"]`

### ramp_permanent

- Support: `runtime_family_partially_supported_review_required`
- Batch strategy: `split_by_scope_before_metadata_batch`
- Family tests: `[]`
- Cards: `["Bridgeworks Battle", "Growing Rites of Itlimoc", "Neheb, the Eternal", "Blazing Firesinger", "Hydroelectric Specimen", "Ashling, Flame Dancer", "Electro, Assaulting Battery", "Selvala, Heart of the Wilds"]`

### ramp_ritual

- Support: `runtime_supported_by_local_artifact`
- Batch strategy: `metadata_batch_after_pg_precheck`
- Family tests: `[]`
- Cards: `["Mana Geyser", "Burnt Offering"]`

### recursion

- Support: `runtime_family_partially_supported_review_required`
- Batch strategy: `split_by_scope_before_metadata_batch`
- Family tests: `["test_profound_journey_rebounds_and_returns_permanents_to_battlefield", "test_pg202_redress_fate_returns_all_artifact_enchantment_cards"]`
- Cards: `["Flashback", "Worldfire", "Perpetual Timepiece", "Endurance", "Moonshadow", "Bond of Insight", "Charmbreaker Devils", "Codex Shredder"]`

### targeted_interaction

- Support: `runtime_family_partially_supported_review_required`
- Batch strategy: `split_by_scope_before_metadata_batch`
- Family tests: `[]`
- Cards: `["Tezzeret the Seeker", "Wheel of Fate", "Abrade", "Misdirection", "Pyrokinesis", "Tyvar, Jubilant Brawler", "Fury", "Nature's Chosen"]`

### targeted_protection

- Support: `runtime_supported_family`
- Batch strategy: `metadata_batch_after_pg_precheck`
- Family tests: `["test_pg204_gods_willing_grants_protection_to_best_creature_until_cleanup"]`
- Cards: `["Volatile Stormdrake", "Clout of the Dominus", "Eight-and-a-Half-Tails", "Hellkite Courser", "Protective Bubble", "Zephid's Embrace", "Sylvan Safekeeper", "Akroma's Will"]`

### topdeck_play

- Support: `runtime_supported_family`
- Batch strategy: `metadata_batch_after_pg_precheck`
- Family tests: `["test_verge_rangers_plays_top_library_land_when_opponent_has_more_lands"]`
- Cards: `["Bolas's Citadel", "Lens of Clarity", "Mystic Forge"]`

### tutor

- Support: `runtime_family_partially_supported_review_required`
- Batch strategy: `split_by_scope_before_metadata_batch`
- Family tests: `[]`
- Cards: `["Beseech the Mirror", "Intuition", "Invasion of Ikoria", "Praetor's Grasp", "Entomb", "Gifts Ungiven", "Transmute Artifact", "Opposition Agent"]`
