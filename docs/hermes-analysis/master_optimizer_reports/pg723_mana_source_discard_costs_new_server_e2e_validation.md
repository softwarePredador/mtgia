# Battle Package End-to-End Validation

- Generated UTC: `2026-07-10T22:07:07.867528+00:00`
- Package ID: `pg723_mana_source_discard_costs_new_server_package_manifest`
- Status: `pass`
- Database target: `127.0.0.1:15432/halder`
- SQLite DB: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db`
- Snapshot: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/manaloom-knowledge/scripts/known_cards_canonical_snapshot.json`

## Stage Results

| Stage | Status | Evidence |
| --- | --- | --- |
| postgres_source_of_truth | `pass` | `{"validated_rows": 6}` |
| sqlite_hermes_cache | `pass` | `{"validated_rows": 6}` |
| canonical_snapshot_fallback | `pass` | `{"validated_cards": 6}` |
| runtime_get_card_effect | `pass` | `{"validated_cards": 6}` |
| battle_execution | `pass` | `{"events": 9, "scenarios": 6}` |

## Battle Execution

```json
{
  "event_count": 9,
  "results": [
    {
      "activation_limit_per_turn": 0,
      "available_mana": 3,
      "card_name": "Bog Witch",
      "conditional_life_loss_by_color": {},
      "conditional_mana": 0,
      "discarded_count": 1,
      "life_after_refresh": 40,
      "life_paid": 0,
      "mana_activation_life_gain": 0,
      "scenario": "Bog Witch refreshes modeled mana source",
      "sources": 2,
      "tapped": true
    },
    {
      "activation_limit_per_turn": 0,
      "available_mana": 1,
      "card_name": "Bramble Familiar // Fetch Quest",
      "conditional_life_loss_by_color": {},
      "conditional_mana": 0,
      "discarded_count": 0,
      "life_after_refresh": 40,
      "life_paid": 0,
      "mana_activation_life_gain": 0,
      "scenario": "Bramble Familiar // Fetch Quest refreshes modeled mana source",
      "sources": 1,
      "tapped": true
    },
    {
      "activation_limit_per_turn": 0,
      "available_mana": 1,
      "card_name": "Izzet Keyrune",
      "conditional_life_loss_by_color": {},
      "conditional_mana": 1,
      "discarded_count": 0,
      "life_after_refresh": 40,
      "life_paid": 0,
      "mana_activation_life_gain": 0,
      "scenario": "Izzet Keyrune refreshes modeled mana source",
      "sources": 1,
      "tapped": true
    },
    {
      "activation_limit_per_turn": 0,
      "available_mana": 1,
      "card_name": "Network Terminal",
      "conditional_life_loss_by_color": {},
      "conditional_mana": 1,
      "discarded_count": 0,
      "life_after_refresh": 40,
      "life_paid": 0,
      "mana_activation_life_gain": 0,
      "scenario": "Network Terminal refreshes modeled mana source",
      "sources": 1,
      "tapped": true
    },
    {
      "activation_limit_per_turn": 0,
      "available_mana": 1,
      "card_name": "Skirge Familiar",
      "conditional_life_loss_by_color": {},
      "conditional_mana": 0,
      "discarded_count": 1,
      "life_after_refresh": 40,
      "life_paid": 0,
      "mana_activation_life_gain": 0,
      "scenario": "Skirge Familiar refreshes modeled mana source",
      "sources": 1,
      "tapped": false
    },
    {
      "activation_limit_per_turn": 0,
      "available_mana": 1,
      "card_name": "Starting Column",
      "conditional_life_loss_by_color": {},
      "conditional_mana": 1,
      "discarded_count": 0,
      "life_after_refresh": 40,
      "life_paid": 0,
      "mana_activation_life_gain": 0,
      "scenario": "Starting Column refreshes modeled mana source",
      "sources": 1,
      "tapped": true
    }
  ],
  "scenario_count": 6
}
```
