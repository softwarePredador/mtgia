# Battle Package End-to-End Validation

- Generated UTC: `2026-07-12T17:22:58.767527+00:00`
- Package ID: `pg834_add_counters_proliferate_new_server_manifest`
- Status: `pass`
- Database target: `127.0.0.1:15432/halder`
- SQLite DB: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db`
- Snapshot: `docs/hermes-analysis/master_optimizer_reports/pg834a_seed_hash_guard_after_apply_pg_sqlite_sync_tracked_snapshot.json`

## Stage Results

| Stage | Status | Evidence |
| --- | --- | --- |
| postgres_source_of_truth | `pass` | `{"validated_rows": 2}` |
| sqlite_hermes_cache | `pass` | `{"validated_rows": 2}` |
| canonical_snapshot_fallback | `pass` | `{"validated_cards": 2}` |
| runtime_get_card_effect | `pass` | `{"validated_cards": 2}` |
| battle_execution | `pass` | `{"events": 12, "scenarios": 2}` |

## Battle Execution

```json
{
  "event_count": 12,
  "results": [
    {
      "card_name": "Courage in Crisis",
      "counter_type": "+1/+1",
      "counters_after_resolution": 2,
      "opponent_charge_counters": 3,
      "opponent_poison_counters": 2,
      "scenario": "Courage in Crisis adds counters then proliferates",
      "target": "E2E Legal Counter Proliferate Target"
    },
    {
      "card_name": "Grim Affliction",
      "counter_type": "-1/-1",
      "counters_after_resolution": 2,
      "opponent_charge_counters": 3,
      "opponent_poison_counters": 2,
      "scenario": "Grim Affliction adds counters then proliferates",
      "target": "E2E Legal Counter Proliferate Target"
    }
  ],
  "scenario_count": 2
}
```
