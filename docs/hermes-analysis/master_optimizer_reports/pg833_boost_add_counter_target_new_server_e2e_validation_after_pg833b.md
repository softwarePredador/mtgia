# Battle Package End-to-End Validation

- Generated UTC: `2026-07-12T13:36:38.519799+00:00`
- Package ID: `pg833_boost_add_counter_target_new_server_package_manifest`
- Status: `pass`
- Database target: `127.0.0.1:15432/halder`
- SQLite DB: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db`
- Snapshot: `docs/hermes-analysis/master_optimizer_reports/pg833b_trusted_rule_oracle_hash_backfill_new_server_pg_to_sqlite_sync_tracked_snapshot.json`

## Stage Results

| Stage | Status | Evidence |
| --- | --- | --- |
| postgres_source_of_truth | `pass` | `{"validated_rows": 4}` |
| sqlite_hermes_cache | `pass` | `{"validated_rows": 4}` |
| canonical_snapshot_fallback | `pass` | `{"validated_cards": 4}` |
| runtime_get_card_effect | `pass` | `{"validated_cards": 4}` |
| battle_execution | `pass` | `{"events": 24, "scenarios": 4}` |

## Battle Execution

```json
{
  "event_count": 24,
  "results": [
    {
      "card_name": "Free from Flesh",
      "counter_type": "oil",
      "counters_added": 2,
      "power_delta": 2,
      "scenario": "Free from Flesh boosts target creature and adds a counter",
      "target": "E2E Legal Boost Counter Target",
      "toughness_delta": 2
    },
    {
      "card_name": "Fully Grown",
      "counter_type": "trample",
      "counters_added": 1,
      "power_delta": 3,
      "scenario": "Fully Grown boosts target creature and adds a counter",
      "target": "E2E Legal Boost Counter Target",
      "toughness_delta": 3
    },
    {
      "card_name": "Heightened Reflexes",
      "counter_type": "first_strike",
      "counters_added": 1,
      "power_delta": 1,
      "scenario": "Heightened Reflexes boosts target creature and adds a counter",
      "target": "E2E Legal Boost Counter Target",
      "toughness_delta": 0
    },
    {
      "card_name": "Spontaneous Flight",
      "counter_type": "flying",
      "counters_added": 1,
      "power_delta": 2,
      "scenario": "Spontaneous Flight boosts target creature and adds a counter",
      "target": "E2E Legal Boost Counter Target",
      "toughness_delta": 2
    }
  ],
  "scenario_count": 4
}
```
