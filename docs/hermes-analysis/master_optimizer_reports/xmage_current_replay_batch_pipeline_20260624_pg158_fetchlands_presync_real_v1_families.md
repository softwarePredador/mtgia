# XMage Semantic Family Classification

Generated at: `2026-06-24T09:02:44+00:00`

Read-only artifact. `mutations_performed=[]`.

- Summary: `{"batch_metadata_candidate_count": 3, "card_count": 220, "family_count": 2, "family_counts": {"manual_model": 217, "ramp_permanent": 3}, "manual_or_blocked_count": 217, "promotion_lane_counts": {"batch_metadata_candidate_requires_pg_precheck": 3, "mapper_metadata_or_test_scenario_required": 217}, "runtime_family_required_count": 0}`

| Family | Cards | Support | Lane counts | Implementation unit |
| --- | ---: | --- | --- | --- |
| `manual_model` | 217 | `manual_model_required` | `{"mapper_metadata_or_test_scenario_required": 217}` | manual Oracle/reference review |
| `ramp_permanent` | 3 | `runtime_family_partially_supported_review_required` | `{"batch_metadata_candidate_requires_pg_precheck": 3}` | battlefield mana artifacts and triggered resource permanents |

## Work Units

### manual_model

- Support: `manual_model_required`
- Batch strategy: `not_batch_safe`
- Family tests: `[]`
- Cards: `["Demonic Tutor", "Flusterstorm", "Formidable Speaker", "Mystic Remora", "Nature's Rhythm", "Rhystic Study", "Vampiric Tutor", "Brain Freeze"]`

### ramp_permanent

- Support: `runtime_family_partially_supported_review_required`
- Batch strategy: `split_by_scope_before_metadata_batch`
- Family tests: `[]`
- Cards: `["Misty Rainforest", "Verdant Catacombs", "Polluted Delta"]`
