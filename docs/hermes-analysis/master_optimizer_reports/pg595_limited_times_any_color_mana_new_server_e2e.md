# Battle Package End-to-End Validation

- Generated UTC: `2026-07-07T05:11:57.240047+00:00`
- Package ID: `pg595_limited_times_any_color_mana_new_server_package_manifest`
- Status: `pass`
- Database target: `127.0.0.1:15432/halder`
- SQLite DB: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db`
- Snapshot: `docs/hermes-analysis/manaloom-knowledge/scripts/known_cards_canonical_snapshot.json`

## Stage Results

| Stage | Status | Evidence |
| --- | --- | --- |
| postgres_source_of_truth | `pass` | `{"validated_rows": 7}` |
| sqlite_hermes_cache | `pass` | `{"validated_rows": 7}` |
| canonical_snapshot_fallback | `pass` | `{"validated_cards": 7}` |
| runtime_get_card_effect | `pass` | `{"validated_cards": 7}` |
| battle_execution | `pass` | `{"events": 28, "scenarios": 7}` |

## Battle Execution

```json
{
  "event_count": 28,
  "results": [
    {
      "activation_limit_per_turn": 1,
      "available_mana": 1,
      "card_name": "Barrels of Blasting Jelly",
      "conditional_mana": 1,
      "scenario": "Barrels of Blasting Jelly refreshes modeled mana source",
      "sources": 2,
      "tapped": false
    },
    {
      "activation_limit_per_turn": 1,
      "available_mana": 1,
      "card_name": "Foraging Wickermaw",
      "conditional_mana": 1,
      "scenario": "Foraging Wickermaw refreshes modeled mana source",
      "sources": 2,
      "tapped": false
    },
    {
      "activation_limit_per_turn": 1,
      "available_mana": 1,
      "card_name": "Gravestone Strider",
      "conditional_mana": 1,
      "scenario": "Gravestone Strider refreshes modeled mana source",
      "sources": 2,
      "tapped": false
    },
    {
      "activation_limit_per_turn": 1,
      "available_mana": 1,
      "card_name": "Salvaged Manaworker",
      "conditional_mana": 1,
      "scenario": "Salvaged Manaworker refreshes modeled mana source",
      "sources": 2,
      "tapped": false
    },
    {
      "activation_limit_per_turn": 1,
      "available_mana": 1,
      "card_name": "Scarecrow Guide",
      "conditional_mana": 1,
      "scenario": "Scarecrow Guide refreshes modeled mana source",
      "sources": 2,
      "tapped": false
    },
    {
      "activation_limit_per_turn": 1,
      "available_mana": 1,
      "card_name": "Shire Scarecrow",
      "conditional_mana": 1,
      "scenario": "Shire Scarecrow refreshes modeled mana source",
      "sources": 2,
      "tapped": false
    },
    {
      "activation_limit_per_turn": 1,
      "available_mana": 1,
      "card_name": "Three Tree Mascot",
      "conditional_mana": 1,
      "scenario": "Three Tree Mascot refreshes modeled mana source",
      "sources": 2,
      "tapped": false
    }
  ],
  "scenario_count": 7
}
```
