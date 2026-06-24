# XMage Semantic Family Classification

Generated at: `2026-06-24T15:19:10+00:00`

Read-only artifact. `mutations_performed=[]`.

- Summary: `{"batch_metadata_candidate_count": 54, "card_count": 504, "family_count": 17, "family_counts": {"board_wipe_choice": 4, "copy_permanent_etb": 9, "copy_spell_engine": 2, "creature": 8, "draw_engine": 3, "land": 4, "land_ramp": 1, "manual_model": 357, "passive": 4, "ramp_permanent": 7, "ramp_ritual": 1, "static_cost_reducer": 3, "targeted_interaction": 70, "token_maker": 21, "treasure_maker": 1, "tutor": 5, "untap_land_engine": 4}, "manual_or_blocked_count": 426, "promotion_lane_counts": {"batch_metadata_candidate_requires_pg_precheck": 54, "blocked_missing_xmage_source": 2, "mapper_metadata_or_test_scenario_required": 356, "runtime_family_implementation_required": 24, "split_family_scope_review_required": 68}, "runtime_family_required_count": 24}`

| Family | Cards | Support | Lane counts | Implementation unit |
| --- | ---: | --- | --- | --- |
| `board_wipe_choice` | 4 | `runtime_family_required` | `{"runtime_family_implementation_required": 4}` | multi-player choice/wipe/sacrifice resolution |
| `copy_permanent_etb` | 9 | `runtime_family_partially_supported_review_required` | `{"batch_metadata_candidate_requires_pg_precheck": 9}` | permanent enters-the-battlefield copy replacement with optional extra card types |
| `copy_spell_engine` | 2 | `runtime_family_partially_supported_review_required` | `{"batch_metadata_candidate_requires_pg_precheck": 2}` | stack spell copying from ETB, instant responses, and spell-cast battlefield triggers |
| `creature` | 8 | `runtime_family_partially_supported_review_required` | `{"batch_metadata_candidate_requires_pg_precheck": 8}` | creature permanents with exact-scope ETB, death, combat, and activated behavior |
| `draw_engine` | 3 | `runtime_family_partially_supported_review_required` | `{"batch_metadata_candidate_requires_pg_precheck": 3}` | static and activated draw-engine bookkeeping with delayed card movement |
| `land` | 4 | `runtime_supported_by_local_artifact` | `{"batch_metadata_candidate_requires_pg_precheck": 4}` | basic and simple land mana-source modeling already consumed by the battle runtime |
| `land_ramp` | 1 | `runtime_supported_by_local_artifact` | `{"batch_metadata_candidate_requires_pg_precheck": 1}` | search-based land tutoring and battlefield land entry with landfall-aware zone movement |
| `manual_model` | 357 | `manual_model_required` | `{"blocked_missing_xmage_source": 2, "mapper_metadata_or_test_scenario_required": 355}` | manual Oracle/reference review |
| `passive` | 4 | `runtime_family_partially_supported_review_required` | `{"batch_metadata_candidate_requires_pg_precheck": 4}` | static battlefield annotation and passive support execution |
| `ramp_permanent` | 7 | `runtime_family_partially_supported_review_required` | `{"batch_metadata_candidate_requires_pg_precheck": 7}` | battlefield mana artifacts and triggered resource permanents |
| `ramp_ritual` | 1 | `runtime_supported_by_local_artifact` | `{"batch_metadata_candidate_requires_pg_precheck": 1}` | one-shot and activated ritual mana bursts already modeled by the battle runtime |
| `static_cost_reducer` | 3 | `runtime_supported_family` | `{"batch_metadata_candidate_requires_pg_precheck": 1, "split_family_scope_review_required": 2}` | battle cost-locking / affordability / payment reducer |
| `targeted_interaction` | 70 | `runtime_family_partially_supported_review_required` | `{"batch_metadata_candidate_requires_pg_precheck": 4, "split_family_scope_review_required": 66}` | target legality, resolution, zone transition, and event provenance |
| `token_maker` | 21 | `runtime_family_required` | `{"mapper_metadata_or_test_scenario_required": 1, "runtime_family_implementation_required": 20}` | token creation with stats, abilities, duration, and zone cleanup |
| `treasure_maker` | 1 | `runtime_family_partially_supported_review_required` | `{"batch_metadata_candidate_requires_pg_precheck": 1}` | treasure creation and discard-draw riders |
| `tutor` | 5 | `runtime_family_partially_supported_review_required` | `{"batch_metadata_candidate_requires_pg_precheck": 5}` | library search, constrained target selection, and zone movement to hand, top, graveyard, or battlefield |
| `untap_land_engine` | 4 | `runtime_family_partially_supported_review_required` | `{"batch_metadata_candidate_requires_pg_precheck": 4}` | activated land-untap engines that convert board resources into contextual extra mana |

## Work Units

### board_wipe_choice

- Support: `runtime_family_required`
- Batch strategy: `implement_family_before_metadata_batch`
- Family tests: `[]`
- Cards: `["Ultima", "Armageddon", "Ashling, Flame Dancer", "Soul Immolation"]`

### copy_permanent_etb

- Support: `runtime_family_partially_supported_review_required`
- Batch strategy: `split_by_scope_before_metadata_batch`
- Family tests: `["test_phyrexian_metamorph_enters_as_copy_of_best_creature_and_keeps_artifact_type", "test_copy_enchantment_without_target_enters_as_self"]`
- Cards: `["Copy Enchantment", "Mirrormade", "Imposter Mech", "Mockingbird", "Phyrexian Metamorph", "Clever Impersonator", "Copy Artifact", "Flesh Duplicate"]`

### copy_spell_engine

- Support: `runtime_family_partially_supported_review_required`
- Batch strategy: `split_by_scope_before_metadata_batch`
- Family tests: `[]`
- Cards: `["Double Vision", "Swarm Intelligence"]`

### creature

- Support: `runtime_family_partially_supported_review_required`
- Batch strategy: `split_by_scope_before_metadata_batch`
- Family tests: `[]`
- Cards: `["Fate Unraveler", "Enduring Vitality", "Bloom Tender", "Elves of Deep Shadow", "Circle of Dreams Druid", "Ignoble Hierarch", "Elvish Reclaimer", "Noble Hierarch"]`

### draw_engine

- Support: `runtime_family_partially_supported_review_required`
- Batch strategy: `split_by_scope_before_metadata_batch`
- Family tests: `[]`
- Cards: `["Mystic Remora", "Rhystic Study", "Geth's Grimoire"]`

### land

- Support: `runtime_supported_by_local_artifact`
- Batch strategy: `metadata_batch_after_pg_precheck`
- Family tests: `[]`
- Cards: `["Exotic Orchard", "Tarnished Citadel", "Mountain", "Plains"]`

### land_ramp

- Support: `runtime_supported_by_local_artifact`
- Batch strategy: `metadata_batch_after_pg_precheck`
- Family tests: `[]`
- Cards: `["Crop Rotation"]`

### manual_model

- Support: `manual_model_required`
- Batch strategy: `not_batch_safe`
- Family tests: `[]`
- Cards: `["Apex of Power", "Flusterstorm", "Formidable Speaker", "Volcanic Vision", "Brain Freeze", "Cabal Ritual", "Chain of Vapor", "Dance with Calamity"]`

### passive

- Support: `runtime_family_partially_supported_review_required`
- Batch strategy: `split_by_scope_before_metadata_batch`
- Family tests: `[]`
- Cards: `["Underworld Dreams", "Cryptolith Rite", "Feast of Sanity", "Megrim"]`

### ramp_permanent

- Support: `runtime_family_partially_supported_review_required`
- Batch strategy: `split_by_scope_before_metadata_batch`
- Family tests: `[]`
- Cards: `["Basalt Monolith", "Grim Monolith", "Springleaf Drum", "Talisman of Curiosity", "Relic of Legends", "Talisman of Indulgence", "Moonsnare Prototype"]`

### ramp_ritual

- Support: `runtime_supported_by_local_artifact`
- Batch strategy: `metadata_batch_after_pg_precheck`
- Family tests: `[]`
- Cards: `["Elvish Spirit Guide"]`

### static_cost_reducer

- Support: `runtime_supported_family`
- Batch strategy: `metadata_batch_after_pg_precheck`
- Family tests: `["test_pearl_medallion_reduces_white_spell_generic_cost_without_mana_source", "test_scarlet_witch_reduces_mv4_instant_or_sorcery_by_source_power", "test_scarlet_witch_does_not_reduce_mv3_or_non_instant_sorcery_spell"]`
- Cards: `["Explosive Singularity", "Vanquish the Horde", "Locket of Yesterdays"]`

### targeted_interaction

- Support: `runtime_family_partially_supported_review_required`
- Batch strategy: `split_by_scope_before_metadata_batch`
- Family tests: `[]`
- Cards: `["Vandalblast", "Reprieve", "Bloodchief Ascension", "Cool but Rude", "Glint-Horn Buccaneer", "Tezzeret, Cruel Captain", "Trouble in Pairs", "Abrade"]`

### token_maker

- Support: `runtime_family_required`
- Batch strategy: `implement_family_before_metadata_batch`
- Family tests: `[]`
- Cards: `["Perch Protection", "Young Pyromancer", "Bone Miser", "Maskwood Nexus", "Monastery Mentor", "Spiked Corridor // Torture Pit", "The Locust God", "Utvara Hellkite"]`

### treasure_maker

- Support: `runtime_family_partially_supported_review_required`
- Batch strategy: `split_by_scope_before_metadata_batch`
- Family tests: `[]`
- Cards: `["Brass's Bounty"]`

### tutor

- Support: `runtime_family_partially_supported_review_required`
- Batch strategy: `split_by_scope_before_metadata_batch`
- Family tests: `[]`
- Cards: `["Nature's Rhythm", "Chord of Calling", "Green Sun's Zenith", "Steelshaper's Gift", "Whir of Invention"]`

### untap_land_engine

- Support: `runtime_family_partially_supported_review_required`
- Batch strategy: `split_by_scope_before_metadata_batch`
- Family tests: `[]`
- Cards: `["Candelabra of Tawnos", "Earthcraft", "Magus of the Candelabra", "Oboro Breezecaller"]`
