# Battle Package End-to-End Validation

- Generated UTC: `2026-07-01T15:25:41.954931+00:00`
- Package ID: `pg313_xmage_permanent_activated_self_boost_wave_manifest`
- Status: `pass`
- Database target: `143.198.230.247:5433/halder`
- SQLite DB: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db`
- Snapshot: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/manaloom-knowledge/scripts/known_cards_canonical_snapshot.json`

## Stage Results

| Stage | Status | Evidence |
| --- | --- | --- |
| postgres_source_of_truth | `pass` | `{"validated_rows": 63}` |
| sqlite_hermes_cache | `pass` | `{"validated_rows": 63}` |
| canonical_snapshot_fallback | `pass` | `{"validated_cards": 63}` |
| runtime_get_card_effect | `pass` | `{"validated_cards": 63}` |
| battle_execution_no_override | `pass` | `{"events": 0, "scenarios": 0}` |

## Battle Execution

```json
{
  "event_count": 0,
  "results": [],
  "scenario_count": 0
}
```
