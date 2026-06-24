# XMage Semantic Family Classification

Generated at: `2026-06-24T06:37:09+00:00`

Read-only artifact. `mutations_performed=[]`.

- Summary: `{"batch_metadata_candidate_count": 1, "card_count": 240, "family_count": 4, "family_counts": {"copy_creature_token": 1, "manual_model": 235, "modal_spell": 1, "token_maker": 3}, "manual_or_blocked_count": 236, "promotion_lane_counts": {"batch_metadata_candidate_requires_pg_precheck": 1, "blocked_missing_xmage_source": 3, "mapper_metadata_or_test_scenario_required": 232, "runtime_family_implementation_required": 3, "split_family_scope_review_required": 1}, "runtime_family_required_count": 3}`

| Family | Cards | Support | Lane counts | Implementation unit |
| --- | ---: | --- | --- | --- |
| `copy_creature_token` | 1 | `runtime_family_partially_supported_review_required` | `{"split_family_scope_review_required": 1}` | copy-target token creation with haste and end-step cleanup |
| `manual_model` | 235 | `manual_model_required` | `{"blocked_missing_xmage_source": 3, "mapper_metadata_or_test_scenario_required": 232}` | manual Oracle/reference review |
| `modal_spell` | 1 | `runtime_family_partially_supported_review_required` | `{"batch_metadata_candidate_requires_pg_precheck": 1}` | exact-scope modal resolution with repeated mode selection when the card allows it |
| `token_maker` | 3 | `runtime_family_required` | `{"runtime_family_implementation_required": 3}` | token creation with stats, abilities, duration, and zone cleanup |

## Work Units

### copy_creature_token

- Support: `runtime_family_partially_supported_review_required`
- Batch strategy: `split_by_scope_before_metadata_batch`
- Family tests: `[]`
- Cards: `["Kindle the Inner Flame"]`

### manual_model

- Support: `manual_model_required`
- Batch strategy: `not_batch_safe`
- Family tests: `[]`
- Cards: `["Demonic Tutor", "Flusterstorm", "Formidable Speaker", "Mystic Remora", "Nature's Rhythm", "Rhystic Study", "Vampiric Tutor", "Brain Freeze"]`

### modal_spell

- Support: `runtime_family_partially_supported_review_required`
- Batch strategy: `split_by_scope_before_metadata_batch`
- Family tests: `[]`
- Cards: `["Eldrazi Confluence"]`

### token_maker

- Support: `runtime_family_required`
- Batch strategy: `implement_family_before_metadata_batch`
- Family tests: `[]`
- Cards: `["Insidious Roots", "Springheart Nantuko", "Magda, Brazen Outlaw"]`
