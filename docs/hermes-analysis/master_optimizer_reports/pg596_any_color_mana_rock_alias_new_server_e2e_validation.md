# Battle Package End-to-End Validation

- Generated UTC: `2026-07-07T05:31:51.601011+00:00`
- Package ID: `pg596_any_color_mana_rock_alias_new_server_package_manifest`
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
| battle_execution | `pass` | `{"events": 9, "scenarios": 5}` |

## Battle Execution

```json
{
  "event_count": 9,
  "results": [
    {
      "activation_limit_per_turn": 0,
      "available_mana": 1,
      "card_name": "Celestial Prism",
      "conditional_mana": 1,
      "scenario": "Celestial Prism refreshes modeled mana source",
      "sources": 3,
      "tapped": true
    },
    {
      "available_mana": 1,
      "card_name": "Chromatic Sphere",
      "conditional_mana": 1,
      "event": "self_sacrifice_mana_source_activated",
      "scenario": "Chromatic Sphere activates contextual sacrifice mana source",
      "source_sacrificed": true,
      "target_sacrificed": false
    },
    {
      "activation_limit_per_turn": 0,
      "available_mana": 1,
      "card_name": "Mana Cylix",
      "conditional_mana": 1,
      "scenario": "Mana Cylix refreshes modeled mana source",
      "sources": 2,
      "tapped": true
    },
    {
      "activation_limit_per_turn": 0,
      "available_mana": 1,
      "card_name": "Manalith",
      "conditional_mana": 1,
      "scenario": "Manalith refreshes modeled mana source",
      "sources": 1,
      "tapped": true
    },
    {
      "available_mana": 1,
      "card_name": "Phyrexian Altar",
      "conditional_mana": 1,
      "event": "target_sacrifice_mana_source_activated",
      "scenario": "Phyrexian Altar activates contextual sacrifice mana source",
      "source_sacrificed": false,
      "target_sacrificed": true
    }
  ],
  "scenario_count": 5
}
```
