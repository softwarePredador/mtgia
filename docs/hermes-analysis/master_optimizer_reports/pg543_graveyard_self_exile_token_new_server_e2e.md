# Battle Package End-to-End Validation

- Generated UTC: `2026-07-06T02:24:27.405645+00:00`
- Package ID: `pg543_graveyard_self_exile_token_new_server_package_manifest`
- Status: `pass`
- Database target: `143.198.230.247:5433/halder`
- SQLite DB: `docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db`
- Snapshot: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/manaloom-knowledge/scripts/known_cards_canonical_snapshot.json`

## Stage Results

| Stage | Status | Evidence |
| --- | --- | --- |
| postgres_source_of_truth | `pass` | `{"validated_rows": 2}` |
| sqlite_hermes_cache | `pass` | `{"validated_rows": 2}` |
| canonical_snapshot_fallback | `pass` | `{"validated_cards": 2}` |
| runtime_get_card_effect | `pass` | `{"validated_cards": 2}` |
| battle_execution | `pass` | `{"events": 2, "scenarios": 2}` |

## Battle Execution

```json
{
  "event_count": 2,
  "results": [
    {
      "card_name": "Eternal Student",
      "discard_target": null,
      "discarded_count": 0,
      "exiled_source_from_graveyard": true,
      "scenario": "Eternal Student activates token ability",
      "token_name": "Inkling Token",
      "tokens_created": 2
    },
    {
      "card_name": "Illustrious Historian",
      "discard_target": null,
      "discarded_count": 0,
      "exiled_source_from_graveyard": true,
      "scenario": "Illustrious Historian activates token ability",
      "token_name": "Spirit Token",
      "tokens_created": 1
    }
  ],
  "scenario_count": 2
}
```
