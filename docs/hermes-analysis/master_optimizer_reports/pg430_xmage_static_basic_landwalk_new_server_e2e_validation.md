# Battle Package End-to-End Validation

- Generated UTC: `2026-07-04T20:51:13.294514+00:00`
- Package ID: `pg430_xmage_static_basic_landwalk_new_server_manifest`
- Status: `pass`
- Database target: `143.198.230.247:5433/halder`
- SQLite DB: `docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db`
- Snapshot: `docs/hermes-analysis/manaloom-knowledge/scripts/known_cards_canonical_snapshot.json`

## Stage Results

| Stage | Status | Evidence |
| --- | --- | --- |
| postgres_source_of_truth | `pass` | `{"validated_rows": 61}` |
| sqlite_hermes_cache | `pass` | `{"validated_rows": 61}` |
| canonical_snapshot_fallback | `pass` | `{"validated_cards": 61}` |
| runtime_get_card_effect | `pass` | `{"validated_cards": 61}` |
| battle_execution_no_override | `pass` | `{"events": 0, "scenarios": 0}` |

## Battle Execution

```json
{
  "event_count": 0,
  "results": [],
  "scenario_count": 0
}
```
