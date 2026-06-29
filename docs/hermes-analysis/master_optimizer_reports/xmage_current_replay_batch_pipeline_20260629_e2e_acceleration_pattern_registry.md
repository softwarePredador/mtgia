# XMage Shadow Pattern Registry

- Generated at: `2026-06-29T12:13:01+00:00`
- Status: `ready`
- Mutations performed: `[]`
- Promotion status: `shadow_only`

## Summary

- `proposal_count`: `139`
- `pattern_count`: `6`
- `lane_counts`: `{"manual_mapper_backlog": 134, "runtime_family_backlog": 1, "split_scope_backlog": 4}`
- `pattern_status_counts`: `{"candidate_template_requires_review_tests": 4, "fragmented_runtime_observation_only": 1, "manual_model_observation_only": 1}`
- `card_counts_by_pattern_status`: `{"candidate_template_requires_review_tests": 4, "fragmented_runtime_observation_only": 1, "manual_model_observation_only": 134}`
- `executable_pattern_count`: `0`
- `auto_promotable_pattern_count`: `0`

## Boundary

- Registry rows are advisory evidence only.
- Executable battle behavior still belongs in reviewed/tested `card_battle_rules`.
- Do not join registry rows directly into deck-card consumers.
- PostgreSQL/Hermes writes remain approval-gated.

## Patterns

| Pattern | Lane | Status | Cards | Subpatterns | Action |
| --- | --- | --- | ---: | ---: | --- |
| `mill_spell/mill_engine/artifact_tap_sacrifice_permanent_target_player_mill_v1` | `split_scope_backlog` | `candidate_template_requires_review_tests` | 1 | 1 | Review before promotion. |
| `modal_spell/modal_spell/modal_artifact_tutor_or_artifact_graveyard_to_hand_v1` | `split_scope_backlog` | `candidate_template_requires_review_tests` | 1 | 1 | Review before promotion. |
| `tutor/tutor/conditional_delirium_restricted_or_any_tutor_to_hand_v1` | `split_scope_backlog` | `candidate_template_requires_review_tests` | 1 | 1 | Review before promotion. |
| `tutor/tutor/pact_green_creature_tutor_to_hand_delayed_payment_v1` | `split_scope_backlog` | `candidate_template_requires_review_tests` | 1 | 1 | Review before promotion. |
| `token_maker/token_maker/xmage_create_token_variant_hazelsbrewmaster_v1` | `runtime_family_backlog` | `fragmented_runtime_observation_only` | 1 | 1 | Keep as registry evidence; wait for taxonomy/test-miner support before executor work. |
| `manual_model/external_reference_required_manual_model/xmage_reference_requires_manual_model_review_v1` | `manual_mapper_backlog` | `manual_model_observation_only` | 134 | 40 | Keep after package, split-scope, and homogeneous-runtime lanes. |

## Top Pattern Details

### mill_spell / mill_engine / artifact_tap_sacrifice_permanent_target_player_mill_v1

- Pattern id: `xmage_pattern:66611bf37756ed6a27eb`
- Lane: `split_scope_backlog`
- Status: `candidate_template_requires_review_tests`
- Cards: `1` (Grinding Station)
- Subpatterns: `1`
- Required evidence: `["review", "focused test", "promotion gate"]`

### modal_spell / modal_spell / modal_artifact_tutor_or_artifact_graveyard_to_hand_v1

- Pattern id: `xmage_pattern:a76c20bec936fa38b8b6`
- Lane: `split_scope_backlog`
- Status: `candidate_template_requires_review_tests`
- Cards: `1` (Scour for Scrap)
- Subpatterns: `1`
- Required evidence: `["review", "focused test", "promotion gate"]`

### tutor / tutor / conditional_delirium_restricted_or_any_tutor_to_hand_v1

- Pattern id: `xmage_pattern:0ca4cbb866e75ce66af2`
- Lane: `split_scope_backlog`
- Status: `candidate_template_requires_review_tests`
- Cards: `1` (Demonic Counsel)
- Subpatterns: `1`
- Required evidence: `["review", "focused test", "promotion gate"]`

### tutor / tutor / pact_green_creature_tutor_to_hand_delayed_payment_v1

- Pattern id: `xmage_pattern:721ed0460770572ca8f8`
- Lane: `split_scope_backlog`
- Status: `candidate_template_requires_review_tests`
- Cards: `1` (Summoner's Pact)
- Subpatterns: `1`
- Required evidence: `["review", "focused test", "promotion gate"]`

### token_maker / token_maker / xmage_create_token_variant_hazelsbrewmaster_v1

- Pattern id: `xmage_pattern:c50444dfd944a84cf5e7`
- Lane: `runtime_family_backlog`
- Status: `fragmented_runtime_observation_only`
- Cards: `1` (Hazel's Brewmaster)
- Subpatterns: `1`
- Required evidence: `["taxonomy support", "test miner coverage", "do not open broad runtime by raw family count"]`

### manual_model / external_reference_required_manual_model / xmage_reference_requires_manual_model_review_v1

- Pattern id: `xmage_pattern:1c4300d3a825055c0113`
- Lane: `manual_mapper_backlog`
- Status: `manual_model_observation_only`
- Cards: `134` ("Name Sticker" Goblin, Altar of Dementia, Aminatou's Augury, Amphibian Downpour, Archon of Emeria, Ashnod's Altar, Autumn's Veil, Aven Interrupter, Aven Mindcensor, Beseech the Mirror)
- Subpatterns: `40`
- Required evidence: `["manual mapper review", "Oracle/source provenance", "focused test before promotion"]`
