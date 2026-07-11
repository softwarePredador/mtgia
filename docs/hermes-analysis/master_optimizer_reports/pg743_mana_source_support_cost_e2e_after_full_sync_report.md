# Battle Package End-to-End Validation

- Generated UTC: `2026-07-11T05:56:03.830611+00:00`
- Package ID: `pg743_mana_source_support_cost_package_manifest`
- Status: `pass`
- Database target: `127.0.0.1:15432/halder`
- SQLite DB: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db`
- Snapshot: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/manaloom-knowledge/scripts/known_cards_canonical_snapshot.json`

## Stage Results

| Stage | Status | Evidence |
| --- | --- | --- |
| postgres_source_of_truth | `pass` | `{"validated_rows": 4}` |
| sqlite_hermes_cache | `pass` | `{"validated_rows": 4}` |
| canonical_snapshot_fallback | `pass` | `{"validated_cards": 4}` |
| runtime_get_card_effect | `pass` | `{"validated_cards": 4}` |
| battle_execution | `pass` | `{"events": 8, "scenarios": 4}` |

## Battle Execution

```json
{
  "event_count": 8,
  "results": [
    {
      "activation_limit_per_turn": 0,
      "available_mana": 1,
      "card_name": "Citanul Stalwart",
      "conditional_life_loss_by_color": {},
      "conditional_mana": 1,
      "discarded_count": 0,
      "life_after_refresh": 40,
      "life_paid": 0,
      "mana_activation_life_gain": 0,
      "scenario": "Citanul Stalwart refreshes modeled mana source",
      "sources": 1,
      "support_tapped_count": 1,
      "tapped": true
    },
    {
      "activation_limit_per_turn": 0,
      "available_mana": 1,
      "card_name": "Jaspera Sentinel",
      "conditional_life_loss_by_color": {},
      "conditional_mana": 1,
      "discarded_count": 0,
      "life_after_refresh": 40,
      "life_paid": 0,
      "mana_activation_life_gain": 0,
      "scenario": "Jaspera Sentinel refreshes modeled mana source",
      "sources": 1,
      "support_tapped_count": 1,
      "tapped": true
    },
    {
      "activation_limit_per_turn": 0,
      "available_mana": 1,
      "card_name": "Loam Dryad",
      "conditional_life_loss_by_color": {},
      "conditional_mana": 1,
      "discarded_count": 0,
      "life_after_refresh": 40,
      "life_paid": 0,
      "mana_activation_life_gain": 0,
      "scenario": "Loam Dryad refreshes modeled mana source",
      "sources": 1,
      "support_tapped_count": 1,
      "tapped": true
    },
    {
      "activation_limit_per_turn": 0,
      "available_mana": 1,
      "card_name": "Saruli Caretaker",
      "conditional_life_loss_by_color": {},
      "conditional_mana": 1,
      "discarded_count": 0,
      "life_after_refresh": 40,
      "life_paid": 0,
      "mana_activation_life_gain": 0,
      "scenario": "Saruli Caretaker refreshes modeled mana source",
      "sources": 1,
      "support_tapped_count": 1,
      "tapped": true
    }
  ],
  "scenario_count": 4
}
```
