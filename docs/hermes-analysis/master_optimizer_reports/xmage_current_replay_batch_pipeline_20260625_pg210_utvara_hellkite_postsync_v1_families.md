# XMage Semantic Family Classification

Generated at: `2026-06-25T08:13:26+00:00`

Read-only artifact. `mutations_performed=[]`.

- Summary: `{"batch_metadata_candidate_count": 0, "card_count": 428, "family_count": 11, "family_counts": {"board_wipe_choice": 3, "controlled_creature_etb_damage_engine": 2, "creature": 4, "manual_model": 336, "mill_spell": 1, "modal_spell": 1, "recursion": 2, "static_cost_reducer": 2, "targeted_interaction": 58, "token_maker": 15, "tutor": 4}, "manual_or_blocked_count": 411, "promotion_lane_counts": {"blocked_missing_xmage_source": 4, "mapper_metadata_or_test_scenario_required": 333, "runtime_family_implementation_required": 17, "split_family_scope_review_required": 74}, "runtime_family_required_count": 17}`

| Family | Cards | Support | Lane counts | Implementation unit |
| --- | ---: | --- | --- | --- |
| `board_wipe_choice` | 3 | `runtime_family_required` | `{"runtime_family_implementation_required": 3}` | multi-player choice/wipe/sacrifice resolution |
| `controlled_creature_etb_damage_engine` | 2 | `runtime_supported_family` | `{"split_family_scope_review_required": 2}` | battlefield trigger when a creature controlled by the source controller enters and damages each live opponent |
| `creature` | 4 | `runtime_family_partially_supported_review_required` | `{"split_family_scope_review_required": 4}` | creature permanents with exact-scope ETB, death, combat, and activated behavior |
| `manual_model` | 336 | `manual_model_required` | `{"blocked_missing_xmage_source": 4, "mapper_metadata_or_test_scenario_required": 332}` | manual Oracle/reference review |
| `mill_spell` | 1 | `runtime_family_partially_supported_review_required` | `{"split_family_scope_review_required": 1}` | target-player library milling, storm copy counting, and activated mill engines |
| `modal_spell` | 1 | `runtime_family_partially_supported_review_required` | `{"split_family_scope_review_required": 1}` | exact-scope modal resolution with repeated mode selection when the card allows it |
| `recursion` | 2 | `runtime_family_partially_supported_review_required` | `{"split_family_scope_review_required": 2}` | graveyard target selection, zone movement to hand or battlefield, and replacement-cost annotations |
| `static_cost_reducer` | 2 | `runtime_supported_family` | `{"split_family_scope_review_required": 2}` | battle cost-locking / affordability / payment reducer |
| `targeted_interaction` | 58 | `runtime_family_partially_supported_review_required` | `{"split_family_scope_review_required": 58}` | target legality, resolution, zone transition, and event provenance |
| `token_maker` | 15 | `runtime_family_required` | `{"mapper_metadata_or_test_scenario_required": 1, "runtime_family_implementation_required": 14}` | token creation with stats, abilities, duration, and zone cleanup |
| `tutor` | 4 | `runtime_family_partially_supported_review_required` | `{"split_family_scope_review_required": 4}` | library search, constrained target selection, and zone movement to hand, top, graveyard, or battlefield |

## Work Units

### board_wipe_choice

- Support: `runtime_family_required`
- Batch strategy: `implement_family_before_metadata_batch`
- Family tests: `[]`
- Cards: `["Ultima", "Ashling, Flame Dancer", "Soul Immolation"]`

### controlled_creature_etb_damage_engine

- Support: `runtime_supported_family`
- Batch strategy: `metadata_batch_after_pg_precheck`
- Family tests: `["test_pg207_another_creature_enter_damage_each_opponent_excludes_source_entering", "test_pg207_impact_tremors_damages_each_opponent_when_token_enters"]`
- Cards: `["Purphoros, God of the Forge", "Warleader's Call"]`

### creature

- Support: `runtime_family_partially_supported_review_required`
- Batch strategy: `split_by_scope_before_metadata_batch`
- Family tests: `[]`
- Cards: `["Razaketh, the Foulblooded", "Rune-Scarred Demon", "Blood Artist", "Starfield Shepherd"]`

### manual_model

- Support: `manual_model_required`
- Batch strategy: `not_batch_safe`
- Family tests: `[]`
- Cards: `["Lim-Dul's Vault", "Apex of Power", "Formidable Speaker", "Force of Negation", "Kinnan, Bonder Prodigy", "Tainted Pact", "Voice of Victory", "Volcanic Vision"]`

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

### recursion

- Support: `runtime_family_partially_supported_review_required`
- Batch strategy: `split_by_scope_before_metadata_batch`
- Family tests: `["test_profound_journey_rebounds_and_returns_permanents_to_battlefield", "test_pg202_redress_fate_returns_all_artifact_enchantment_cards"]`
- Cards: `["Forge Anew", "The Soul Stone"]`

### static_cost_reducer

- Support: `runtime_supported_family`
- Batch strategy: `metadata_batch_after_pg_precheck`
- Family tests: `["test_pearl_medallion_reduces_white_spell_generic_cost_without_mana_source", "test_scarlet_witch_reduces_mv4_instant_or_sorcery_by_source_power", "test_scarlet_witch_does_not_reduce_mv3_or_non_instant_sorcery_spell"]`
- Cards: `["Explosive Singularity", "Vanquish the Horde"]`

### targeted_interaction

- Support: `runtime_family_partially_supported_review_required`
- Batch strategy: `split_by_scope_before_metadata_batch`
- Family tests: `[]`
- Cards: `["Flusterstorm", "Chain of Vapor", "Vandalblast", "Reprieve", "Bloodchief Ascension", "Tezzeret, Cruel Captain", "Abrade", "Arcane Denial"]`

### token_maker

- Support: `runtime_family_required`
- Batch strategy: `implement_family_before_metadata_batch`
- Family tests: `[]`
- Cards: `["Bone Miser", "Maskwood Nexus", "Spiked Corridor // Torture Pit", "The Locust God", "Waste Not", "Black Market Connections", "Fable of the Mirror-Breaker // Reflection of Kiki-Jiki", "Smuggler's Share"]`

### tutor

- Support: `runtime_family_partially_supported_review_required`
- Batch strategy: `split_by_scope_before_metadata_batch`
- Family tests: `[]`
- Cards: `["Reckless Handling", "Demonic Counsel", "Grim Tutor", "Summoner's Pact"]`
