# Battle Package End-to-End Validation

- Generated UTC: `2026-07-01T16:01:48.405251+00:00`
- Package ID: `pg315_xmage_permanent_activated_target_boost_wave_manifest`
- Status: `pass`
- Database target: `143.198.230.247:5433/halder`
- SQLite DB: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db`
- Snapshot: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/manaloom-knowledge/scripts/known_cards_canonical_snapshot.json`

## Stage Results

| Stage | Status | Evidence |
| --- | --- | --- |
| postgres_source_of_truth | `pass` | `{"validated_rows": 19}` |
| sqlite_hermes_cache | `pass` | `{"validated_rows": 19}` |
| canonical_snapshot_fallback | `pass` | `{"validated_cards": 19}` |
| runtime_get_card_effect | `pass` | `{"validated_cards": 19}` |
| battle_execution_no_override | `pass` | `{"events": 0, "scenarios": 0}` |

## Battle Execution

```json
{
  "event_count": 0,
  "results": [],
  "scenario_count": 0
}
```
