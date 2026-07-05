# Battle Package End-to-End Validation

- Generated UTC: `2026-07-05T23:53:44.273537+00:00`
- Package ID: `pg537_etb_treasure_condition_new_server_package_manifest`
- Status: `pass`
- Database target: `143.198.230.247:5433/halder`
- SQLite DB: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db`
- Snapshot: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/manaloom-knowledge/scripts/known_cards_canonical_snapshot.json`

## Stage Results

| Stage | Status | Evidence |
| --- | --- | --- |
| postgres_source_of_truth | `pass` | `{"validated_rows": 1}` |
| sqlite_hermes_cache | `pass` | `{"validated_rows": 1}` |
| canonical_snapshot_fallback | `pass` | `{"validated_cards": 1}` |
| runtime_get_card_effect | `pass` | `{"validated_cards": 1}` |
| battle_execution | `pass` | `{"events": 1, "scenarios": 1}` |

## Battle Execution

```json
{
  "event_count": 1,
  "results": [
    {
      "card_name": "Ticket Tortoise",
      "controller_treasures_after": 1,
      "scenario": "Ticket Tortoise ETB creates Treasure",
      "treasures_created": 1,
      "validated_condition": "opponent_controls_more_lands",
      "validated_keywords": [
        "defender"
      ]
    }
  ],
  "scenario_count": 1
}
```
