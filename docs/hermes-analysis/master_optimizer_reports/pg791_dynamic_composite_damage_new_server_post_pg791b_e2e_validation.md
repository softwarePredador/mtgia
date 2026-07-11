# Battle Package End-to-End Validation

- Generated UTC: `2026-07-11T22:32:00.972031+00:00`
- Package ID: `pg791_dynamic_composite_damage_new_server_manifest`
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
| battle_execution | `pass` | `{"events": 12, "scenarios": 4}` |

## Battle Execution

```json
{
  "event_count": 12,
  "results": [
    {
      "additional_cost": null,
      "card_name": "Focus Fire",
      "controller_life": 10,
      "controller_treasures": 0,
      "damage": 4,
      "life_gained": 0,
      "opponent_life": 20,
      "scenario": "Focus Fire deals fixed target damage",
      "shuffled_self_into_library": false,
      "target": "E2E Fixed Damage Legal Target",
      "treasures_created": 0
    },
    {
      "additional_cost": null,
      "card_name": "Hobbit's Sting",
      "controller_life": 10,
      "controller_treasures": 0,
      "damage": 2,
      "life_gained": 0,
      "opponent_life": 20,
      "scenario": "Hobbit's Sting deals fixed target damage",
      "shuffled_self_into_library": false,
      "target": "E2E Fixed Damage Legal Target",
      "treasures_created": 0
    },
    {
      "additional_cost": null,
      "card_name": "Road Rage",
      "controller_life": 10,
      "controller_treasures": 0,
      "damage": 4,
      "life_gained": 0,
      "opponent_life": 20,
      "scenario": "Road Rage deals fixed target damage",
      "shuffled_self_into_library": false,
      "target": "E2E Fixed Damage Legal Target",
      "treasures_created": 0
    },
    {
      "additional_cost": null,
      "card_name": "Slash of Light",
      "controller_life": 10,
      "controller_treasures": 0,
      "damage": 2,
      "life_gained": 0,
      "opponent_life": 20,
      "scenario": "Slash of Light deals fixed target damage",
      "shuffled_self_into_library": false,
      "target": "E2E Fixed Damage Legal Target",
      "treasures_created": 0
    }
  ],
  "scenario_count": 4
}
```
