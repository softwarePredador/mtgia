# Battle Package End-to-End Validation

- Generated UTC: `2026-07-12T22:07:04.201123+00:00`
- Package ID: `pg847_golden_throne_new_server_manifest`
- Status: `pass`
- Database target: `127.0.0.1:15432/halder`
- SQLite DB: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db`
- Snapshot: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/manaloom-knowledge/scripts/known_cards_canonical_snapshot.json`

## Stage Results

| Stage | Status | Evidence |
| --- | --- | --- |
| postgres_source_of_truth | `pass` | `{"validated_rows": 1}` |
| sqlite_hermes_cache | `pass` | `{"validated_rows": 1}` |
| canonical_snapshot_fallback | `pass` | `{"validated_cards": 1}` |
| runtime_get_card_effect | `pass` | `{"validated_cards": 1}` |
| battle_execution | `pass` | `{"events": 3, "scenarios": 2}` |

## Battle Execution

```json
{
  "event_count": 3,
  "results": [
    {
      "card_name": "The Golden Throne",
      "destination": "exile",
      "life_after": 1,
      "scenario": "The Golden Throne replaces a loss by exiling itself"
    },
    {
      "available_mana": 3,
      "card_name": "The Golden Throne",
      "conditional_mana": 3,
      "event": "target_sacrifice_mana_source_activated",
      "scenario": "The Golden Throne activates contextual sacrifice mana source",
      "source_sacrificed": false,
      "target_sacrificed": true
    }
  ],
  "scenario_count": 2
}
```
