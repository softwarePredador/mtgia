# XMage Semantic Family Classification

Generated at: `2026-06-24T09:48:58+00:00`

Read-only artifact. `mutations_performed=[]`.

- Summary: `{"batch_metadata_candidate_count": 5, "card_count": 211, "family_count": 2, "family_counts": {"creature": 2, "manual_model": 209}, "manual_or_blocked_count": 206, "promotion_lane_counts": {"batch_metadata_candidate_requires_pg_precheck": 5, "mapper_metadata_or_test_scenario_required": 206}, "runtime_family_required_count": 0}`

| Family | Cards | Support | Lane counts | Implementation unit |
| --- | ---: | --- | --- | --- |
| `creature` | 2 | `runtime_family_partially_supported_review_required` | `{"batch_metadata_candidate_requires_pg_precheck": 2}` | creature permanents with exact-scope ETB, death, combat, and activated behavior |
| `manual_model` | 209 | `manual_model_required` | `{"batch_metadata_candidate_requires_pg_precheck": 3, "mapper_metadata_or_test_scenario_required": 206}` | manual Oracle/reference review |

## Work Units

### creature

- Support: `runtime_family_partially_supported_review_required`
- Batch strategy: `split_by_scope_before_metadata_batch`
- Family tests: `[]`
- Cards: `["Spellseeker", "Trophy Mage"]`

### manual_model

- Support: `manual_model_required`
- Batch strategy: `not_batch_safe`
- Family tests: `[]`
- Cards: `["Demonic Tutor", "Flusterstorm", "Formidable Speaker", "Mystic Remora", "Nature's Rhythm", "Rhystic Study", "Brain Freeze", "Chain of Vapor"]`
