# PGC062 Conditional ETB Lands Runtime Validation

- Generated UTC: `2026-06-29T10:09:15.047645+00:00`
- Package ID: `pgc062_conditional_etb_lands_runtime`
- Status: `pass`
- Database target: `143.198.230.247:5433/halder`
- SQLite DB: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db`
- Snapshot: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/manaloom-knowledge/scripts/known_cards_canonical_snapshot.json`

## Stage Results

| Stage | Status | Evidence |
| --- | --- | --- |
| postgres_source_of_truth | `pass` | `{"validated_rows": 3}` |
| sqlite_hermes_cache | `pass` | `{"validated_rows": 3}` |
| canonical_snapshot_fallback | `pass` | `{"validated_cards": 3}` |
| runtime_get_card_effect | `pass` | `{"validated_cards": 3}` |
| battle_execution_no_override | `pass` | `{"events": 6, "scenarios": 6}` |

## Battle Execution

```json
{
  "event_count": 6,
  "results": [
    {
      "actual_tapped": true,
      "card_name": "Clifftop Retreat",
      "expected_tapped": true,
      "land_count": 0,
      "reason": "missing_required_land_subtype",
      "scenario": "clifftop_tapped_without_plains_or_mountain"
    },
    {
      "actual_tapped": false,
      "card_name": "Clifftop Retreat",
      "expected_tapped": false,
      "land_count": 1,
      "reason": "controlled_required_land_subtype",
      "scenario": "clifftop_untapped_with_plains"
    },
    {
      "actual_tapped": false,
      "card_name": "Inspiring Vantage",
      "expected_tapped": false,
      "land_count": 2,
      "reason": "land_count_below_tapped_threshold",
      "scenario": "inspiring_untapped_with_two_other_lands"
    },
    {
      "actual_tapped": true,
      "card_name": "Inspiring Vantage",
      "expected_tapped": true,
      "land_count": 3,
      "reason": "land_count_at_or_above_tapped_threshold",
      "scenario": "inspiring_tapped_with_three_other_lands"
    },
    {
      "actual_tapped": true,
      "card_name": "Sundown Pass",
      "expected_tapped": true,
      "land_count": 1,
      "reason": "land_count_below_untapped_threshold",
      "scenario": "sundown_tapped_with_one_other_land"
    },
    {
      "actual_tapped": false,
      "card_name": "Sundown Pass",
      "expected_tapped": false,
      "land_count": 2,
      "reason": "land_count_met_untapped_threshold",
      "scenario": "sundown_untapped_with_two_other_lands"
    }
  ],
  "scenario_count": 6
}
```
