# Battle Package End-to-End Validation

- Generated UTC: `2026-07-12T02:04:43.750670+00:00`
- Package ID: `pg800_static_count_base_subtypes_new_server_package_manifest`
- Status: `pass`
- Database target: `127.0.0.1:15432/halder`
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
      "card_name": "Aysen Crusader",
      "count": 2,
      "power": 4,
      "scenario": "Aysen Crusader static count P/T recalculates",
      "toughness": 4
    }
  ],
  "scenario_count": 1
}
```
