# Battle Package End-to-End Validation

- Generated UTC: `2026-07-07T03:13:14.326305+00:00`
- Package ID: `pg589_damage_each_opponent_new_server_package_manifest`
- Status: `pass`
- Database target: `127.0.0.1:15432/halder`
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
      "card_name": "Breath of Malfegor",
      "damage": 5,
      "opponent_life": 4,
      "scenario": "Breath of Malfegor damages each opponent",
      "second_opponent_life": 6
    },
    {
      "card_name": "Sizzle",
      "damage": 3,
      "opponent_life": 6,
      "scenario": "Sizzle damages each opponent",
      "second_opponent_life": 8
    }
  ],
  "scenario_count": 2
}
```
