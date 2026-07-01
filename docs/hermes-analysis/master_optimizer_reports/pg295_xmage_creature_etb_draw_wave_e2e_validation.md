# Battle Package End-to-End Validation

- Generated UTC: `2026-07-01T10:13:44.658680+00:00`
- Package ID: `pg295_xmage_creature_etb_draw_wave_manifest`
- Status: `pass`
- Database target: `143.198.230.247:5433/halder`
- SQLite DB: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db`
- Snapshot: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/manaloom-knowledge/scripts/known_cards_canonical_snapshot.json`

## Stage Results

| Stage | Status | Evidence |
| --- | --- | --- |
| postgres_source_of_truth | `pass` | `{"validated_rows": 28}` |
| sqlite_hermes_cache | `pass` | `{"validated_rows": 28}` |
| canonical_snapshot_fallback | `pass` | `{"validated_cards": 28}` |
| runtime_get_card_effect | `pass` | `{"validated_cards": 28}` |
| battle_execution_no_override | `pass` | `{"events": 0, "scenarios": 0}` |

## Battle Execution

```json
{
  "event_count": 0,
  "results": [],
  "scenario_count": 0
}
```
