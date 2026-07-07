# Battle Package End-to-End Validation

- Generated UTC: `2026-07-07T04:57:27.673440+00:00`
- Package ID: `pg594_limited_times_color_choice_mana_new_server_package_manifest`
- Status: `pass`
- Database target: `127.0.0.1:15432/halder`
- SQLite DB: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db`
- Snapshot: `docs/hermes-analysis/manaloom-knowledge/scripts/known_cards_canonical_snapshot.json`

## Stage Results

| Stage | Status | Evidence |
| --- | --- | --- |
| postgres_source_of_truth | `pass` | `{"validated_rows": 4}` |
| sqlite_hermes_cache | `pass` | `{"validated_rows": 4}` |
| canonical_snapshot_fallback | `pass` | `{"validated_cards": 4}` |
| runtime_get_card_effect | `pass` | `{"validated_cards": 4}` |
| battle_execution | `pass` | `{"events": 16, "scenarios": 4}` |

## Battle Execution

```json
{
  "event_count": 16,
  "results": [
    {
      "activation_limit_per_turn": 1,
      "available_mana": 1,
      "card_name": "Abzan Devotee",
      "conditional_mana": 1,
      "scenario": "Abzan Devotee refreshes modeled mana source",
      "sources": 2,
      "tapped": false
    },
    {
      "activation_limit_per_turn": 1,
      "available_mana": 1,
      "card_name": "Jeskai Devotee",
      "conditional_mana": 1,
      "scenario": "Jeskai Devotee refreshes modeled mana source",
      "sources": 2,
      "tapped": false
    },
    {
      "activation_limit_per_turn": 1,
      "available_mana": 1,
      "card_name": "Sultai Devotee",
      "conditional_mana": 1,
      "scenario": "Sultai Devotee refreshes modeled mana source",
      "sources": 2,
      "tapped": false
    },
    {
      "activation_limit_per_turn": 1,
      "available_mana": 1,
      "card_name": "Temur Devotee",
      "conditional_mana": 1,
      "scenario": "Temur Devotee refreshes modeled mana source",
      "sources": 2,
      "tapped": false
    }
  ],
  "scenario_count": 4
}
```
