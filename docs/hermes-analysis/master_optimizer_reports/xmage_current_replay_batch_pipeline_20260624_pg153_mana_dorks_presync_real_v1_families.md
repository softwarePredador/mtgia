# XMage Semantic Family Classification

Generated at: `2026-06-24T08:10:18+00:00`

Read-only artifact. `mutations_performed=[]`.

- Summary: `{"batch_metadata_candidate_count": 5, "card_count": 234, "family_count": 2, "family_counts": {"creature": 5, "manual_model": 229}, "manual_or_blocked_count": 229, "promotion_lane_counts": {"batch_metadata_candidate_requires_pg_precheck": 5, "mapper_metadata_or_test_scenario_required": 229}, "runtime_family_required_count": 0}`

| Family | Cards | Support | Lane counts | Implementation unit |
| --- | ---: | --- | --- | --- |
| `creature` | 5 | `runtime_family_partially_supported_review_required` | `{"batch_metadata_candidate_requires_pg_precheck": 5}` | creature permanents with exact-scope ETB, death, combat, and activated behavior |
| `manual_model` | 229 | `manual_model_required` | `{"mapper_metadata_or_test_scenario_required": 229}` | manual Oracle/reference review |

## Work Units

### creature

- Support: `runtime_family_partially_supported_review_required`
- Batch strategy: `split_by_scope_before_metadata_batch`
- Family tests: `[]`
- Cards: `["Birds of Paradise", "Llanowar Elves", "Elvish Mystic", "Avacyn's Pilgrim", "Fyndhorn Elves"]`

### manual_model

- Support: `manual_model_required`
- Batch strategy: `not_batch_safe`
- Family tests: `[]`
- Cards: `["Demonic Tutor", "Flusterstorm", "Formidable Speaker", "Mystic Remora", "Nature's Rhythm", "Rhystic Study", "Vampiric Tutor", "Brain Freeze"]`
