# XMage Semantic Family Classification

Generated at: `2026-06-24T02:29:54+00:00`

Read-only artifact. `mutations_performed=[]`.

- Summary: `{"batch_metadata_candidate_count": 3, "card_count": 262, "family_count": 4, "family_counts": {"copy_creature_token": 2, "manual_model": 240, "token_maker": 18, "treasure_maker": 2}, "manual_or_blocked_count": 241, "promotion_lane_counts": {"batch_metadata_candidate_requires_pg_precheck": 3, "blocked_missing_xmage_source": 3, "mapper_metadata_or_test_scenario_required": 237, "runtime_family_implementation_required": 18, "split_family_scope_review_required": 1}, "runtime_family_required_count": 18}`

| Family | Cards | Support | Lane counts | Implementation unit |
| --- | ---: | --- | --- | --- |
| `copy_creature_token` | 2 | `runtime_family_partially_supported_review_required` | `{"batch_metadata_candidate_requires_pg_precheck": 1, "split_family_scope_review_required": 1}` | copy-target token creation with haste and end-step cleanup |
| `manual_model` | 240 | `manual_model_required` | `{"blocked_missing_xmage_source": 3, "mapper_metadata_or_test_scenario_required": 237}` | manual Oracle/reference review |
| `token_maker` | 18 | `runtime_family_required` | `{"runtime_family_implementation_required": 18}` | token creation with stats, abilities, duration, and zone cleanup |
| `treasure_maker` | 2 | `runtime_family_partially_supported_review_required` | `{"batch_metadata_candidate_requires_pg_precheck": 2}` | treasure creation and discard-draw riders |

## Work Units

### copy_creature_token

- Support: `runtime_family_partially_supported_review_required`
- Batch strategy: `split_by_scope_before_metadata_batch`
- Family tests: `[]`
- Cards: `["Electroduplicate", "Kindle the Inner Flame"]`

### manual_model

- Support: `manual_model_required`
- Batch strategy: `not_batch_safe`
- Family tests: `[]`
- Cards: `["Lim-Dul's Vault", "Demonic Tutor", "Flusterstorm", "Formidable Speaker", "Mystic Remora", "Nature's Rhythm", "Rhystic Study", "Vampiric Tutor"]`

### token_maker

- Support: `runtime_family_required`
- Batch strategy: `implement_family_before_metadata_batch`
- Family tests: `[]`
- Cards: `["Insidious Roots", "Eldrazi Confluence", "Jaxis, the Troublemaker", "Knuckles the Echidna", "Rionya, Fire Dancer", "Springheart Nantuko", "Lotho, Corrupt Shirriff", "Tataru Taru"]`

### treasure_maker

- Support: `runtime_family_partially_supported_review_required`
- Batch strategy: `split_by_scope_before_metadata_batch`
- Family tests: `[]`
- Cards: `["Pirate's Pillage", "Strike It Rich"]`
