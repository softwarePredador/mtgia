# Battle Package End-to-End Validation

- Generated UTC: `2026-07-04T02:07:50.269694+00:00`
- Package ID: `pg378_xmage_target_keyword_constraints_wave_package_manifest`
- Status: `pass`
- Database target: `127.0.0.1:15432/halder`
- SQLite DB: `docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db`
- Snapshot: `docs/hermes-analysis/master_optimizer_reports/canonical_battle_card_rules_pg378_target_keyword_constraints_new_server.json`

## Stage Results

| Stage | Status | Evidence |
| --- | --- | --- |
| postgres_source_of_truth | `pass` | `{"validated_rows": 16}` |
| sqlite_hermes_cache | `pass` | `{"validated_rows": 16}` |
| canonical_snapshot_fallback | `pass` | `{"validated_cards": 16}` |
| runtime_get_card_effect | `pass` | `{"validated_cards": 16}` |
| battle_execution_no_override | `pass` | `{"events": 0, "scenarios": 0}` |

## Battle Execution

```json
{
  "event_count": 0,
  "results": [],
  "scenario_count": 0
}
```
