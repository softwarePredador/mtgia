# Battle Package End-to-End Validation

- Generated UTC: `2026-07-12T22:57:36.298099+00:00`
- Package ID: `pg849_counter_target_controller_mill_new_server_package_manifest`
- Status: `pass`
- Database target: `127.0.0.1:15432/halder`
- SQLite DB: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db`
- Snapshot: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/manaloom-knowledge/scripts/known_cards_canonical_snapshot.json`

## Stage Results

| Stage | Status | Evidence |
| --- | --- | --- |
| postgres_source_of_truth | `pass` | `{"validated_rows": 4}` |
| sqlite_hermes_cache | `pass` | `{"validated_rows": 4}` |
| canonical_snapshot_fallback | `pass` | `{"validated_cards": 4}` |
| runtime_get_card_effect | `pass` | `{"validated_cards": 4}` |
| battle_execution | `pass` | `{"events": 8, "scenarios": 4}` |

## Battle Execution

```json
{
  "event_count": 8,
  "results": [
    {
      "additional_cost": null,
      "card_name": "Countermand",
      "cards_drawn": 0,
      "countered": true,
      "countered_spell_to_exile": false,
      "countered_spell_to_top_library": false,
      "nonmatching_target": "E2E Illegal Counter Target",
      "scenario": "Countermand counters a legal stack object",
      "target": "E2E Legal Counter Target",
      "target_controller_cards_milled": 4,
      "target_stack_effect": "finisher"
    },
    {
      "additional_cost": null,
      "card_name": "Didn't Say Please",
      "cards_drawn": 0,
      "countered": true,
      "countered_spell_to_exile": false,
      "countered_spell_to_top_library": false,
      "nonmatching_target": "E2E Illegal Counter Target",
      "scenario": "Didn't Say Please counters a legal stack object",
      "target": "E2E Legal Counter Target",
      "target_controller_cards_milled": 3,
      "target_stack_effect": "finisher"
    },
    {
      "additional_cost": null,
      "card_name": "Psychic Strike",
      "cards_drawn": 0,
      "countered": true,
      "countered_spell_to_exile": false,
      "countered_spell_to_top_library": false,
      "nonmatching_target": "E2E Illegal Counter Target",
      "scenario": "Psychic Strike counters a legal stack object",
      "target": "E2E Legal Counter Target",
      "target_controller_cards_milled": 2,
      "target_stack_effect": "finisher"
    },
    {
      "additional_cost": null,
      "card_name": "Thought Collapse",
      "cards_drawn": 0,
      "countered": true,
      "countered_spell_to_exile": false,
      "countered_spell_to_top_library": false,
      "nonmatching_target": "E2E Illegal Counter Target",
      "scenario": "Thought Collapse counters a legal stack object",
      "target": "E2E Legal Counter Target",
      "target_controller_cards_milled": 3,
      "target_stack_effect": "finisher"
    }
  ],
  "scenario_count": 4
}
```
