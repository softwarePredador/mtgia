# Battle Package End-to-End Validation

- Generated UTC: `2026-07-05T22:41:25.010993+00:00`
- Package ID: `pg534_multi_tokens_new_server_package_manifest`
- Status: `pass`
- Database target: `143.198.230.247:5433/halder`
- SQLite DB: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db`
- Snapshot: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/manaloom-knowledge/scripts/known_cards_canonical_snapshot.json`

## Stage Results

| Stage | Status | Evidence |
| --- | --- | --- |
| postgres_source_of_truth | `pass` | `{"validated_rows": 3}` |
| sqlite_hermes_cache | `pass` | `{"validated_rows": 3}` |
| canonical_snapshot_fallback | `pass` | `{"validated_cards": 3}` |
| runtime_get_card_effect | `pass` | `{"validated_cards": 3}` |
| battle_execution | `pass` | `{"events": 14, "scenarios": 3}` |

## Battle Execution

```json
{
  "event_count": 14,
  "results": [
    {
      "card_name": "Bestial Menace",
      "component_count": 3,
      "scenario": "Bestial Menace creates multiple modeled creature tokens",
      "token_names": [
        "Elephant Token",
        "Snake Token",
        "Wolf Token"
      ],
      "tokens_created": 3
    },
    {
      "card_name": "Forbidden Friendship",
      "component_count": 2,
      "scenario": "Forbidden Friendship creates multiple modeled creature tokens",
      "token_names": [
        "Dinosaur Token",
        "Human Soldier Token"
      ],
      "tokens_created": 2
    },
    {
      "card_name": "Mascot Exhibition",
      "component_count": 3,
      "scenario": "Mascot Exhibition creates multiple modeled creature tokens",
      "token_names": [
        "Elemental Token",
        "Inkling Token",
        "Spirit Token"
      ],
      "tokens_created": 3
    }
  ],
  "scenario_count": 3
}
```
