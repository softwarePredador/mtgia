# Battle Package End-to-End Validation

- Generated UTC: `2026-07-04T18:23:12.435483+00:00`
- Package ID: `pg420_xmage_static_basic_landwalk_new_server_manifest`
- Status: `pass`
- Database target: `127.0.0.1:15432/halder`
- SQLite DB: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db`
- Snapshot: `docs/hermes-analysis/master_optimizer_reports/pg420_xmage_static_basic_landwalk_new_server_canonical_fallback.json`

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
