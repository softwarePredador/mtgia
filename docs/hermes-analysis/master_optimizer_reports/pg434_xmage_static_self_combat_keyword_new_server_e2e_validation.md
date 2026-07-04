# Battle Package End-to-End Validation

- Generated UTC: `2026-07-04T21:25:10.356078+00:00`
- Package ID: `pg434_xmage_static_self_combat_keyword_new_server_manifest`
- Status: `pass`
- Database target: `143.198.230.247:5433/halder`
- SQLite DB: `docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db`
- Snapshot: `docs/hermes-analysis/manaloom-knowledge/scripts/known_cards_canonical_snapshot.json`

## Stage Results

| Stage | Status | Evidence |
| --- | --- | --- |
| postgres_source_of_truth | `pass` | `{"validated_rows": 33}` |
| sqlite_hermes_cache | `pass` | `{"validated_rows": 33}` |
| canonical_snapshot_fallback | `pass` | `{"validated_cards": 33}` |
| runtime_get_card_effect | `pass` | `{"validated_cards": 33}` |
| battle_execution_no_override | `pass` | `{"events": 0, "scenarios": 0}` |

## Battle Execution

```json
{
  "event_count": 0,
  "results": [],
  "scenario_count": 0
}
```
