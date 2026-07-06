# Battle Package End-to-End Validation

- Generated UTC: `2026-07-06T03:09:06.443179+00:00`
- Package ID: `pg545_token_prowess_new_server_package_manifest`
- Status: `pass`
- Database target: `143.198.230.247:5433/halder`
- SQLite DB: `docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db`
- Snapshot: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/manaloom-knowledge/scripts/known_cards_canonical_snapshot.json`

## Stage Results

| Stage | Status | Evidence |
| --- | --- | --- |
| postgres_source_of_truth | `pass` | `{"validated_rows": 1}` |
| sqlite_hermes_cache | `pass` | `{"validated_rows": 1}` |
| canonical_snapshot_fallback | `pass` | `{"validated_cards": 1}` |
| runtime_get_card_effect | `pass` | `{"validated_cards": 1}` |
| battle_execution | `pass` | `{"events": 2, "scenarios": 1}` |

## Battle Execution

```json
{
  "event_count": 2,
  "results": [
    {
      "card_name": "Goblin Wizardry",
      "scenario": "Goblin Wizardry creates modeled creature tokens",
      "token_name": "Goblin Wizard Token",
      "token_tapped": false,
      "tokens_created": 2
    }
  ],
  "scenario_count": 1
}
```
