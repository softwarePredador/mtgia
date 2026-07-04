# Battle Package End-to-End Validation

- Generated UTC: `2026-07-04T13:07:15.656209+00:00`
- Package ID: `pg406_tutor_to_hand_new_server_package_manifest`
- Status: `pass`
- Database target: `127.0.0.1:15432/halder`
- SQLite DB: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db`
- Snapshot: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/manaloom-knowledge/scripts/known_cards_canonical_snapshot.json`

## Stage Results

| Stage | Status | Evidence |
| --- | --- | --- |
| postgres_source_of_truth | `pass` | `{"validated_rows": 35}` |
| sqlite_hermes_cache | `pass` | `{"validated_rows": 35}` |
| canonical_snapshot_fallback | `pass` | `{"validated_cards": 35}` |
| runtime_get_card_effect | `pass` | `{"validated_cards": 35}` |
| battle_execution_no_override | `pass` | `{"events": 0, "scenarios": 0}` |

## Battle Execution

```json
{
  "event_count": 0,
  "results": [],
  "scenario_count": 0
}
```
