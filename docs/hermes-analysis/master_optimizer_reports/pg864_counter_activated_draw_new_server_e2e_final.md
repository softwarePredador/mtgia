# Battle Package End-to-End Validation

- Generated UTC: `2026-07-13T05:20:55.365769+00:00`
- Package ID: `pg864_counter_activated_draw_new_server_manifest`
- Status: `pass`
- Database target: `127.0.0.1:15432/halder`
- SQLite DB: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db`
- Snapshot: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/manaloom-knowledge/scripts/known_cards_canonical_snapshot.json`

## Stage Results

| Stage | Status | Evidence |
| --- | --- | --- |
| postgres_source_of_truth | `pass` | `{"validated_rows": 3}` |
| sqlite_hermes_cache | `pass` | `{"validated_rows": 3}` |
| canonical_snapshot_fallback | `pass` | `{"validated_cards": 3}` |
| runtime_get_card_effect | `pass` | `{"validated_cards": 3}` |
| battle_execution | `pass` | `{"events": 3, "scenarios": 3}` |

## Battle Execution

```json
{
  "event_count": 3,
  "results": [
    {
      "additional_cost": null,
      "card_name": "Bind",
      "cards_drawn": 1,
      "countered": true,
      "countered_spell_to_exile": false,
      "countered_spell_to_top_library": false,
      "nonmatching_target": "E2E Illegal Counter Target",
      "scenario": "Bind counters a legal stack object",
      "target": "E2E Legal Counter Target",
      "target_controller_cards_milled": 0,
      "target_stack_effect": "activated_ability"
    },
    {
      "additional_cost": null,
      "card_name": "Bind // Liberate",
      "cards_drawn": 1,
      "countered": true,
      "countered_spell_to_exile": false,
      "countered_spell_to_top_library": false,
      "nonmatching_target": "E2E Illegal Counter Target",
      "scenario": "Bind // Liberate counters a legal stack object",
      "target": "E2E Legal Counter Target",
      "target_controller_cards_milled": 0,
      "target_stack_effect": "activated_ability"
    },
    {
      "additional_cost": null,
      "card_name": "Squelch",
      "cards_drawn": 1,
      "countered": true,
      "countered_spell_to_exile": false,
      "countered_spell_to_top_library": false,
      "nonmatching_target": "E2E Illegal Counter Target",
      "scenario": "Squelch counters a legal stack object",
      "target": "E2E Legal Counter Target",
      "target_controller_cards_milled": 0,
      "target_stack_effect": "activated_ability"
    }
  ],
  "scenario_count": 3
}
```
