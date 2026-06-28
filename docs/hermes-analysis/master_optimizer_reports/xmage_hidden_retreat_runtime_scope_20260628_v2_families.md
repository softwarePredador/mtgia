# XMage Semantic Family Classification

Generated at: `2026-06-28T06:54:35+00:00`

Read-only artifact. `mutations_performed=[]`.

- Summary: `{"batch_metadata_candidate_count": 1, "card_count": 1, "family_count": 1, "family_counts": {"damage_prevention_shield": 1}, "manual_or_blocked_count": 0, "promotion_lane_counts": {"batch_metadata_candidate_requires_pg_precheck": 1}, "runtime_family_required_count": 0}`

| Family | Cards | Support | Lane counts | Implementation unit |
| --- | ---: | --- | --- | --- |
| `damage_prevention_shield` | 1 | `runtime_supported_family` | `{"batch_metadata_candidate_requires_pg_precheck": 1}` | activated chosen-source prevention shield that topdecks a hand card and blanks the next matching damage event |

## Work Units

### damage_prevention_shield

- Support: `runtime_supported_family`
- Batch strategy: `metadata_batch_after_pg_precheck`
- Family tests: `["test_pg241_penance_activates_in_combat_window_and_prevents_matching_damage", "test_pg241_penance_skips_non_black_red_source"]`
- Cards: `["Hidden Retreat"]`
