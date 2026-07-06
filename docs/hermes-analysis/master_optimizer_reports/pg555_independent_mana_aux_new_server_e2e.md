# Battle Package End-to-End Validation

- Generated UTC: `2026-07-06T06:30:51.621058+00:00`
- Package ID: `pg555_independent_mana_aux_new_server_package_manifest`
- Status: `pass`
- Database target: `143.198.230.247:5433/halder`
- SQLite DB: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db`
- Snapshot: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/manaloom-knowledge/scripts/known_cards_canonical_snapshot.json`

## Stage Results

| Stage | Status | Evidence |
| --- | --- | --- |
| postgres_source_of_truth | `pass` | `{"validated_rows": 5}` |
| sqlite_hermes_cache | `pass` | `{"validated_rows": 5}` |
| canonical_snapshot_fallback | `pass` | `{"validated_cards": 5}` |
| runtime_get_card_effect | `pass` | `{"validated_cards": 5}` |
| battle_execution | `pass` | `{"events": 5, "scenarios": 5}` |

## Battle Execution

```json
{
  "event_count": 5,
  "results": [
    {
      "available_mana": 1,
      "card_name": "Atzocan Seer",
      "conditional_mana": 1,
      "scenario": "Atzocan Seer refreshes modeled mana source",
      "sources": 1,
      "tapped": true
    },
    {
      "available_mana": 1,
      "card_name": "Blitzball",
      "conditional_mana": 1,
      "scenario": "Blitzball refreshes modeled mana source",
      "sources": 1,
      "tapped": true
    },
    {
      "available_mana": 1,
      "card_name": "Infernal Idol",
      "conditional_mana": 0,
      "scenario": "Infernal Idol refreshes modeled mana source",
      "sources": 1,
      "tapped": true
    },
    {
      "available_mana": 1,
      "card_name": "Sunset Strikemaster",
      "conditional_mana": 0,
      "scenario": "Sunset Strikemaster refreshes modeled mana source",
      "sources": 1,
      "tapped": true
    },
    {
      "available_mana": 1,
      "card_name": "Unstable Obelisk",
      "conditional_mana": 0,
      "scenario": "Unstable Obelisk refreshes modeled mana source",
      "sources": 1,
      "tapped": true
    }
  ],
  "scenario_count": 5
}
```
