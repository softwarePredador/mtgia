# XMage Semantic Family Classification

Generated at: `2026-06-24T05:09:33+00:00`

Read-only artifact. `mutations_performed=[]`.

- Summary: `{"batch_metadata_candidate_count": 0, "card_count": 243, "family_count": 3, "family_counts": {"copy_creature_token": 1, "manual_model": 234, "token_maker": 8}, "manual_or_blocked_count": 235, "promotion_lane_counts": {"blocked_missing_xmage_source": 3, "mapper_metadata_or_test_scenario_required": 231, "runtime_family_implementation_required": 8, "split_family_scope_review_required": 1}, "runtime_family_required_count": 8}`

| Family | Cards | Support | Lane counts | Implementation unit |
| --- | ---: | --- | --- | --- |
| `copy_creature_token` | 1 | `runtime_family_partially_supported_review_required` | `{"split_family_scope_review_required": 1}` | copy-target token creation with haste and end-step cleanup |
| `manual_model` | 234 | `manual_model_required` | `{"blocked_missing_xmage_source": 3, "mapper_metadata_or_test_scenario_required": 231}` | manual Oracle/reference review |
| `token_maker` | 8 | `runtime_family_required` | `{"runtime_family_implementation_required": 8}` | token creation with stats, abilities, duration, and zone cleanup |

## Work Units

### copy_creature_token

- Support: `runtime_family_partially_supported_review_required`
- Batch strategy: `split_by_scope_before_metadata_batch`
- Family tests: `[]`
- Cards: `["Kindle the Inner Flame"]`

### manual_model

- Support: `manual_model_required`
- Batch strategy: `not_batch_safe`
- Family tests: `[]`
- Cards: `["Lim-Dul's Vault", "Demonic Tutor", "Flusterstorm", "Formidable Speaker", "Nature's Rhythm", "Chord of Calling", "Kinnan, Bonder Prodigy", "Mystic Remora"]`

### token_maker

- Support: `runtime_family_required`
- Batch strategy: `implement_family_before_metadata_batch`
- Family tests: `[]`
- Cards: `["Insidious Roots", "Eldrazi Confluence", "Knuckles the Echidna", "Springheart Nantuko", "Magda, Brazen Outlaw", "Hazel's Brewmaster", "Patrol Signaler", "Treasure Vault"]`
