# XMage Semantic Family Classification

Generated at: `2026-06-24T10:34:01+00:00`

Read-only artifact. `mutations_performed=[]`.

- Summary: `{"batch_metadata_candidate_count": 2, "card_count": 201, "family_count": 2, "family_counts": {"dig_spell": 2, "manual_model": 199}, "manual_or_blocked_count": 199, "promotion_lane_counts": {"batch_metadata_candidate_requires_pg_precheck": 2, "mapper_metadata_or_test_scenario_required": 199}, "runtime_family_required_count": 0}`

| Family | Cards | Support | Lane counts | Implementation unit |
| --- | ---: | --- | --- | --- |
| `dig_spell` | 2 | `runtime_supported_family` | `{"batch_metadata_candidate_requires_pg_precheck": 2}` | top-of-library selection to hand with remainder-to-graveyard zone movement |
| `manual_model` | 199 | `manual_model_required` | `{"mapper_metadata_or_test_scenario_required": 199}` | manual Oracle/reference review |

## Work Units

### dig_spell

- Support: `runtime_supported_family`
- Batch strategy: `metadata_batch_after_pg_precheck`
- Family tests: `["test_scattered_thoughts_selects_two_from_top_four_and_bins_the_rest"]`
- Cards: `["Ancestral Memories", "Scattered Thoughts"]`

### manual_model

- Support: `manual_model_required`
- Batch strategy: `not_batch_safe`
- Family tests: `[]`
- Cards: `["Flusterstorm", "Formidable Speaker", "Mystic Remora", "Nature's Rhythm", "Rhystic Study", "Brain Freeze", "Chain of Vapor", "Chord of Calling"]`
