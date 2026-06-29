# PGC068 Return the Favor Spree Stack Object Runtime Validation

- Generated UTC: `2026-06-29T11:56:04.149834+00:00`
- Package ID: `pgc068_return_favor_spree_stack_object_runtime`
- Status: `pass`
- Database target: `143.198.230.247:5433/halder`
- SQLite DB: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db`
- Snapshot: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/manaloom-knowledge/scripts/known_cards_canonical_snapshot.json`

## Stage Results

| Stage | Status | Evidence |
| --- | --- | --- |
| postgres_source_of_truth | `pass` | `{"validated_rows": 1}` |
| sqlite_hermes_cache | `pass` | `{"validated_rows": 1}` |
| canonical_snapshot_fallback | `pass` | `{"validated_cards": 1}` |
| runtime_get_card_effect | `pass` | `{"validated_cards": 1}` |
| battle_execution_no_override | `pass` | `{"events": 11, "scenarios": 3}` |

## Battle Execution

```json
{
  "event_count": 11,
  "results": [
    {
      "card_name": "Return the Favor",
      "copied_spell": "Targeted Insight",
      "copy_path": "response",
      "copy_spell_target": null,
      "copy_target_selection_status": "may_choose_new_targets",
      "locked_cost": {
        "colored": {
          "red": 2
        },
        "generic": 1,
        "hybrid": [],
        "monocolored_hybrid": [],
        "phyrexian": [],
        "phyrexian_hybrid": [],
        "spend_tags": [
          "instant_or_sorcery_spell",
          "noncreature_spell"
        ]
      },
      "scenario": "return_favor_copy_spell_pays_spree_selected_mode",
      "spree": {
        "spree_additional_cost_paid": true,
        "spree_additional_cost_status": "runtime_executor_v1",
        "spree_additional_costs": [
          "{1}"
        ],
        "spree_selected_modes": [
          "copy_instant_or_sorcery_spell"
        ]
      },
      "target_reassignment_performed": false
    },
    {
      "card_name": "Return the Favor",
      "copied_stack_object": "Lorehold Trigger",
      "copy_activated_triggered_ability_status": "runtime_executor_v1",
      "copy_resolutions": 1,
      "locked_cost": {
        "colored": {
          "red": 2
        },
        "generic": 1,
        "hybrid": [],
        "monocolored_hybrid": [],
        "phyrexian": [],
        "phyrexian_hybrid": [],
        "spend_tags": [
          "instant_or_sorcery_spell",
          "noncreature_spell"
        ]
      },
      "scenario": "return_favor_copy_triggered_ability_pays_spree_selected_mode",
      "spree": {
        "spree_additional_cost_paid": true,
        "spree_additional_cost_status": "runtime_executor_v1",
        "spree_additional_costs": [
          "{1}"
        ],
        "spree_selected_modes": [
          "copy_instant_or_sorcery_spell"
        ]
      },
      "target_type": "activated_or_triggered_ability_on_stack"
    },
    {
      "card_name": "Return the Favor",
      "locked_cost": {
        "colored": {
          "red": 2
        },
        "generic": 1,
        "hybrid": [],
        "monocolored_hybrid": [],
        "phyrexian": [],
        "phyrexian_hybrid": [],
        "spend_tags": [
          "instant_or_sorcery_spell",
          "noncreature_spell"
        ]
      },
      "new_target": "Opponent Threat",
      "old_target": "Protected Creature",
      "scenario": "return_favor_change_single_target_pays_spree_selected_mode",
      "spree": {
        "spree_additional_cost_paid": true,
        "spree_additional_cost_status": "runtime_executor_v1",
        "spree_additional_costs": [
          "{1}"
        ],
        "spree_selected_modes": [
          "change_single_target"
        ]
      },
      "target_change_applied": true,
      "target_change_pipeline": "single_target_stack_object_redirect_runtime_v1"
    }
  ],
  "scenario_count": 3
}
```
