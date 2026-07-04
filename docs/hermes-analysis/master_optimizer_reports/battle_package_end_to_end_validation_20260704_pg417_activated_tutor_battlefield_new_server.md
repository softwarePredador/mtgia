# Battle Package End-to-End Validation

- Generated UTC: `2026-07-04T17:30:25.098731+00:00`
- Package ID: `pg417_xmage_activated_tutor_battlefield_new_server_package_manifest`
- Status: `pass`
- Database target: `127.0.0.1:15432/halder`
- SQLite DB: `docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db`
- Snapshot: `docs/hermes-analysis/master_optimizer_reports/pg417_xmage_activated_tutor_battlefield_new_server_canonical_fallback.json`

## Stage Results

| Stage | Status | Evidence |
| --- | --- | --- |
| postgres_source_of_truth | `pass` | `{"validated_rows": 21}` |
| sqlite_hermes_cache | `pass` | `{"validated_rows": 21}` |
| canonical_snapshot_fallback | `pass` | `{"validated_cards": 21}` |
| runtime_get_card_effect | `pass` | `{"validated_cards": 21}` |
| battle_execution_no_override | `pass` | `{"events": 0, "scenarios": 0}` |

## Battle Execution

```json
{
  "event_count": 0,
  "results": [],
  "scenario_count": 0
}
```
