# Battle Package End-to-End Validation

- Generated UTC: `2026-07-05T05:39:36.135156+00:00`
- Package ID: `xmage_pg484_board_wipe_extended_new_server_manifest`
- Status: `pass`
- Database target: `143.198.230.247:5433/halder`
- SQLite DB: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db`
- Snapshot: `docs/hermes-analysis/master_optimizer_reports/card_intelligence_snapshot_pg484_board_wipe_extended_new_server.json`

## Stage Results

| Stage | Status | Evidence |
| --- | --- | --- |
| postgres_source_of_truth | `pass` | `{"validated_rows": 26}` |
| sqlite_hermes_cache | `pass` | `{"validated_rows": 26}` |
| canonical_snapshot_fallback | `pass` | `{"validated_cards": 26}` |
| runtime_get_card_effect | `pass` | `{"validated_cards": 26}` |
| battle_execution_no_override | `pass` | `{"events": 0, "scenarios": 0}` |

## Battle Execution

```json
{
  "event_count": 0,
  "results": [],
  "scenario_count": 0
}
```
