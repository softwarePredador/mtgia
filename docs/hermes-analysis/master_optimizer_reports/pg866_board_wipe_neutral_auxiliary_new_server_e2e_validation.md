# Battle Package End-to-End Validation

- Generated UTC: `2026-07-13T05:57:02.081448+00:00`
- Package ID: `pg866_board_wipe_neutral_auxiliary_new_server_manifest`
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
| battle_execution | `pass` | `{"events": 24, "scenarios": 5}` |

## Battle Execution

```json
{
  "event_count": 24,
  "results": [
    {
      "card_name": "Akroma's Vengeance",
      "destroy_card_types": [
        "artifact",
        "creature",
        "enchantment"
      ],
      "destroy_controller": "any",
      "destroyed": 6,
      "expected_destroyed": 6
    },
    {
      "card_name": "Fuel the Flames",
      "creatures_destroyed": 2,
      "damage": 2,
      "damage_players": false,
      "damage_scope": "each_creature",
      "players_damaged": 0
    },
    {
      "card_name": "Hush",
      "destroy_card_types": [
        "enchantment"
      ],
      "destroy_controller": "any",
      "destroyed": 2,
      "expected_destroyed": 2
    },
    {
      "card_name": "Starstorm",
      "creatures_destroyed": 2,
      "damage": 3,
      "damage_players": false,
      "damage_scope": "each_creature",
      "players_damaged": 0
    },
    {
      "card_name": "Sweltering Suns",
      "creatures_destroyed": 2,
      "damage": 3,
      "damage_players": false,
      "damage_scope": "each_creature",
      "players_damaged": 0
    }
  ],
  "scenario_count": 5
}
```
