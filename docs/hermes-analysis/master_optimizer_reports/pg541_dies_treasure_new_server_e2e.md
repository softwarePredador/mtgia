# Battle Package End-to-End Validation

- Generated UTC: `2026-07-06T01:36:52.010794+00:00`
- Package ID: `pg541_dies_treasure_new_server_package_manifest`
- Status: `pass`
- Database target: `143.198.230.247:5433/halder`
- SQLite DB: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db`
- Snapshot: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/manaloom-knowledge/scripts/known_cards_canonical_snapshot.json`

## Stage Results

| Stage | Status | Evidence |
| --- | --- | --- |
| postgres_source_of_truth | `pass` | `{"validated_rows": 5}` |
| sqlite_hermes_cache | `pass` | `{"validated_rows": 5}` |
| canonical_snapshot_fallback | `pass` | `{"validated_cards": 5}` |
| runtime_get_card_effect | `pass` | `{"validated_cards": 5}` |
| battle_execution | `pass` | `{"events": 10, "scenarios": 5}` |

## Battle Execution

```json
{
  "event_count": 10,
  "results": [
    {
      "card_name": "Common Crook",
      "controller_treasures_after": 1,
      "scenario": "Common Crook dies and creates Treasure",
      "treasures_created": 1,
      "validated_keywords": []
    },
    {
      "card_name": "Dire Fleet Hoarder",
      "controller_treasures_after": 1,
      "scenario": "Dire Fleet Hoarder dies and creates Treasure",
      "treasures_created": 1,
      "validated_keywords": []
    },
    {
      "card_name": "Gleaming Barrier",
      "controller_treasures_after": 1,
      "scenario": "Gleaming Barrier dies and creates Treasure",
      "treasures_created": 1,
      "validated_keywords": [
        "defender"
      ]
    },
    {
      "card_name": "Jewel-Eyed Cobra",
      "controller_treasures_after": 1,
      "scenario": "Jewel-Eyed Cobra dies and creates Treasure",
      "treasures_created": 1,
      "validated_keywords": [
        "deathtouch"
      ]
    },
    {
      "card_name": "Piggy Bank",
      "controller_treasures_after": 1,
      "scenario": "Piggy Bank dies and creates Treasure",
      "treasures_created": 1,
      "validated_keywords": []
    }
  ],
  "scenario_count": 5
}
```
