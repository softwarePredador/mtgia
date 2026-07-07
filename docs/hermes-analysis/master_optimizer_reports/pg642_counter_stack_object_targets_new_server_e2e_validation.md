# Battle Package End-to-End Validation

- Generated UTC: `2026-07-07T21:43:11.936212+00:00`
- Package ID: `pg642_counter_stack_object_targets_new_server_manifest`
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
| battle_execution | `pass` | `{"events": 4, "scenarios": 4}` |

## Battle Execution

```json
{
  "event_count": 4,
  "results": [
    {
      "card_name": "Disallow",
      "countered": true,
      "nonmatching_target": "E2E Illegal Counter Target",
      "scenario": "Disallow counters a legal stack object",
      "target": "E2E Legal Counter Target",
      "target_stack_effect": "finisher"
    },
    {
      "card_name": "Stern Scolding",
      "countered": true,
      "nonmatching_target": "E2E Illegal Counter Target",
      "scenario": "Stern Scolding counters a legal stack object",
      "target": "E2E Legal Counter Target",
      "target_stack_effect": "finisher"
    },
    {
      "card_name": "Tale's End",
      "countered": true,
      "nonmatching_target": "E2E Illegal Counter Target",
      "scenario": "Tale's End counters a legal stack object",
      "target": "E2E Legal Counter Target",
      "target_stack_effect": "finisher"
    },
    {
      "card_name": "Voidslime",
      "countered": true,
      "nonmatching_target": "E2E Illegal Counter Target",
      "scenario": "Voidslime counters a legal stack object",
      "target": "E2E Legal Counter Target",
      "target_stack_effect": "finisher"
    }
  ],
  "scenario_count": 4
}
```
