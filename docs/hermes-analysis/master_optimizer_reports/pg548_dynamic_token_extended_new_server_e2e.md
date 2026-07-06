# Battle Package End-to-End Validation

- Generated UTC: `2026-07-06T04:06:15.546095+00:00`
- Package ID: `pg548_dynamic_token_extended_new_server_package_manifest`
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
      "card_name": "Flurry of Wings",
      "scenario": "Flurry of Wings creates modeled creature tokens",
      "token_name": "Bird Soldier Token",
      "token_tapped": false,
      "tokens_created": 3
    },
    {
      "card_name": "Ordered Migration",
      "scenario": "Ordered Migration creates modeled creature tokens",
      "token_name": "Bird Token",
      "token_tapped": false,
      "tokens_created": 3
    },
    {
      "card_name": "Rise from the Tides",
      "scenario": "Rise from the Tides creates modeled creature tokens",
      "token_name": "Zombie Token",
      "token_tapped": true,
      "tokens_created": 3
    },
    {
      "card_name": "Spontaneous Generation",
      "scenario": "Spontaneous Generation creates modeled creature tokens",
      "token_name": "Saproling Token",
      "token_tapped": false,
      "tokens_created": 4
    },
    {
      "card_name": "Spore Burst",
      "scenario": "Spore Burst creates modeled creature tokens",
      "token_name": "Saproling Token",
      "token_tapped": false,
      "tokens_created": 3
    }
  ],
  "scenario_count": 5
}
```
