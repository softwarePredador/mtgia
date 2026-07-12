# Battle Package End-to-End Validation

- Generated UTC: `2026-07-12T13:08:29.441093+00:00`
- Package ID: `pg832_mana_spent_cast_trigger_new_server_package_manifest`
- Status: `pass`
- Database target: `127.0.0.1:15432/halder`
- SQLite DB: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db`
- Snapshot: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/manaloom-knowledge/scripts/known_cards_canonical_snapshot.json`

## Stage Results

| Stage | Status | Evidence |
| --- | --- | --- |
| postgres_source_of_truth | `pass` | `{"validated_rows": 3}` |
| sqlite_hermes_cache | `pass` | `{"validated_rows": 3}` |
| canonical_snapshot_fallback | `pass` | `{"validated_cards": 3}` |
| runtime_get_card_effect | `pass` | `{"validated_cards": 3}` |
| battle_execution | `pass` | `{"events": 12, "scenarios": 3}` |

## Battle Execution

```json
{
  "event_count": 12,
  "results": [
    {
      "available_mana_after_cast": 0,
      "card_name": "Animal Attendant",
      "cast_card": "E2E Non-Human Creature Spell",
      "cast_card_keywords": [],
      "cast_card_plus_one_counters": 1,
      "draw_count": 0,
      "life_gain": 0,
      "scenario": "Animal Attendant resolves mana-spent cast trigger",
      "scry_count": 0,
      "trigger_count": 1
    },
    {
      "available_mana_after_cast": 0,
      "card_name": "Biophagus",
      "cast_card": "E2E Creature Spell",
      "cast_card_keywords": [],
      "cast_card_plus_one_counters": 1,
      "draw_count": 0,
      "life_gain": 0,
      "scenario": "Biophagus resolves mana-spent cast trigger",
      "scry_count": 0,
      "trigger_count": 1
    },
    {
      "available_mana_after_cast": 0,
      "card_name": "Carnelian Orb of Dragonkind",
      "cast_card": "E2E Dragon Creature Spell",
      "cast_card_keywords": [
        "haste"
      ],
      "cast_card_plus_one_counters": 0,
      "draw_count": 0,
      "life_gain": 0,
      "scenario": "Carnelian Orb of Dragonkind resolves mana-spent cast trigger",
      "scry_count": 0,
      "trigger_count": 1
    }
  ],
  "scenario_count": 3
}
```
