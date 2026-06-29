# PGC061 Basic Land Compensation Runtime Validation

- Generated UTC: `2026-06-29T09:50:11.192023+00:00`
- Package ID: `pgc061_basic_land_compensation_runtime`
- Status: `pass`
- Database target: `143.198.230.247:5433/halder`
- SQLite DB: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db`
- Snapshot: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/manaloom-knowledge/scripts/known_cards_canonical_snapshot.json`

## Stage Results

| Stage | Status | Evidence |
| --- | --- | --- |
| postgres_source_of_truth | `pass` | `{"validated_rows": 2}` |
| sqlite_hermes_cache | `pass` | `{"validated_rows": 2}` |
| canonical_snapshot_fallback | `pass` | `{"validated_cards": 2}` |
| runtime_get_card_effect | `pass` | `{"validated_cards": 2}` |
| battle_execution_no_override | `pass` | `{"events": 8, "scenarios": 2}` |

## Battle Execution

```json
{
  "event_count": 8,
  "results": [
    {
      "basic_land_tapped": true,
      "basic_lands_moved": 1,
      "card_name": "Erode",
      "scenario": "erode_planeswalker_basic_land_compensation",
      "target_removed": "Test Walker"
    },
    {
      "basic_land_tapped": true,
      "basic_lands_moved": 1,
      "card_name": "Sundering Eruption // Volcanic Fissure",
      "scenario": "sundering_land_basic_land_compensation",
      "target_removed": "Ancient Tomb"
    }
  ],
  "scenario_count": 2
}
```
