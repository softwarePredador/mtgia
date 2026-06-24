# XMage Semantic Family Classification

Generated at: `2026-06-24T21:25:11+00:00`

Read-only artifact. `mutations_performed=[]`.

- Summary: `{"batch_metadata_candidate_count": 0, "card_count": 365, "family_count": 8, "family_counts": {"board_wipe_choice": 4, "creature": 4, "manual_model": 264, "mill_spell": 1, "static_cost_reducer": 2, "targeted_interaction": 65, "token_maker": 21, "tutor": 4}, "manual_or_blocked_count": 341, "promotion_lane_counts": {"blocked_missing_xmage_source": 4, "mapper_metadata_or_test_scenario_required": 261, "runtime_family_implementation_required": 24, "split_family_scope_review_required": 76}, "runtime_family_required_count": 24}`

| Family | Cards | Support | Lane counts | Implementation unit |
| --- | ---: | --- | --- | --- |
| `board_wipe_choice` | 4 | `runtime_family_required` | `{"runtime_family_implementation_required": 4}` | multi-player choice/wipe/sacrifice resolution |
| `creature` | 4 | `runtime_family_partially_supported_review_required` | `{"split_family_scope_review_required": 4}` | creature permanents with exact-scope ETB, death, combat, and activated behavior |
| `manual_model` | 264 | `manual_model_required` | `{"blocked_missing_xmage_source": 4, "mapper_metadata_or_test_scenario_required": 260}` | manual Oracle/reference review |
| `mill_spell` | 1 | `runtime_family_partially_supported_review_required` | `{"split_family_scope_review_required": 1}` | target-player library milling, storm copy counting, and activated mill engines |
| `static_cost_reducer` | 2 | `runtime_supported_family` | `{"split_family_scope_review_required": 2}` | battle cost-locking / affordability / payment reducer |
| `targeted_interaction` | 65 | `runtime_family_partially_supported_review_required` | `{"split_family_scope_review_required": 65}` | target legality, resolution, zone transition, and event provenance |
| `token_maker` | 21 | `runtime_family_required` | `{"mapper_metadata_or_test_scenario_required": 1, "runtime_family_implementation_required": 20}` | token creation with stats, abilities, duration, and zone cleanup |
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
- Cards: `["Apex of Power", "Dance with Calamity", "Galvanoth", "Invoke Calamity", "Longshot, Rebel Bowman", "Penance", "Volcanic Vision", "Deflecting Palm"]`

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
- Cards: `["Vandalblast", "Reprieve", "Bloodchief Ascension", "Cool but Rude", "Glint-Horn Buccaneer", "Tezzeret, Cruel Captain", "Trouble in Pairs", "Abrade"]`

### token_maker

- Support: `runtime_family_required`
- Batch strategy: `implement_family_before_metadata_batch`
- Family tests: `[]`
- Cards: `["Perch Protection", "Young Pyromancer", "Bone Miser", "Maskwood Nexus", "Monastery Mentor", "Spiked Corridor // Torture Pit", "The Locust God", "Utvara Hellkite"]`

### tutor

- Support: `runtime_family_partially_supported_review_required`
- Batch strategy: `split_by_scope_before_metadata_batch`
- Family tests: `[]`
- Cards: `["Reckless Handling", "Demonic Counsel", "Grim Tutor", "Summoner's Pact"]`
