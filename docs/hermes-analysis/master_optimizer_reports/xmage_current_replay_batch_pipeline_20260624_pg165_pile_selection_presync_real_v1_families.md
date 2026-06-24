# XMage Semantic Family Classification

Generated at: `2026-06-24T10:43:12+00:00`

Read-only artifact. `mutations_performed=[]`.

- Summary: `{"batch_metadata_candidate_count": 2, "card_count": 199, "family_count": 2, "family_counts": {"manual_model": 197, "pile_selection_spell": 2}, "manual_or_blocked_count": 197, "promotion_lane_counts": {"batch_metadata_candidate_requires_pg_precheck": 2, "mapper_metadata_or_test_scenario_required": 197}, "runtime_family_required_count": 0}`

| Family | Cards | Support | Lane counts | Implementation unit |
| --- | ---: | --- | --- | --- |
| `manual_model` | 197 | `manual_model_required` | `{"mapper_metadata_or_test_scenario_required": 197}` | manual Oracle/reference review |
| `pile_selection_spell` | 2 | `runtime_supported_family` | `{"batch_metadata_candidate_requires_pg_precheck": 2}` | top-of-library reveal, two-pile minimax partitioning, and hand-versus-graveyard zone movement |

## Work Units

### manual_model

- Support: `manual_model_required`
- Batch strategy: `not_batch_safe`
- Family tests: `[]`
- Cards: `["Flusterstorm", "Formidable Speaker", "Mystic Remora", "Nature's Rhythm", "Rhystic Study", "Brain Freeze", "Chain of Vapor", "Chord of Calling"]`

### pile_selection_spell

- Support: `runtime_supported_family`
- Batch strategy: `metadata_batch_after_pg_precheck`
- Family tests: `["test_fact_or_fiction_minimizes_best_available_pile", "test_steam_augury_maximizes_worst_available_pile"]`
- Cards: `["Fact or Fiction", "Steam Augury"]`
