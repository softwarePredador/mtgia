# XMage Semantic Family Classification

Generated at: `2026-06-24T07:57:15+00:00`

Read-only artifact. `mutations_performed=[]`.

- Summary: `{"batch_metadata_candidate_count": 1, "card_count": 235, "family_count": 2, "family_counts": {"creature": 1, "manual_model": 234}, "manual_or_blocked_count": 234, "promotion_lane_counts": {"batch_metadata_candidate_requires_pg_precheck": 1, "mapper_metadata_or_test_scenario_required": 234}, "runtime_family_required_count": 0}`

| Family | Cards | Support | Lane counts | Implementation unit |
| --- | ---: | --- | --- | --- |
| `creature` | 1 | `runtime_family_partially_supported_review_required` | `{"batch_metadata_candidate_requires_pg_precheck": 1}` | creature permanents with exact-scope ETB, death, combat, and activated behavior |
| `manual_model` | 234 | `manual_model_required` | `{"mapper_metadata_or_test_scenario_required": 234}` | manual Oracle/reference review |

## Work Units

### creature

- Support: `runtime_family_partially_supported_review_required`
- Batch strategy: `split_by_scope_before_metadata_batch`
- Family tests: `[]`
- Cards: `["Bartolom\u00e9 del Presidio"]`

### manual_model

- Support: `manual_model_required`
- Batch strategy: `not_batch_safe`
- Family tests: `[]`
- Cards: `["Demonic Tutor", "Flusterstorm", "Formidable Speaker", "Mystic Remora", "Nature's Rhythm", "Rhystic Study", "Vampiric Tutor", "Brain Freeze"]`
