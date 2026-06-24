# XMage Semantic Family Classification

Generated at: `2026-06-24T00:12:39+00:00`

Read-only artifact. `mutations_performed=[]`.

- Summary: `{"batch_metadata_candidate_count": 3, "card_count": 307, "family_count": 3, "family_counts": {"manual_model": 254, "targeted_interaction": 28, "token_maker": 25}, "manual_or_blocked_count": 279, "promotion_lane_counts": {"batch_metadata_candidate_requires_pg_precheck": 3, "blocked_missing_xmage_source": 4, "mapper_metadata_or_test_scenario_required": 247, "runtime_family_implementation_required": 25, "split_family_scope_review_required": 28}, "runtime_family_required_count": 25}`

| Family | Cards | Support | Lane counts | Implementation unit |
| --- | ---: | --- | --- | --- |
| `manual_model` | 254 | `manual_model_required` | `{"batch_metadata_candidate_requires_pg_precheck": 3, "blocked_missing_xmage_source": 4, "mapper_metadata_or_test_scenario_required": 247}` | manual Oracle/reference review |
| `targeted_interaction` | 28 | `runtime_family_partially_supported_review_required` | `{"split_family_scope_review_required": 28}` | target legality, resolution, zone transition, and event provenance |
| `token_maker` | 25 | `runtime_family_required` | `{"runtime_family_implementation_required": 25}` | token creation with stats, abilities, duration, and zone cleanup |

## Work Units

### manual_model

- Support: `manual_model_required`
- Batch strategy: `not_batch_safe`
- Family tests: `[]`
- Cards: `["Lim-Dul's Vault", "Demonic Tutor", "Flusterstorm", "Formidable Speaker", "Mystic Remora", "Nature's Rhythm", "Rhystic Study", "Vampiric Tutor"]`

### targeted_interaction

- Support: `runtime_family_partially_supported_review_required`
- Batch strategy: `split_by_scope_before_metadata_batch`
- Family tests: `[]`
- Cards: `["Orcish Bowmasters", "Deathrite Shaman", "Faerie Mastermind", "Wan Shi Tong, Librarian", "Agatha's Soul Cauldron", "Borne Upon a Wind", "Into the Flood Maw", "Red Elemental Blast"]`

### token_maker

- Support: `runtime_family_required`
- Batch strategy: `implement_family_before_metadata_batch`
- Family tests: `[]`
- Cards: `["Insidious Roots", "Eldrazi Confluence", "Electroduplicate", "Jaxis, the Troublemaker", "Knuckles the Echidna", "Rionya, Fire Dancer", "Springheart Nantuko", "Lotho, Corrupt Shirriff"]`
