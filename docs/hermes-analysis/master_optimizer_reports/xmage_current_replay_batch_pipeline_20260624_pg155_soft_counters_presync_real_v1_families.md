# XMage Semantic Family Classification

Generated at: `2026-06-24T08:29:27+00:00`

Read-only artifact. `mutations_performed=[]`.

- Summary: `{"batch_metadata_candidate_count": 3, "card_count": 226, "family_count": 2, "family_counts": {"manual_model": 223, "targeted_interaction": 3}, "manual_or_blocked_count": 223, "promotion_lane_counts": {"batch_metadata_candidate_requires_pg_precheck": 3, "mapper_metadata_or_test_scenario_required": 223}, "runtime_family_required_count": 0}`

| Family | Cards | Support | Lane counts | Implementation unit |
| --- | ---: | --- | --- | --- |
| `manual_model` | 223 | `manual_model_required` | `{"mapper_metadata_or_test_scenario_required": 223}` | manual Oracle/reference review |
| `targeted_interaction` | 3 | `runtime_family_partially_supported_review_required` | `{"batch_metadata_candidate_requires_pg_precheck": 3}` | target legality, resolution, zone transition, and event provenance |

## Work Units

### manual_model

- Support: `manual_model_required`
- Batch strategy: `not_batch_safe`
- Family tests: `[]`
- Cards: `["Demonic Tutor", "Flusterstorm", "Formidable Speaker", "Mystic Remora", "Nature's Rhythm", "Rhystic Study", "Vampiric Tutor", "Brain Freeze"]`

### targeted_interaction

- Support: `runtime_family_partially_supported_review_required`
- Batch strategy: `split_by_scope_before_metadata_batch`
- Family tests: `[]`
- Cards: `["Mana Leak", "Miscast", "Spell Pierce"]`
