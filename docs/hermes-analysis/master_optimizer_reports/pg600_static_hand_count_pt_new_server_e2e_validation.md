# Battle Package End-to-End Validation

- Generated UTC: `2026-07-07T07:17:17.797250+00:00`
- Package ID: `pg600_static_hand_count_pt_new_server_manifest`
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
      "card_name": "Adamaro, First to Desire",
      "count": 4,
      "power": 4,
      "scenario": "Adamaro, First to Desire static count P/T recalculates",
      "toughness": 4
    },
    {
      "card_name": "Maro",
      "count": 3,
      "power": 3,
      "scenario": "Maro static count P/T recalculates",
      "toughness": 3
    },
    {
      "card_name": "Masumaro, First to Live",
      "count": 3,
      "power": 6,
      "scenario": "Masumaro, First to Live static count P/T recalculates",
      "toughness": 6
    },
    {
      "card_name": "Multani, Maro-Sorcerer",
      "count": 5,
      "power": 5,
      "scenario": "Multani, Maro-Sorcerer static count P/T recalculates",
      "toughness": 5
    }
  ],
  "scenario_count": 4
}
```
