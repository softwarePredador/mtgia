# Battle Package End-to-End Validation

- Generated UTC: `2026-07-06T04:19:40.576410+00:00`
- Package ID: `pg549_token_flashback_new_server_package_manifest`
- Status: `pass`
- Database target: `143.198.230.247:5433/halder`
- SQLite DB: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db`
- Snapshot: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/manaloom-knowledge/scripts/known_cards_canonical_snapshot.json`

## Stage Results

| Stage | Status | Evidence |
| --- | --- | --- |
| postgres_source_of_truth | `pass` | `{"validated_rows": 12}` |
| sqlite_hermes_cache | `pass` | `{"validated_rows": 12}` |
| canonical_snapshot_fallback | `pass` | `{"validated_cards": 12}` |
| runtime_get_card_effect | `pass` | `{"validated_cards": 12}` |
| battle_execution | `pass` | `{"events": 24, "scenarios": 12}` |

## Battle Execution

```json
{
  "event_count": 24,
  "results": [
    {
      "card_name": "Army of the Damned",
      "scenario": "Army of the Damned creates modeled creature tokens",
      "token_name": "Zombie Token",
      "token_tapped": true,
      "tokens_created": 13
    },
    {
      "card_name": "Beast Attack",
      "scenario": "Beast Attack creates modeled creature tokens",
      "token_name": "Beast Token",
      "token_tapped": false,
      "tokens_created": 1
    },
    {
      "card_name": "Call of the Herd",
      "scenario": "Call of the Herd creates modeled creature tokens",
      "token_name": "Elephant Token",
      "token_tapped": false,
      "tokens_created": 1
    },
    {
      "card_name": "Chatter of the Squirrel",
      "scenario": "Chatter of the Squirrel creates modeled creature tokens",
      "token_name": "Squirrel Token",
      "token_tapped": false,
      "tokens_created": 1
    },
    {
      "card_name": "Crush of Wurms",
      "scenario": "Crush of Wurms creates modeled creature tokens",
      "token_name": "Wurm Token",
      "token_tapped": false,
      "tokens_created": 3
    },
    {
      "card_name": "Elephant Ambush",
      "scenario": "Elephant Ambush creates modeled creature tokens",
      "token_name": "Elephant Token",
      "token_tapped": false,
      "tokens_created": 1
    },
    {
      "card_name": "Join the Dance",
      "scenario": "Join the Dance creates modeled creature tokens",
      "token_name": "Human Token",
      "token_tapped": false,
      "tokens_created": 2
    },
    {
      "card_name": "Lingering Souls",
      "scenario": "Lingering Souls creates modeled creature tokens",
      "token_name": "Spirit Token",
      "token_tapped": false,
      "tokens_created": 2
    },
    {
      "card_name": "Moan of the Unhallowed",
      "scenario": "Moan of the Unhallowed creates modeled creature tokens",
      "token_name": "Zombie Token",
      "token_tapped": false,
      "tokens_created": 2
    },
    {
      "card_name": "Reap the Seagraf",
      "scenario": "Reap the Seagraf creates modeled creature tokens",
      "token_name": "Zombie Token",
      "token_tapped": false,
      "tokens_created": 1
    },
    {
      "card_name": "Roar of the Wurm",
      "scenario": "Roar of the Wurm creates modeled creature tokens",
      "token_name": "Wurm Token",
      "token_tapped": false,
      "tokens_created": 1
    },
    {
      "card_name": "Shadowbeast Sighting",
      "scenario": "Shadowbeast Sighting creates modeled creature tokens",
      "token_name": "Beast Token",
      "token_tapped": false,
      "tokens_created": 1
    }
  ],
  "scenario_count": 12
}
```
