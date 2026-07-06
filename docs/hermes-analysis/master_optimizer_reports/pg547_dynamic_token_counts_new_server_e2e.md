# Battle Package End-to-End Validation

- Generated UTC: `2026-07-06T03:41:08.278270+00:00`
- Package ID: `pg547_dynamic_token_counts_new_server_package_manifest`
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
      "card_name": "Crash the Party",
      "scenario": "Crash the Party creates modeled creature tokens",
      "token_name": "Rhino Warrior Token",
      "token_tapped": true,
      "tokens_created": 3
    },
    {
      "card_name": "Deploy to the Front",
      "scenario": "Deploy to the Front creates modeled creature tokens",
      "token_name": "Soldier Token",
      "token_tapped": false,
      "tokens_created": 4
    },
    {
      "card_name": "Fungal Sprouting",
      "scenario": "Fungal Sprouting creates modeled creature tokens",
      "token_name": "Saproling Token",
      "token_tapped": false,
      "tokens_created": 4
    },
    {
      "card_name": "Goblin Gathering",
      "scenario": "Goblin Gathering creates modeled creature tokens",
      "token_name": "Goblin Token",
      "token_tapped": false,
      "tokens_created": 4
    },
    {
      "card_name": "Howl of the Night Pack",
      "scenario": "Howl of the Night Pack creates modeled creature tokens",
      "token_name": "Wolf Token",
      "token_tapped": false,
      "tokens_created": 3
    }
  ],
  "scenario_count": 5
}
```
