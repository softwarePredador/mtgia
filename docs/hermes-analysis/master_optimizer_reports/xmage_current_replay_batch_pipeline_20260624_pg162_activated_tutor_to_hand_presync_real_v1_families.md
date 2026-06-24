# XMage Semantic Family Classification

Generated at: `2026-06-24T10:10:04+00:00`

Read-only artifact. `mutations_performed=[]`.

- Summary: `{"batch_metadata_candidate_count": 3, "card_count": 206, "family_count": 3, "family_counts": {"creature": 1, "manual_model": 203, "ramp_permanent": 2}, "manual_or_blocked_count": 203, "promotion_lane_counts": {"batch_metadata_candidate_requires_pg_precheck": 3, "mapper_metadata_or_test_scenario_required": 203}, "runtime_family_required_count": 0}`

| Family | Cards | Support | Lane counts | Implementation unit |
| --- | ---: | --- | --- | --- |
| `creature` | 1 | `runtime_family_partially_supported_review_required` | `{"batch_metadata_candidate_requires_pg_precheck": 1}` | creature permanents with exact-scope ETB, death, combat, and activated behavior |
| `manual_model` | 203 | `manual_model_required` | `{"mapper_metadata_or_test_scenario_required": 203}` | manual Oracle/reference review |
| `ramp_permanent` | 2 | `runtime_family_partially_supported_review_required` | `{"batch_metadata_candidate_requires_pg_precheck": 2}` | battlefield mana artifacts and triggered resource permanents |

## Work Units

### creature

- Support: `runtime_family_partially_supported_review_required`
- Batch strategy: `split_by_scope_before_metadata_batch`
- Family tests: `[]`
- Cards: `["Weathered Wayfarer"]`

### manual_model

- Support: `manual_model_required`
- Batch strategy: `not_batch_safe`
- Family tests: `[]`
- Cards: `["Flusterstorm", "Formidable Speaker", "Mystic Remora", "Nature's Rhythm", "Rhystic Study", "Brain Freeze", "Chain of Vapor", "Chord of Calling"]`

### ramp_permanent

- Support: `runtime_family_partially_supported_review_required`
- Batch strategy: `split_by_scope_before_metadata_batch`
- Family tests: `[]`
- Cards: `["Expedition Map", "Moonsilver Key"]`
