# Battle Package End-to-End Validation

- Generated UTC: `2026-07-07T06:02:42.390568+00:00`
- Package ID: `pg597_pay_life_mana_source_new_server_package_manifest`
- Status: `pass`
- Database target: `127.0.0.1:15432/halder`
- SQLite DB: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db`
- Snapshot: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/manaloom-knowledge/scripts/known_cards_canonical_snapshot.json`

## Stage Results

| Stage | Status | Evidence |
| --- | --- | --- |
| postgres_source_of_truth | `pass` | `{"validated_rows": 5}` |
| sqlite_hermes_cache | `pass` | `{"validated_rows": 5}` |
| canonical_snapshot_fallback | `pass` | `{"validated_cards": 5}` |
| runtime_get_card_effect | `pass` | `{"validated_cards": 5}` |
| battle_execution | `pass` | `{"events": 12, "scenarios": 5}` |

## Battle Execution

```json
{
  "event_count": 12,
  "results": [
    {
      "activation_limit_per_turn": 0,
      "available_mana": 1,
      "card_name": "Blightsoil Druid",
      "conditional_mana": 0,
      "life_after_refresh": 39,
      "life_paid": 1,
      "scenario": "Blightsoil Druid refreshes modeled mana source",
      "sources": 1,
      "tapped": true
    },
    {
      "activation_limit_per_turn": 0,
      "available_mana": 1,
      "card_name": "Blood Celebrant",
      "conditional_mana": 1,
      "life_after_refresh": 39,
      "life_paid": 1,
      "scenario": "Blood Celebrant refreshes modeled mana source",
      "sources": 2,
      "tapped": false
    },
    {
      "activation_limit_per_turn": 0,
      "available_mana": 1,
      "card_name": "Phyrexian Lens",
      "conditional_mana": 1,
      "life_after_refresh": 39,
      "life_paid": 1,
      "scenario": "Phyrexian Lens refreshes modeled mana source",
      "sources": 1,
      "tapped": true
    },
    {
      "activation_limit_per_turn": 0,
      "available_mana": 1,
      "card_name": "Standing Stones",
      "conditional_mana": 1,
      "life_after_refresh": 39,
      "life_paid": 1,
      "scenario": "Standing Stones refreshes modeled mana source",
      "sources": 2,
      "tapped": true
    },
    {
      "activation_limit_per_turn": 0,
      "available_mana": 1,
      "card_name": "Vesper Ghoul",
      "conditional_mana": 1,
      "life_after_refresh": 39,
      "life_paid": 1,
      "scenario": "Vesper Ghoul refreshes modeled mana source",
      "sources": 1,
      "tapped": true
    }
  ],
  "scenario_count": 5
}
```
