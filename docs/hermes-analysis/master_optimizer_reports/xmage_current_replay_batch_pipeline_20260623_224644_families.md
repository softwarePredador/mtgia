# XMage Semantic Family Classification

Generated at: `2026-06-23T22:46:44+00:00`

Read-only artifact. `mutations_performed=[]`.

- Summary: `{"batch_metadata_candidate_count": 1, "card_count": 325, "family_count": 5, "family_counts": {"manual_model": 251, "modal_mana_rock": 1, "static_cost_reducer": 3, "targeted_interaction": 45, "token_maker": 25}, "manual_or_blocked_count": 299, "promotion_lane_counts": {"batch_metadata_candidate_requires_pg_precheck": 1, "blocked_missing_xmage_source": 4, "mapper_metadata_or_test_scenario_required": 247, "runtime_family_implementation_required": 25, "split_family_scope_review_required": 48}, "runtime_family_required_count": 25}`

| Family | Cards | Support | Lane counts | Implementation unit |
| --- | ---: | --- | --- | --- |
| `manual_model` | 251 | `manual_model_required` | `{"blocked_missing_xmage_source": 4, "mapper_metadata_or_test_scenario_required": 247}` | manual Oracle/reference review |
| `modal_mana_rock` | 1 | `runtime_family_required` | `{"batch_metadata_candidate_requires_pg_precheck": 1}` | activated artifact mana plus secondary activated/non-mana mode |
| `static_cost_reducer` | 3 | `runtime_supported_family` | `{"split_family_scope_review_required": 3}` | battle cost-locking / affordability / payment reducer |
| `targeted_interaction` | 45 | `runtime_family_partially_supported_review_required` | `{"split_family_scope_review_required": 45}` | target legality, resolution, zone transition, and event provenance |
| `token_maker` | 25 | `runtime_family_required` | `{"runtime_family_implementation_required": 25}` | token creation with stats, abilities, duration, and zone cleanup |

## Work Units

### manual_model

- Support: `manual_model_required`
- Batch strategy: `not_batch_safe`
- Family tests: `[]`
- Cards: `["Lim-Dul's Vault", "Demonic Tutor", "Flusterstorm", "Formidable Speaker", "Mystic Remora", "Nature's Rhythm", "Rhystic Study", "Vampiric Tutor"]`

### modal_mana_rock

- Support: `runtime_family_required`
- Batch strategy: `implement_family_before_metadata_batch`
- Family tests: `[]`
- Cards: `["Mind Stone"]`

### static_cost_reducer

- Support: `runtime_supported_family`
- Batch strategy: `metadata_batch_after_pg_precheck`
- Family tests: `["test_pearl_medallion_reduces_white_spell_generic_cost_without_mana_source", "test_scarlet_witch_reduces_mv4_instant_or_sorcery_by_source_power", "test_scarlet_witch_does_not_reduce_mv3_or_non_instant_sorcery_spell"]`
- Cards: `["Training Grounds", "Biomancer's Familiar", "Dargo, the Shipwrecker"]`

### targeted_interaction

- Support: `runtime_family_partially_supported_review_required`
- Batch strategy: `split_by_scope_before_metadata_batch`
- Family tests: `[]`
- Cards: `["Pact of Negation", "Orcish Bowmasters", "Swan Song", "Deathrite Shaman", "Faerie Mastermind", "Wan Shi Tong, Librarian", "Agatha's Soul Cauldron", "An Offer You Can't Refuse"]`

### token_maker

- Support: `runtime_family_required`
- Batch strategy: `implement_family_before_metadata_batch`
- Family tests: `[]`
- Cards: `["Insidious Roots", "Eldrazi Confluence", "Electroduplicate", "Jaxis, the Troublemaker", "Knuckles the Echidna", "Rionya, Fire Dancer", "Springheart Nantuko", "Lotho, Corrupt Shirriff"]`
