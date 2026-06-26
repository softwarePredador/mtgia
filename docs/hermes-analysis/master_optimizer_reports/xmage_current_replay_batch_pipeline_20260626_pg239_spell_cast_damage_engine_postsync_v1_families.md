# XMage Semantic Family Classification

Generated at: `2026-06-26T10:21:04+00:00`

Read-only artifact. `mutations_performed=[]`.

- Summary: `{"batch_metadata_candidate_count": 0, "card_count": 386, "family_count": 10, "family_counts": {"board_wipe_choice": 1, "controlled_creature_etb_damage_engine": 1, "creature": 3, "manual_model": 321, "mill_spell": 1, "modal_spell": 1, "recursion": 2, "targeted_interaction": 48, "token_maker": 4, "tutor": 4}, "manual_or_blocked_count": 382, "promotion_lane_counts": {"blocked_missing_xmage_source": 4, "mapper_metadata_or_test_scenario_required": 318, "runtime_family_implementation_required": 4, "split_family_scope_review_required": 60}, "runtime_family_required_count": 4}`

| Family | Cards | Support | Lane counts | Implementation unit |
| --- | ---: | --- | --- | --- |
| `board_wipe_choice` | 1 | `runtime_family_required` | `{"runtime_family_implementation_required": 1}` | multi-player choice/wipe/sacrifice resolution |
| `controlled_creature_etb_damage_engine` | 1 | `runtime_supported_family` | `{"split_family_scope_review_required": 1}` | battlefield trigger when a creature controlled by the source controller enters and damages each live opponent |
| `creature` | 3 | `runtime_family_partially_supported_review_required` | `{"split_family_scope_review_required": 3}` | creature permanents with exact-scope ETB, death, combat, and activated behavior |
| `manual_model` | 321 | `manual_model_required` | `{"blocked_missing_xmage_source": 4, "mapper_metadata_or_test_scenario_required": 317}` | manual Oracle/reference review |
| `mill_spell` | 1 | `runtime_family_partially_supported_review_required` | `{"split_family_scope_review_required": 1}` | target-player library milling, storm copy counting, and activated mill engines |
| `modal_spell` | 1 | `runtime_family_partially_supported_review_required` | `{"split_family_scope_review_required": 1}` | exact-scope modal resolution with repeated mode selection when the card allows it |
| `recursion` | 2 | `runtime_family_partially_supported_review_required` | `{"split_family_scope_review_required": 2}` | graveyard target selection, zone movement to hand or battlefield, and replacement-cost annotations |
| `targeted_interaction` | 48 | `runtime_family_partially_supported_review_required` | `{"split_family_scope_review_required": 48}` | target legality, resolution, zone transition, and event provenance |
| `token_maker` | 4 | `runtime_family_required` | `{"mapper_metadata_or_test_scenario_required": 1, "runtime_family_implementation_required": 3}` | token creation with stats, abilities, duration, and zone cleanup |
| `tutor` | 4 | `runtime_family_partially_supported_review_required` | `{"split_family_scope_review_required": 4}` | library search, constrained target selection, and zone movement to hand, top, graveyard, or battlefield |

## Work Units

### board_wipe_choice

- Support: `runtime_family_required`
- Batch strategy: `implement_family_before_metadata_batch`
- Family tests: `[]`
- Cards: `["Ashling, Flame Dancer"]`

### controlled_creature_etb_damage_engine

- Support: `runtime_supported_family`
- Batch strategy: `metadata_batch_after_pg_precheck`
- Family tests: `["test_pg207_another_creature_enter_damage_each_opponent_excludes_source_entering", "test_pg207_impact_tremors_damages_each_opponent_when_token_enters"]`
- Cards: `["Purphoros, God of the Forge"]`

### creature

- Support: `runtime_family_partially_supported_review_required`
- Batch strategy: `split_by_scope_before_metadata_batch`
- Family tests: `[]`
- Cards: `["Razaketh, the Foulblooded", "Rune-Scarred Demon", "Blood Artist"]`

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

### targeted_interaction

- Support: `runtime_family_partially_supported_review_required`
- Batch strategy: `split_by_scope_before_metadata_batch`
- Family tests: `[]`
- Cards: `["Flusterstorm", "Chain of Vapor", "Reprieve", "Bloodchief Ascension", "Tezzeret, Cruel Captain", "Abrade", "Arcane Denial", "Archivist of Oghma"]`

### token_maker

- Support: `runtime_family_required`
- Batch strategy: `implement_family_before_metadata_batch`
- Family tests: `[]`
- Cards: `["Maskwood Nexus", "Spiked Corridor // Torture Pit", "Hazel's Brewmaster", "Adagia, Windswept Bastion"]`

### tutor

- Support: `runtime_family_partially_supported_review_required`
- Batch strategy: `split_by_scope_before_metadata_batch`
- Family tests: `[]`
- Cards: `["Reckless Handling", "Demonic Counsel", "Grim Tutor", "Summoner's Pact"]`
