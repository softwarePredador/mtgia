# Battle Package End-to-End Validation

- Generated UTC: `2026-07-08T19:56:19.404137+00:00`
- Package ID: `pg670_damage_treasure_new_server_package_manifest`
- Status: `pass`
- Database target: `127.0.0.1:15432/halder`
- SQLite DB: `docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db`
- Snapshot: `docs/hermes-analysis/manaloom-knowledge/scripts/known_cards_canonical_snapshot.json`

## Stage Results

| Stage | Status | Evidence |
| --- | --- | --- |
| postgres_source_of_truth | `pass` | `{"validated_rows": 1}` |
| sqlite_hermes_cache | `pass` | `{"validated_rows": 1}` |
| canonical_snapshot_fallback | `pass` | `{"validated_cards": 1}` |
| runtime_get_card_effect | `pass` | `{"validated_cards": 1}` |
| battle_execution | `pass` | `{"events": 4, "scenarios": 1}` |

## Battle Execution

```json
{
  "event_count": 4,
  "results": [
    {
      "card_name": "Improvised Weaponry",
      "controller_life": 10,
      "controller_treasures": 1,
      "damage": 2,
      "life_gained": 0,
      "opponent_life": 20,
      "scenario": "Improvised Weaponry deals fixed target damage and creates Treasure",
      "target": "E2E Damage Treasure Legal Target",
      "treasures_created": 1
    }
  ],
  "scenario_count": 1
}
```
