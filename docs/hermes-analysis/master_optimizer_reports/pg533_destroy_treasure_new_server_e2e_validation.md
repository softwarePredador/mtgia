# Battle Package End-to-End Validation

- Generated UTC: `2026-07-05T22:19:02.533734+00:00`
- Package ID: `pg533_destroy_treasure_new_server_package_manifest`
- Status: `pass`
- Database target: `143.198.230.247:5433/halder`
- SQLite DB: `docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db`
- Snapshot: `docs/hermes-analysis/manaloom-knowledge/scripts/known_cards_canonical_snapshot.json`

## Stage Results

| Stage | Status | Evidence |
| --- | --- | --- |
| postgres_source_of_truth | `pass` | `{"validated_rows": 3}` |
| sqlite_hermes_cache | `pass` | `{"validated_rows": 3}` |
| canonical_snapshot_fallback | `pass` | `{"validated_cards": 3}` |
| runtime_get_card_effect | `pass` | `{"validated_cards": 3}` |
| battle_execution | `pass` | `{"events": 12, "scenarios": 3}` |

## Battle Execution

```json
{
  "event_count": 12,
  "results": [
    {
      "card_name": "Contract Killing",
      "controller_treasures_after": 2,
      "scenario": "Contract Killing destroys target and creates Treasure",
      "target": "E2E Creature Target for Contract Killing",
      "target_moved_to_graveyard": true,
      "treasures_created": 2
    },
    {
      "card_name": "Crack Open",
      "controller_treasures_after": 1,
      "scenario": "Crack Open destroys target and creates Treasure",
      "target": "E2E Artifact Target for Crack Open",
      "target_moved_to_graveyard": true,
      "treasures_created": 1
    },
    {
      "card_name": "Grim Bounty",
      "controller_treasures_after": 1,
      "scenario": "Grim Bounty destroys target and creates Treasure",
      "target": "E2E Creature Target for Grim Bounty",
      "target_moved_to_graveyard": true,
      "treasures_created": 1
    }
  ],
  "scenario_count": 3
}
```
