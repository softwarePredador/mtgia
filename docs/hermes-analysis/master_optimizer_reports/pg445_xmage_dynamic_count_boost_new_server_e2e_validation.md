# Battle Package End-to-End Validation

- Generated UTC: `2026-07-04T22:56:14.089972+00:00`
- Package ID: `pg445_xmage_dynamic_count_boost_new_server_manifest`
- Status: `pass`
- Database target: `143.198.230.247:5433/halder`
- SQLite DB: `knowledge.db`
- Snapshot: `known_cards_canonical_snapshot.json`

## Stage Results

| Stage | Status | Evidence |
| --- | --- | --- |
| postgres_source_of_truth | `pass` | `{"validated_rows": 14}` |
| sqlite_hermes_cache | `pass` | `{"validated_rows": 14}` |
| canonical_snapshot_fallback | `pass` | `{"validated_cards": 14}` |
| runtime_get_card_effect | `pass` | `{"validated_cards": 14}` |
| battle_execution_no_override | `pass` | `{"events": 0, "scenarios": 0}` |

## Battle Execution

```json
{
  "event_count": 0,
  "results": [],
  "scenario_count": 0
}
```
