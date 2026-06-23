# XMage Semantic Family Classification

Generated at: `2026-06-23T18:28:13+00:00`

Read-only artifact. `mutations_performed=[]`.

- Summary: `{"batch_metadata_candidate_count": 4, "card_count": 13, "family_count": 8, "family_counts": {"board_wipe_choice": 3, "discard_modal_trigger": 1, "graveyard_spell_copy_cast": 1, "manual_model": 2, "modal_mana_rock": 1, "other_turn_mana_rock": 2, "static_cost_reducer": 2, "token_maker": 1}, "manual_or_blocked_count": 2, "promotion_lane_counts": {"batch_metadata_candidate_requires_pg_precheck": 4, "blocked_missing_xmage_source": 2, "runtime_family_implementation_required": 7}, "runtime_family_required_count": 7}`

| Family | Cards | Support | Lane counts | Implementation unit |
| --- | ---: | --- | --- | --- |
| `board_wipe_choice` | 3 | `runtime_family_required` | `{"runtime_family_implementation_required": 3}` | multi-player choice/wipe/sacrifice resolution |
| `discard_modal_trigger` | 1 | `runtime_family_required` | `{"runtime_family_implementation_required": 1}` | triggered modal once-each-turn resolution |
| `graveyard_spell_copy_cast` | 1 | `runtime_family_required` | `{"runtime_family_implementation_required": 1}` | graveyard target, temporary team boost, delayed combat-damage copy/cast |
| `manual_model` | 2 | `manual_model_required` | `{"blocked_missing_xmage_source": 2}` | manual Oracle/reference review |
| `modal_mana_rock` | 1 | `runtime_family_required` | `{"runtime_family_implementation_required": 1}` | activated artifact mana plus secondary activated/non-mana mode |
| `other_turn_mana_rock` | 2 | `runtime_supported_by_local_artifact` | `{"batch_metadata_candidate_requires_pg_precheck": 2}` | mana source refresh and target-player mana-pool routing |
| `static_cost_reducer` | 2 | `runtime_supported_family` | `{"batch_metadata_candidate_requires_pg_precheck": 2}` | battle cost-locking / affordability / payment reducer |
| `token_maker` | 1 | `runtime_family_required` | `{"runtime_family_implementation_required": 1}` | token creation with stats, abilities, duration, and zone cleanup |

## Work Units

### board_wipe_choice

- Support: `runtime_family_required`
- Batch strategy: `implement_family_before_metadata_batch`
- Family tests: `[]`
- Cards: `["Promise of Loyalty", "Starfall Invocation", "Tragic Arrogance"]`

### discard_modal_trigger

- Support: `runtime_family_required`
- Batch strategy: `implement_family_before_metadata_batch`
- Family tests: `[]`
- Cards: `["Monument to Endurance"]`

### graveyard_spell_copy_cast

- Support: `runtime_family_required`
- Batch strategy: `implement_family_before_metadata_batch`
- Family tests: `[]`
- Cards: `["Surge to Victory"]`

### manual_model

- Support: `manual_model_required`
- Batch strategy: `not_batch_safe`
- Family tests: `[]`
- Cards: `["Molecule Man", "Thor, God of Thunder"]`

### modal_mana_rock

- Support: `runtime_family_required`
- Batch strategy: `implement_family_before_metadata_batch`
- Family tests: `[]`
- Cards: `["The Mind Stone"]`

### other_turn_mana_rock

- Support: `runtime_supported_by_local_artifact`
- Batch strategy: `metadata_batch_after_pg_precheck`
- Family tests: `["pg109_benders_waterskin_victory_chimes_focused_runtime"]`
- Cards: `["Bender's Waterskin", "Victory Chimes"]`

### static_cost_reducer

- Support: `runtime_supported_family`
- Batch strategy: `metadata_batch_after_pg_precheck`
- Family tests: `["test_pearl_medallion_reduces_white_spell_generic_cost_without_mana_source", "test_scarlet_witch_reduces_mv4_instant_or_sorcery_by_source_power", "test_scarlet_witch_does_not_reduce_mv3_or_non_instant_sorcery_spell"]`
- Cards: `["Pearl Medallion", "The Scarlet Witch"]`

### token_maker

- Support: `runtime_family_required`
- Batch strategy: `implement_family_before_metadata_batch`
- Family tests: `[]`
- Cards: `["Emeria's Call // Emeria, Shattered Skyclave"]`
