# XMage Semantic Family Classification

Generated at: `2026-06-24T00:51:08+00:00`

Read-only artifact. `mutations_performed=[]`.

- Summary: `{"batch_metadata_candidate_count": 0, "card_count": 290, "family_count": 3, "family_counts": {"manual_model": 251, "targeted_interaction": 14, "token_maker": 25}, "manual_or_blocked_count": 265, "promotion_lane_counts": {"blocked_missing_xmage_source": 4, "mapper_metadata_or_test_scenario_required": 247, "runtime_family_implementation_required": 25, "split_family_scope_review_required": 14}, "runtime_family_required_count": 25}`

| Family | Cards | Support | Lane counts | Implementation unit |
| --- | ---: | --- | --- | --- |
| `manual_model` | 251 | `manual_model_required` | `{"blocked_missing_xmage_source": 4, "mapper_metadata_or_test_scenario_required": 247}` | manual Oracle/reference review |
| `targeted_interaction` | 14 | `runtime_family_partially_supported_review_required` | `{"split_family_scope_review_required": 14}` | target legality, resolution, zone transition, and event provenance |
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
- Cards: `["Agatha's Soul Cauldron", "Into the Flood Maw", "Necropotence", "Archdruid's Charm", "Sink into Stupor", "Snap", "Walking Ballista", "Everflowing Chalice"]`

### token_maker

- Support: `runtime_family_required`
- Batch strategy: `implement_family_before_metadata_batch`
- Family tests: `[]`
- Cards: `["Insidious Roots", "Eldrazi Confluence", "Electroduplicate", "Jaxis, the Troublemaker", "Knuckles the Echidna", "Rionya, Fire Dancer", "Springheart Nantuko", "Lotho, Corrupt Shirriff"]`
