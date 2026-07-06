# Battle Package End-to-End Validation

- Generated UTC: `2026-07-06T02:00:42.666642+00:00`
- Package ID: `pg542_activated_token_discard_new_server_package_manifest`
- Status: `pass`
- Database target: `143.198.230.247:5433/halder`
- SQLite DB: `docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db`
- Snapshot: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/manaloom-knowledge/scripts/known_cards_canonical_snapshot.json`

## Stage Results

| Stage | Status | Evidence |
| --- | --- | --- |
| postgres_source_of_truth | `pass` | `{"validated_rows": 4}` |
| sqlite_hermes_cache | `pass` | `{"validated_rows": 4}` |
| canonical_snapshot_fallback | `pass` | `{"validated_cards": 4}` |
| runtime_get_card_effect | `pass` | `{"validated_cards": 4}` |
| battle_execution | `pass` | `{"events": 4, "scenarios": 4}` |

## Battle Execution

```json
{
  "event_count": 4,
  "results": [
    {
      "card_name": "Icatian Crier",
      "discard_target": "any_card",
      "discarded_count": 1,
      "scenario": "Icatian Crier activates token ability",
      "token_name": "Citizen Token",
      "tokens_created": 2
    },
    {
      "card_name": "Pegasus Refuge",
      "discard_target": "any_card",
      "discarded_count": 1,
      "scenario": "Pegasus Refuge activates token ability",
      "token_name": "Pegasus Token",
      "tokens_created": 1
    },
    {
      "card_name": "Sliversmith",
      "discard_target": "any_card",
      "discarded_count": 1,
      "scenario": "Sliversmith activates token ability",
      "token_name": "Metallic Sliver",
      "tokens_created": 1
    },
    {
      "card_name": "Thraben Standard Bearer",
      "discard_target": "any_card",
      "discarded_count": 1,
      "scenario": "Thraben Standard Bearer activates token ability",
      "token_name": "Human Soldier Token",
      "tokens_created": 1
    }
  ],
  "scenario_count": 4
}
```
