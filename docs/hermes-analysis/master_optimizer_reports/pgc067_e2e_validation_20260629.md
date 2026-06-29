# PGC067 Buyback Runtime Validation

- Generated UTC: `2026-06-29T11:33:57.735216+00:00`
- Package ID: `pgc067_buyback_runtime`
- Status: `pass`
- Database target: `143.198.230.247:5433/halder`
- SQLite DB: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db`
- Snapshot: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/manaloom-knowledge/scripts/known_cards_canonical_snapshot.json`

## Stage Results

| Stage | Status | Evidence |
| --- | --- | --- |
| postgres_source_of_truth | `pass` | `{"validated_rows": 1}` |
| sqlite_hermes_cache | `pass` | `{"validated_rows": 1}` |
| canonical_snapshot_fallback | `pass` | `{"validated_cards": 1}` |
| runtime_get_card_effect | `pass` | `{"validated_cards": 1}` |
| battle_execution_no_override | `pass` | `{"events": 5, "scenarios": 1}` |

## Battle Execution

```json
{
  "event_count": 5,
  "results": [
    {
      "buyback": {
        "buyback_cost": "{3}",
        "buyback_paid": true,
        "buyback_status": "runtime_executor_v1",
        "destination": "hand"
      },
      "card_name": "Reiterate",
      "copied_spell": "Targeted Removal",
      "copy_path": "response",
      "copy_spell_target": "Better Target",
      "copy_target_selection_status": "runtime_executor_v1",
      "scenario": "reiterate_response_copy_pays_buyback_returns_to_hand",
      "target_reassignment_performed": true
    }
  ],
  "scenario_count": 1
}
```
