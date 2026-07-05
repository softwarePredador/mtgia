# Battle Package End-to-End Validation

- Generated UTC: `2026-07-05T03:43:18.069291+00:00`
- Package ID: `pg479_look_library_pick_bottom_new_server_manifest`
- Status: `pass`
- Database target: `143.198.230.247:5433/halder`
- SQLite DB: `knowledge.db`
- Snapshot: `known_cards_canonical_snapshot.json`

## Stage Results

| Stage | Status | Evidence |
| --- | --- | --- |
| postgres_source_of_truth | `pass` | `{"validated_rows": 15}` |
| sqlite_hermes_cache | `pass` | `{"validated_rows": 15}` |
| canonical_snapshot_fallback | `pass` | `{"validated_cards": 15}` |
| runtime_get_card_effect | `pass` | `{"validated_cards": 15}` |
| battle_execution_no_override | `pass` | `{"events": 0, "scenarios": 0}` |

## Battle Execution

```json
{
  "event_count": 0,
  "results": [],
  "scenario_count": 0
}
```
