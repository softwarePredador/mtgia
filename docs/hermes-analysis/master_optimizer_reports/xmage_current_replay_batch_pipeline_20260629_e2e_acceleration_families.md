# XMage Semantic Family Classification

Generated at: `2026-06-29T12:13:01+00:00`

Read-only artifact. `mutations_performed=[]`.

- Summary: `{"batch_metadata_candidate_count": 0, "card_count": 139, "family_count": 5, "family_counts": {"manual_model": 134, "mill_spell": 1, "modal_spell": 1, "token_maker": 1, "tutor": 2}, "manual_or_blocked_count": 138, "promotion_lane_counts": {"mapper_metadata_or_test_scenario_required": 134, "runtime_family_implementation_required": 1, "split_family_scope_review_required": 4}, "runtime_family_required_count": 1}`

| Family | Cards | Support | Lane counts | Implementation unit |
| --- | ---: | --- | --- | --- |
| `manual_model` | 134 | `manual_model_required` | `{"mapper_metadata_or_test_scenario_required": 134}` | manual Oracle/reference review |
| `mill_spell` | 1 | `runtime_family_partially_supported_review_required` | `{"split_family_scope_review_required": 1}` | target-player library milling, storm copy counting, and activated mill engines |
| `modal_spell` | 1 | `runtime_family_partially_supported_review_required` | `{"split_family_scope_review_required": 1}` | exact-scope modal resolution with repeated mode selection when the card allows it |
| `token_maker` | 1 | `runtime_family_required` | `{"runtime_family_implementation_required": 1}` | token creation with stats, abilities, duration, and zone cleanup |
| `tutor` | 2 | `runtime_family_partially_supported_review_required` | `{"split_family_scope_review_required": 2}` | library search, constrained target selection, and zone movement to hand, top, graveyard, or battlefield |

## Work Units

### manual_model

- Support: `manual_model_required`
- Batch strategy: `not_batch_safe`
- Family tests: `[]`
- Cards: `["Lim-Dul's Vault", "Tymna the Weaver", "Aven Interrupter", "Beseech the Mirror", "Carpet of Flowers", "Culling Ritual", "Deafening Silence", "Intuition"]`

### mill_spell

- Support: `runtime_family_partially_supported_review_required`
- Batch strategy: `split_by_scope_before_metadata_batch`
- Family tests: `["test_brain_freeze_mills_library_instead_of_dealing_life_damage"]`
- Cards: `["Grinding Station"]`

### modal_spell

- Support: `runtime_family_partially_supported_review_required`
- Batch strategy: `split_by_scope_before_metadata_batch`
- Family tests: `[]`
- Cards: `["Scour for Scrap"]`

### token_maker

- Support: `runtime_family_required`
- Batch strategy: `implement_family_before_metadata_batch`
- Family tests: `[]`
- Cards: `["Hazel's Brewmaster"]`

### tutor

- Support: `runtime_family_partially_supported_review_required`
- Batch strategy: `split_by_scope_before_metadata_batch`
- Family tests: `[]`
- Cards: `["Demonic Counsel", "Summoner's Pact"]`
