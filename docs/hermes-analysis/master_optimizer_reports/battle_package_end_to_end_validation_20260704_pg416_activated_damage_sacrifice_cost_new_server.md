# Battle Package End-to-End Validation

- Generated UTC: `2026-07-04T17:04:09.843113+00:00`
- Package ID: `pg416_xmage_activated_damage_sacrifice_cost_new_server_package_manifest`
- Status: `pass`
- Database target: `127.0.0.1:15432/halder`
- SQLite DB: `docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db`
- Snapshot: `docs/hermes-analysis/manaloom-knowledge/scripts/known_cards_canonical_snapshot.json`

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
