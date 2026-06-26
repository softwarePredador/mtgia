# XMage Semantic Family Classification

Generated at: `2026-06-26T04:39:35+00:00`

Read-only artifact. `mutations_performed=[]`.

- Summary: `{"batch_metadata_candidate_count": 0, "card_count": 298, "family_count": 8, "family_counts": {"board_wipe_choice": 1, "controlled_creature_etb_damage_engine": 1, "manual_model": 270, "mill_spell": 1, "modal_spell": 1, "targeted_interaction": 19, "token_maker": 2, "tutor": 3}, "manual_or_blocked_count": 295, "promotion_lane_counts": {"blocked_missing_xmage_source": 2, "mapper_metadata_or_test_scenario_required": 268, "runtime_family_implementation_required": 3, "split_family_scope_review_required": 25}, "runtime_family_required_count": 3}`

| Family | Cards | Support | Lane counts | Implementation unit |
| --- | ---: | --- | --- | --- |
| `board_wipe_choice` | 1 | `runtime_family_required` | `{"runtime_family_implementation_required": 1}` | multi-player choice/wipe/sacrifice resolution |
| `controlled_creature_etb_damage_engine` | 1 | `runtime_supported_family` | `{"split_family_scope_review_required": 1}` | battlefield trigger when a creature controlled by the source controller enters and damages each live opponent |
| `manual_model` | 270 | `manual_model_required` | `{"blocked_missing_xmage_source": 2, "mapper_metadata_or_test_scenario_required": 268}` | manual Oracle/reference review |
| `mill_spell` | 1 | `runtime_family_partially_supported_review_required` | `{"split_family_scope_review_required": 1}` | target-player library milling, storm copy counting, and activated mill engines |
| `modal_spell` | 1 | `runtime_family_partially_supported_review_required` | `{"split_family_scope_review_required": 1}` | exact-scope modal resolution with repeated mode selection when the card allows it |
| `targeted_interaction` | 19 | `runtime_family_partially_supported_review_required` | `{"split_family_scope_review_required": 19}` | target legality, resolution, zone transition, and event provenance |
| `token_maker` | 2 | `runtime_family_required` | `{"runtime_family_implementation_required": 2}` | token creation with stats, abilities, duration, and zone cleanup |
| `tutor` | 3 | `runtime_family_partially_supported_review_required` | `{"split_family_scope_review_required": 3}` | library search, constrained target selection, and zone movement to hand, top, graveyard, or battlefield |

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

### manual_model

- Support: `manual_model_required`
- Batch strategy: `not_batch_safe`
- Family tests: `[]`
- Cards: `["Lim-Dul's Vault", "Apex of Power", "Formidable Speaker", "Force of Negation", "Kinnan, Bonder Prodigy", "Tainted Pact", "Volcanic Vision", "Dance with Calamity"]`

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

### targeted_interaction

- Support: `runtime_family_partially_supported_review_required`
- Batch strategy: `split_by_scope_before_metadata_batch`
- Family tests: `[]`
- Cards: `["Flusterstorm", "Chain of Vapor", "Reprieve", "Tezzeret, Cruel Captain", "Abrade", "Archivist of Oghma", "Firesong and Sunspeaker", "Palant\u00edr of Orthanc"]`

### token_maker

- Support: `runtime_family_required`
- Batch strategy: `implement_family_before_metadata_batch`
- Family tests: `[]`
- Cards: `["Hazel's Brewmaster", "Adagia, Windswept Bastion"]`

### tutor

- Support: `runtime_family_partially_supported_review_required`
- Batch strategy: `split_by_scope_before_metadata_batch`
- Family tests: `[]`
- Cards: `["Reckless Handling", "Demonic Counsel", "Summoner's Pact"]`
