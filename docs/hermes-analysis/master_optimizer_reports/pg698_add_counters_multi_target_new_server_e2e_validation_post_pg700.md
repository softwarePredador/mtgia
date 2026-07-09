# Battle Package End-to-End Validation

- Generated UTC: `2026-07-09T07:28:34.749578+00:00`
- Package ID: `pg698_add_counters_multi_target_new_server_package_manifest`
- Status: `pass`
- Database target: `127.0.0.1:15432/halder`
- SQLite DB: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db`
- Snapshot: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/manaloom-knowledge/scripts/known_cards_canonical_snapshot.json`

## Stage Results

| Stage | Status | Evidence |
| --- | --- | --- |
| postgres_source_of_truth | `pass` | `{"validated_rows": 3}` |
| sqlite_hermes_cache | `pass` | `{"validated_rows": 3}` |
| canonical_snapshot_fallback | `pass` | `{"validated_cards": 3}` |
| runtime_get_card_effect | `pass` | `{"validated_cards": 3}` |
| battle_execution | `pass` | `{"events": 11, "scenarios": 3}` |

## Battle Execution

```json
{
  "event_count": 11,
  "results": [
    {
      "card_name": "Gird for Battle",
      "counter_type": "+1/+1",
      "counters_added_each": 1,
      "scenario": "Gird for Battle adds counters to target creature spell",
      "target_count": 2,
      "targets": [
        "E2E Legal Counter Target 1",
        "E2E Legal Counter Target 2"
      ]
    },
    {
      "card_name": "Leo's Guidance",
      "counter_type": "+1/+1",
      "counters_added_each": 1,
      "scenario": "Leo's Guidance adds counters and untaps target creature",
      "target_count": 3,
      "targets": [
        "E2E Legal Counter Untap Target 1",
        "E2E Legal Counter Untap Target 2",
        "E2E Legal Counter Untap Target 3"
      ],
      "targets_untapped_count": 3
    },
    {
      "card_name": "Reap What Is Sown",
      "counter_type": "+1/+1",
      "counters_added_each": 1,
      "scenario": "Reap What Is Sown adds counters to target creature spell",
      "target_count": 3,
      "targets": [
        "E2E Legal Counter Target 1",
        "E2E Legal Counter Target 2",
        "E2E Legal Counter Target 3"
      ]
    }
  ],
  "scenario_count": 3
}
```
