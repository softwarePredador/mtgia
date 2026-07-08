# Battle Package End-to-End Validation

- Generated UTC: `2026-07-08T15:26:13.618562+00:00`
- Package ID: `pg663_counter_special_stack_constraints_new_server_package_manifest`
- Status: `pass`
- Database target: `127.0.0.1:15432/halder`
- SQLite DB: `docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db`
- Snapshot: `docs/hermes-analysis/manaloom-knowledge/scripts/known_cards_canonical_snapshot.json`

## Stage Results

| Stage | Status | Evidence |
| --- | --- | --- |
| postgres_source_of_truth | `pass` | `{"validated_rows": 4}` |
| sqlite_hermes_cache | `pass` | `{"validated_rows": 4}` |
| canonical_snapshot_fallback | `pass` | `{"validated_cards": 4}` |
| runtime_get_card_effect | `pass` | `{"validated_cards": 4}` |
| battle_execution | `pass` | `{"events": 4, "scenarios": 4}` |

## Battle Execution

```json
{
  "event_count": 4,
  "results": [
    {
      "card_name": "Avoid Fate",
      "cards_drawn": 0,
      "countered": true,
      "nonmatching_target": "E2E Illegal Counter Target",
      "scenario": "Avoid Fate counters a legal stack object",
      "target": "E2E Legal Counter Target",
      "target_stack_effect": "finisher"
    },
    {
      "card_name": "Double Negative",
      "cards_drawn": 0,
      "countered": true,
      "nonmatching_target": "E2E Illegal Counter Target",
      "scenario": "Double Negative counters a legal stack object",
      "target": "E2E Legal Counter Target",
      "target_stack_effect": "finisher"
    },
    {
      "card_name": "Outwit",
      "cards_drawn": 0,
      "countered": true,
      "nonmatching_target": "E2E Illegal Counter Target",
      "scenario": "Outwit counters a legal stack object",
      "target": "E2E Legal Counter Target",
      "target_stack_effect": "finisher"
    },
    {
      "card_name": "Second Guess",
      "cards_drawn": 0,
      "countered": true,
      "nonmatching_target": "E2E Illegal Counter Target",
      "scenario": "Second Guess counters a legal stack object",
      "target": "E2E Legal Counter Target",
      "target_stack_effect": "finisher"
    }
  ],
  "scenario_count": 4
}
```
