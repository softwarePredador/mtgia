# XMage Semantic Family Classification

Generated at: `2026-06-24T22:17:28+00:00`

Read-only artifact. `mutations_performed=[]`.

- Summary: `{"batch_metadata_candidate_count": 0, "card_count": 361, "family_count": 8, "family_counts": {"board_wipe_choice": 4, "creature": 4, "manual_model": 263, "mill_spell": 1, "static_cost_reducer": 2, "targeted_interaction": 64, "token_maker": 19, "tutor": 4}, "manual_or_blocked_count": 339, "promotion_lane_counts": {"blocked_missing_xmage_source": 4, "mapper_metadata_or_test_scenario_required": 260, "runtime_family_implementation_required": 22, "split_family_scope_review_required": 75}, "runtime_family_required_count": 22}`

| Family | Cards | Support | Lane counts | Implementation unit |
| --- | ---: | --- | --- | --- |
| `board_wipe_choice` | 4 | `runtime_family_required` | `{"runtime_family_implementation_required": 4}` | multi-player choice/wipe/sacrifice resolution |
| `creature` | 4 | `runtime_family_partially_supported_review_required` | `{"split_family_scope_review_required": 4}` | creature permanents with exact-scope ETB, death, combat, and activated behavior |
| `manual_model` | 263 | `manual_model_required` | `{"blocked_missing_xmage_source": 4, "mapper_metadata_or_test_scenario_required": 259}` | manual Oracle/reference review |
| `mill_spell` | 1 | `runtime_family_partially_supported_review_required` | `{"split_family_scope_review_required": 1}` | target-player library milling, storm copy counting, and activated mill engines |
| `static_cost_reducer` | 2 | `runtime_supported_family` | `{"split_family_scope_review_required": 2}` | battle cost-locking / affordability / payment reducer |
| `targeted_interaction` | 64 | `runtime_family_partially_supported_review_required` | `{"split_family_scope_review_required": 64}` | target legality, resolution, zone transition, and event provenance |
| `token_maker` | 19 | `runtime_family_required` | `{"mapper_metadata_or_test_scenario_required": 1, "runtime_family_implementation_required": 18}` | token creation with stats, abilities, duration, and zone cleanup |
| `tutor` | 4 | `runtime_family_partially_supported_review_required` | `{"split_family_scope_review_required": 4}` | library search, constrained target selection, and zone movement to hand, top, graveyard, or battlefield |

## Work Units

### board_wipe_choice

- Support: `runtime_family_required`
- Batch strategy: `implement_family_before_metadata_batch`
- Family tests: `[]`
- Cards: `["Ultima", "Armageddon", "Ashling, Flame Dancer", "Soul Immolation"]`

### creature

- Support: `runtime_family_partially_supported_review_required`
- Batch strategy: `split_by_scope_before_metadata_batch`
- Family tests: `[]`
- Cards: `["Razaketh, the Foulblooded", "Rune-Scarred Demon", "Blood Artist", "Starfield Shepherd"]`

### manual_model

- Support: `manual_model_required`
- Batch strategy: `not_batch_safe`
- Family tests: `[]`
- Cards: `["Apex of Power", "Dance with Calamity", "Galvanoth", "Longshot, Rebel Bowman", "Penance", "Volcanic Vision", "Deflecting Palm", "Dragon's Rage Channeler"]`

### mill_spell

- Support: `runtime_family_partially_supported_review_required`
- Batch strategy: `split_by_scope_before_metadata_batch`
- Family tests: `["test_brain_freeze_mills_library_instead_of_dealing_life_damage"]`
- Cards: `["Grinding Station"]`

### static_cost_reducer

- Support: `runtime_supported_family`
- Batch strategy: `metadata_batch_after_pg_precheck`
- Family tests: `["test_pearl_medallion_reduces_white_spell_generic_cost_without_mana_source", "test_scarlet_witch_reduces_mv4_instant_or_sorcery_by_source_power", "test_scarlet_witch_does_not_reduce_mv3_or_non_instant_sorcery_spell"]`
- Cards: `["Explosive Singularity", "Vanquish the Horde"]`

### targeted_interaction

- Support: `runtime_family_partially_supported_review_required`
- Batch strategy: `split_by_scope_before_metadata_batch`
- Family tests: `[]`
- Cards: `["Vandalblast", "Reprieve", "Bloodchief Ascension", "Glint-Horn Buccaneer", "Tezzeret, Cruel Captain", "Trouble in Pairs", "Abrade", "Arcane Denial"]`

### token_maker

- Support: `runtime_family_required`
- Batch strategy: `implement_family_before_metadata_batch`
- Family tests: `[]`
- Cards: `["Young Pyromancer", "Bone Miser", "Maskwood Nexus", "Monastery Mentor", "Spiked Corridor // Torture Pit", "The Locust God", "Utvara Hellkite", "Waste Not"]`

### tutor

- Support: `runtime_family_partially_supported_review_required`
- Batch strategy: `split_by_scope_before_metadata_batch`
- Family tests: `[]`
- Cards: `["Reckless Handling", "Demonic Counsel", "Grim Tutor", "Summoner's Pact"]`
