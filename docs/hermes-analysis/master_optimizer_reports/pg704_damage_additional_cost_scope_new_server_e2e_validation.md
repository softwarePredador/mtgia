# Battle Package End-to-End Validation

- Generated UTC: `2026-07-10T14:31:04.735353+00:00`
- Package ID: `pg704_damage_additional_cost_scope_new_server_package_manifest`
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
| battle_execution | `pass` | `{"events": 14, "scenarios": 3}` |

## Battle Execution

```json
{
  "event_count": 14,
  "results": [
    {
      "additional_cost": "return_land_to_hand",
      "card_name": "Devour in Flames",
      "controller_life": 10,
      "controller_treasures": 0,
      "damage": 5,
      "life_gained": 0,
      "opponent_life": 20,
      "scenario": "Devour in Flames deals fixed target damage",
      "shuffled_self_into_library": false,
      "target": "E2E Fixed Damage Legal Target",
      "treasures_created": 0
    },
    {
      "additional_cost": "sacrifice_creature_or_enchantment",
      "card_name": "Final Flare",
      "controller_life": 10,
      "controller_treasures": 0,
      "damage": 5,
      "life_gained": 0,
      "opponent_life": 20,
      "scenario": "Final Flare deals fixed target damage",
      "shuffled_self_into_library": false,
      "target": "E2E Fixed Damage Legal Target",
      "treasures_created": 0
    },
    {
      "additional_cost": "sacrifice_creature_or_planeswalker",
      "card_name": "Heartfire",
      "controller_life": 10,
      "controller_treasures": 0,
      "damage": 4,
      "life_gained": 0,
      "opponent_life": 20,
      "scenario": "Heartfire deals fixed target damage",
      "shuffled_self_into_library": false,
      "target": "E2E Fixed Damage Legal Target",
      "treasures_created": 0
    }
  ],
  "scenario_count": 3
}
```
