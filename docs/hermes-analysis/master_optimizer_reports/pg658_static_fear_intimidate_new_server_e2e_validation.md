# Battle Package End-to-End Validation

- Generated UTC: `2026-07-08T13:53:13.216409+00:00`
- Package ID: `pg658_static_fear_intimidate_new_server_package_manifest`
- Status: `pass`
- Database target: `127.0.0.1:15432/halder`
- SQLite DB: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db`
- Snapshot: `/tmp/pg658_static_fear_intimidate_new_server_canonical_snapshot.json`

## Stage Results

| Stage | Status | Evidence |
| --- | --- | --- |
| postgres_source_of_truth | `pass` | `{"validated_rows": 15}` |
| sqlite_hermes_cache | `pass` | `{"validated_rows": 15}` |
| canonical_snapshot_fallback | `pass` | `{"validated_cards": 15}` |
| runtime_get_card_effect | `pass` | `{"validated_cards": 15}` |
| battle_execution | `pass` | `{"events": 3, "scenarios": 2}` |

## Battle Execution

```json
{
  "event_count": 3,
  "results": [
    {
      "card_name": "Crowd of Cinders",
      "count": 2,
      "power": 2,
      "scenario": "Crowd of Cinders static count P/T recalculates",
      "toughness": 2
    },
    {
      "activation_limit_per_turn": 0,
      "card_name": "Undercity Shade",
      "power_delta": 1,
      "scenario": "Undercity Shade activates self boost ability",
      "source_power": 3,
      "source_toughness": 3,
      "toughness_delta": 1
    }
  ],
  "scenario_count": 2
}
```
