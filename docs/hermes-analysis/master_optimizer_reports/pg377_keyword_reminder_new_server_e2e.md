# Battle Package End-to-End Validation

- Generated UTC: `2026-07-04T01:41:24.640057+00:00`
- Package ID: `pg377_xmage_keyword_reminder_wave_package_manifest`
- Status: `pass`
- Database target: `127.0.0.1:15432/halder`
- SQLite DB: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db`
- Snapshot: `docs/hermes-analysis/master_optimizer_reports/canonical_battle_card_rules_pg377_keyword_reminder_new_server.json`

## Stage Results

| Stage | Status | Evidence |
| --- | --- | --- |
| postgres_source_of_truth | `pass` | `{"validated_rows": 32}` |
| sqlite_hermes_cache | `pass` | `{"validated_rows": 32}` |
| canonical_snapshot_fallback | `pass` | `{"validated_cards": 32}` |
| runtime_get_card_effect | `pass` | `{"validated_cards": 32}` |
| battle_execution_no_override | `pass` | `{"events": 0, "scenarios": 0}` |

## Battle Execution

```json
{
  "event_count": 0,
  "results": [],
  "scenario_count": 0
}
```
