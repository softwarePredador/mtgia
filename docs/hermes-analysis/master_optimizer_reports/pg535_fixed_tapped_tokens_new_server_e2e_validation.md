# Battle Package End-to-End Validation

- Generated UTC: `2026-07-05T23:03:10.289766+00:00`
- Package ID: `pg535_fixed_tapped_tokens_new_server_package_manifest`
- Status: `pass`
- Database target: `143.198.230.247:5433/halder`
- SQLite DB: `docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db`
- Snapshot: `docs/hermes-analysis/manaloom-knowledge/scripts/known_cards_canonical_snapshot.json`

## Stage Results

| Stage | Status | Evidence |
| --- | --- | --- |
| postgres_source_of_truth | `pass` | `{"validated_rows": 2}` |
| sqlite_hermes_cache | `pass` | `{"validated_rows": 2}` |
| canonical_snapshot_fallback | `pass` | `{"validated_cards": 2}` |
| runtime_get_card_effect | `pass` | `{"validated_cards": 2}` |
| battle_execution | `pass` | `{"events": 4, "scenarios": 2}` |

## Battle Execution

```json
{
  "event_count": 4,
  "results": [
    {
      "card_name": "Servo Exhibition",
      "scenario": "Servo Exhibition creates modeled creature tokens",
      "token_name": "Servo Token",
      "token_tapped": false,
      "tokens_created": 2
    },
    {
      "card_name": "Shadow Summoning",
      "scenario": "Shadow Summoning creates modeled creature tokens",
      "token_name": "Spirit Token",
      "token_tapped": true,
      "tokens_created": 2
    }
  ],
  "scenario_count": 2
}
```
