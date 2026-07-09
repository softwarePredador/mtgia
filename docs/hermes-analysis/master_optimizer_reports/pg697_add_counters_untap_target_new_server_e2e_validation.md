# Battle Package End-to-End Validation

- Generated UTC: `2026-07-09T06:58:05.993866+00:00`
- Package ID: `pg697_add_counters_untap_target_new_server_package_manifest`
- Status: `pass`
- Database target: `127.0.0.1:15432/halder`
- SQLite DB: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db`
- Snapshot: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/manaloom-knowledge/scripts/known_cards_canonical_snapshot.json`

## Stage Results

| Stage | Status | Evidence |
| --- | --- | --- |
| postgres_source_of_truth | `pass` | `{"validated_rows": 2}` |
| sqlite_hermes_cache | `pass` | `{"validated_rows": 2}` |
| canonical_snapshot_fallback | `pass` | `{"validated_cards": 2}` |
| runtime_get_card_effect | `pass` | `{"validated_cards": 2}` |
| battle_execution | `pass` | `{"events": 4, "scenarios": 2}` |

## Battle Execution

```json
{
  "event_count": 4,
  "results": [
    {
      "card_name": "Burst of Strength",
      "counter_type": "+1/+1",
      "counters_added": 1,
      "scenario": "Burst of Strength adds counters and untaps target creature",
      "target": "E2E Legal Counter Untap Target",
      "target_untapped": true
    },
    {
      "card_name": "Dragonscale Boon",
      "counter_type": "+1/+1",
      "counters_added": 2,
      "scenario": "Dragonscale Boon adds counters and untaps target creature",
      "target": "E2E Legal Counter Untap Target",
      "target_untapped": true
    }
  ],
  "scenario_count": 2
}
```
