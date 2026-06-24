# XMage Semantic Family Classification

Generated at: `2026-06-24T10:20:16+00:00`

Read-only artifact. `mutations_performed=[]`.

- Summary: `{"batch_metadata_candidate_count": 2, "card_count": 203, "family_count": 2, "family_counts": {"extra_turn_spell": 2, "manual_model": 201}, "manual_or_blocked_count": 201, "promotion_lane_counts": {"batch_metadata_candidate_requires_pg_precheck": 2, "mapper_metadata_or_test_scenario_required": 201}, "runtime_family_required_count": 0}`

| Family | Cards | Support | Lane counts | Implementation unit |
| --- | ---: | --- | --- | --- |
| `extra_turn_spell` | 2 | `runtime_supported_family` | `{"batch_metadata_candidate_requires_pg_precheck": 2}` | extra turn scheduling and delayed lose-the-game bookkeeping |
| `manual_model` | 201 | `manual_model_required` | `{"mapper_metadata_or_test_scenario_required": 201}` | manual Oracle/reference review |

## Work Units

### extra_turn_spell

- Support: `runtime_supported_family`
- Batch strategy: `metadata_batch_after_pg_precheck`
- Family tests: `["test_final_fortune_extra_turn_causes_loss_after_taken_turn"]`
- Cards: `["Final Fortune", "Last Chance"]`

### manual_model

- Support: `manual_model_required`
- Batch strategy: `not_batch_safe`
- Family tests: `[]`
- Cards: `["Flusterstorm", "Formidable Speaker", "Mystic Remora", "Nature's Rhythm", "Rhystic Study", "Brain Freeze", "Chain of Vapor", "Chord of Calling"]`
