# Battle Package End-to-End Validation

- Generated UTC: `2026-07-05T23:27:44.572803+00:00`
- Package ID: `pg536_etb_treasure_new_server_package_manifest`
- Status: `pass`
- Database target: `143.198.230.247:5433/halder`
- SQLite DB: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db`
- Snapshot: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/manaloom-knowledge/scripts/known_cards_canonical_snapshot.json`

## Stage Results

| Stage | Status | Evidence |
| --- | --- | --- |
| postgres_source_of_truth | `pass` | `{"validated_rows": 6}` |
| sqlite_hermes_cache | `pass` | `{"validated_rows": 6}` |
| canonical_snapshot_fallback | `pass` | `{"validated_cards": 6}` |
| runtime_get_card_effect | `pass` | `{"validated_cards": 6}` |
| battle_execution | `pass` | `{"events": 6, "scenarios": 6}` |

## Battle Execution

```json
{
  "event_count": 6,
  "results": [
    {
      "card_name": "Brazen Freebooter",
      "controller_treasures_after": 1,
      "scenario": "Brazen Freebooter ETB creates Treasure",
      "treasures_created": 1
    },
    {
      "card_name": "Plundering Pirate",
      "controller_treasures_after": 1,
      "scenario": "Plundering Pirate ETB creates Treasure",
      "treasures_created": 1
    },
    {
      "card_name": "Prosperous Pirates",
      "controller_treasures_after": 2,
      "scenario": "Prosperous Pirates ETB creates Treasure",
      "treasures_created": 2
    },
    {
      "card_name": "Redcap Thief",
      "controller_treasures_after": 1,
      "scenario": "Redcap Thief ETB creates Treasure",
      "treasures_created": 1
    },
    {
      "card_name": "Sailor of Means",
      "controller_treasures_after": 1,
      "scenario": "Sailor of Means ETB creates Treasure",
      "treasures_created": 1
    },
    {
      "card_name": "Wily Goblin",
      "controller_treasures_after": 1,
      "scenario": "Wily Goblin ETB creates Treasure",
      "treasures_created": 1
    }
  ],
  "scenario_count": 6
}
```
