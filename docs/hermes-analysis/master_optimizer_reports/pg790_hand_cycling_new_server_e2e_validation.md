# Battle Package End-to-End Validation

- Generated UTC: `2026-07-11T21:56:11.430365+00:00`
- Package ID: `pg790_hand_cycling_new_server_package_manifest`
- Status: `pass`
- Database target: `127.0.0.1:15432/halder`
- SQLite DB: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db`
- Snapshot: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/manaloom-knowledge/scripts/known_cards_canonical_snapshot.json`

## Stage Results

| Stage | Status | Evidence |
| --- | --- | --- |
| postgres_source_of_truth | `pass` | `{"validated_rows": 24}` |
| sqlite_hermes_cache | `pass` | `{"validated_rows": 24}` |
| canonical_snapshot_fallback | `pass` | `{"validated_cards": 24}` |
| runtime_get_card_effect | `pass` | `{"validated_cards": 24}` |
| battle_execution | `pass` | `{"events": 24, "scenarios": 24}` |

## Battle Execution

```json
{
  "event_count": 24,
  "results": [
    {
      "card_name": "Angel of the God-Pharaoh",
      "cycling_cost": "{2}",
      "drawn": [
        "E2E Fresh Cycling Draw"
      ],
      "graveyard_size": 1,
      "scenario": "Angel of the God-Pharaoh cycles from hand"
    },
    {
      "card_name": "Barkhide Mauler",
      "cycling_cost": "{2}",
      "drawn": [
        "E2E Fresh Cycling Draw"
      ],
      "graveyard_size": 1,
      "scenario": "Barkhide Mauler cycles from hand"
    },
    {
      "card_name": "Desert Cerodon",
      "cycling_cost": "{R}",
      "drawn": [
        "E2E Fresh Cycling Draw"
      ],
      "graveyard_size": 1,
      "scenario": "Desert Cerodon cycles from hand"
    },
    {
      "card_name": "Granitic Titan",
      "cycling_cost": "{2}",
      "drawn": [
        "E2E Fresh Cycling Draw"
      ],
      "graveyard_size": 1,
      "scenario": "Granitic Titan cycles from hand"
    },
    {
      "card_name": "Hundroog",
      "cycling_cost": "{3}",
      "drawn": [
        "E2E Fresh Cycling Draw"
      ],
      "graveyard_size": 1,
      "scenario": "Hundroog cycles from hand"
    },
    {
      "card_name": "Imposing Vantasaur",
      "cycling_cost": "{1}",
      "drawn": [
        "E2E Fresh Cycling Draw"
      ],
      "graveyard_size": 1,
      "scenario": "Imposing Vantasaur cycles from hand"
    },
    {
      "card_name": "Jungle Weaver",
      "cycling_cost": "{2}",
      "drawn": [
        "E2E Fresh Cycling Draw"
      ],
      "graveyard_size": 1,
      "scenario": "Jungle Weaver cycles from hand"
    },
    {
      "card_name": "Keeneye Aven",
      "cycling_cost": "{2}",
      "drawn": [
        "E2E Fresh Cycling Draw"
      ],
      "graveyard_size": 1,
      "scenario": "Keeneye Aven cycles from hand"
    },
    {
      "card_name": "Lava Serpent",
      "cycling_cost": "{2}",
      "drawn": [
        "E2E Fresh Cycling Draw"
      ],
      "graveyard_size": 1,
      "scenario": "Lava Serpent cycles from hand"
    },
    {
      "card_name": "Lurching Rotbeast",
      "cycling_cost": "{B}",
      "drawn": [
        "E2E Fresh Cycling Draw"
      ],
      "graveyard_size": 1,
      "scenario": "Lurching Rotbeast cycles from hand"
    },
    {
      "card_name": "Macetail Hystrodon",
      "cycling_cost": "{3}",
      "drawn": [
        "E2E Fresh Cycling Draw"
      ],
      "graveyard_size": 1,
      "scenario": "Macetail Hystrodon cycles from hand"
    },
    {
      "card_name": "Moaning Wall",
      "cycling_cost": "{2}",
      "drawn": [
        "E2E Fresh Cycling Draw"
      ],
      "graveyard_size": 1,
      "scenario": "Moaning Wall cycles from hand"
    },
    {
      "card_name": "Pendrell Drake",
      "cycling_cost": "{2}",
      "drawn": [
        "E2E Fresh Cycling Draw"
      ],
      "graveyard_size": 1,
      "scenario": "Pendrell Drake cycles from hand"
    },
    {
      "card_name": "Primoc Escapee",
      "cycling_cost": "{2}",
      "drawn": [
        "E2E Fresh Cycling Draw"
      ],
      "graveyard_size": 1,
      "scenario": "Primoc Escapee cycles from hand"
    },
    {
      "card_name": "Rampaging Hippo",
      "cycling_cost": "{2}",
      "drawn": [
        "E2E Fresh Cycling Draw"
      ],
      "graveyard_size": 1,
      "scenario": "Rampaging Hippo cycles from hand"
    },
    {
      "card_name": "Ridge Rannet",
      "cycling_cost": "{2}",
      "drawn": [
        "E2E Fresh Cycling Draw"
      ],
      "graveyard_size": 1,
      "scenario": "Ridge Rannet cycles from hand"
    },
    {
      "card_name": "Sandbar Merfolk",
      "cycling_cost": "{2}",
      "drawn": [
        "E2E Fresh Cycling Draw"
      ],
      "graveyard_size": 1,
      "scenario": "Sandbar Merfolk cycles from hand"
    },
    {
      "card_name": "Sandbar Serpent",
      "cycling_cost": "{2}",
      "drawn": [
        "E2E Fresh Cycling Draw"
      ],
      "graveyard_size": 1,
      "scenario": "Sandbar Serpent cycles from hand"
    },
    {
      "card_name": "Shimmering Barrier",
      "cycling_cost": "{2}",
      "drawn": [
        "E2E Fresh Cycling Draw"
      ],
      "graveyard_size": 1,
      "scenario": "Shimmering Barrier cycles from hand"
    },
    {
      "card_name": "Shimmerscale Drake",
      "cycling_cost": "{2}",
      "drawn": [
        "E2E Fresh Cycling Draw"
      ],
      "graveyard_size": 1,
      "scenario": "Shimmerscale Drake cycles from hand"
    },
    {
      "card_name": "Striped Riverwinder",
      "cycling_cost": "{U}",
      "drawn": [
        "E2E Fresh Cycling Draw"
      ],
      "graveyard_size": 1,
      "scenario": "Striped Riverwinder cycles from hand"
    },
    {
      "card_name": "Wasteland Scorpion",
      "cycling_cost": "{2}",
      "drawn": [
        "E2E Fresh Cycling Draw"
      ],
      "graveyard_size": 1,
      "scenario": "Wasteland Scorpion cycles from hand"
    },
    {
      "card_name": "Winged Shepherd",
      "cycling_cost": "{W}",
      "drawn": [
        "E2E Fresh Cycling Draw"
      ],
      "graveyard_size": 1,
      "scenario": "Winged Shepherd cycles from hand"
    },
    {
      "card_name": "Yoked Plowbeast",
      "cycling_cost": "{2}",
      "drawn": [
        "E2E Fresh Cycling Draw"
      ],
      "graveyard_size": 1,
      "scenario": "Yoked Plowbeast cycles from hand"
    }
  ],
  "scenario_count": 24
}
```
