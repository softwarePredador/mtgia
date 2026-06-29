# PGC066 Cant Block Runtime Validation

- Generated UTC: `2026-06-29T11:13:40.035353+00:00`
- Package ID: `pgc066_cant_block_runtime`
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
| battle_execution_no_override | `pass` | `{"events": 9, "scenarios": 2}` |

## Battle Execution

```json
{
  "event_count": 9,
  "results": [
    {
      "affected": [
        "Large Ground Blocker"
      ],
      "blockers": [
        "Small Ground Blocker"
      ],
      "cant_block_mode_status": "runtime_executor_v1",
      "card_name": "Untimely Malfunction",
      "scenario": "untimely_malfunction_target_creature_cant_block"
    },
    {
      "blockers": [
        "Flying Blocker"
      ],
      "cant_block_mode_status": "runtime_executor_v1",
      "cant_block_target_restriction": "creatures_without_flying",
      "card_name": "Sundering Eruption // Volcanic Fissure",
      "scenario": "sundering_eruption_nonfliers_cant_block_rider",
      "target_removed": "Target Land"
    }
  ],
  "scenario_count": 2
}
```
