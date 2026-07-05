# Battle Package End-to-End Validation

- Generated UTC: `2026-07-05T21:57:37.823600+00:00`
- Package ID: `pg532_aura_static_pt_new_server_package_manifest`
- Status: `pass`
- Database target: `143.198.230.247:5433/halder`
- SQLite DB: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db`
- Snapshot: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/manaloom-knowledge/scripts/known_cards_canonical_snapshot.json`

## Stage Results

| Stage | Status | Evidence |
| --- | --- | --- |
| postgres_source_of_truth | `pass` | `{"validated_rows": 35}` |
| sqlite_hermes_cache | `pass` | `{"validated_rows": 35}` |
| canonical_snapshot_fallback | `pass` | `{"validated_cards": 35}` |
| runtime_get_card_effect | `pass` | `{"validated_cards": 35}` |
| battle_execution | `pass` | `{"events": 49, "scenarios": 35}` |

## Battle Execution

```json
{
  "event_count": 49,
  "results": [
    {
      "attached_event": {
        "power_boost": 3,
        "target_player": "Aura Target Opponent",
        "toughness_boost": -3
      },
      "card_name": "Boon of Emrakul",
      "moved_to_graveyard": true,
      "scenario": "Boon of Emrakul aura static P/T attaches",
      "target": "E2E Aura Target for Boon of Emrakul",
      "target_owner": "opponent",
      "target_power": 5,
      "target_toughness": -1
    },
    {
      "attached_event": {
        "power_boost": -13,
        "target_player": "Aura Target Opponent",
        "toughness_boost": 0
      },
      "card_name": "Chant of the Skifsang",
      "moved_to_graveyard": false,
      "scenario": "Chant of the Skifsang aura static P/T attaches",
      "target": "E2E Aura Target for Chant of the Skifsang",
      "target_owner": "opponent",
      "target_power": -11,
      "target_toughness": 2
    },
    {
      "attached_event": {
        "power_boost": -4,
        "target_player": "Aura Target Opponent",
        "toughness_boost": -1
      },
      "card_name": "Clinging Darkness",
      "moved_to_graveyard": false,
      "scenario": "Clinging Darkness aura static P/T attaches",
      "target": "E2E Aura Target for Clinging Darkness",
      "target_owner": "opponent",
      "target_power": -2,
      "target_toughness": 1
    },
    {
      "attached_event": {
        "power_boost": -2,
        "target_player": "Aura Target Opponent",
        "toughness_boost": -2
      },
      "card_name": "Dead Weight",
      "moved_to_graveyard": true,
      "scenario": "Dead Weight aura static P/T attaches",
      "target": "E2E Aura Target for Dead Weight",
      "target_owner": "opponent",
      "target_power": 0,
      "target_toughness": 0
    },
    {
      "attached_event": {
        "power_boost": -2,
        "target_player": "Aura Target Opponent",
        "toughness_boost": -2
      },
      "card_name": "Debilitating Injury",
      "moved_to_graveyard": true,
      "scenario": "Debilitating Injury aura static P/T attaches",
      "target": "E2E Aura Target for Debilitating Injury",
      "target_owner": "opponent",
      "target_power": 0,
      "target_toughness": 0
    },
    {
      "attached_event": {
        "power_boost": -1,
        "target_player": "Aura Target Opponent",
        "toughness_boost": 1
      },
      "card_name": "Defensive Stance",
      "moved_to_graveyard": false,
      "scenario": "Defensive Stance aura static P/T attaches",
      "target": "E2E Aura Target for Defensive Stance",
      "target_owner": "opponent",
      "target_power": 1,
      "target_toughness": 3
    },
    {
      "attached_event": {
        "power_boost": 3,
        "target_player": "Aura Controller",
        "toughness_boost": 3
      },
      "card_name": "Divine Transformation",
      "moved_to_graveyard": false,
      "scenario": "Divine Transformation aura static P/T attaches",
      "target": "E2E Aura Target for Divine Transformation",
      "target_owner": "controller",
      "target_power": 5,
      "target_toughness": 5
    },
    {
      "attached_event": {
        "power_boost": -2,
        "target_player": "Aura Target Opponent",
        "toughness_boost": -2
      },
      "card_name": "Enfeeblement",
      "moved_to_graveyard": true,
      "scenario": "Enfeeblement aura static P/T attaches",
      "target": "E2E Aura Target for Enfeeblement",
      "target_owner": "opponent",
      "target_power": 0,
      "target_toughness": 0
    },
    {
      "attached_event": {
        "power_boost": 4,
        "target_player": "Aura Controller",
        "toughness_boost": 0
      },
      "card_name": "Feast of the Unicorn",
      "moved_to_graveyard": false,
      "scenario": "Feast of the Unicorn aura static P/T attaches",
      "target": "E2E Aura Target for Feast of the Unicorn",
      "target_owner": "controller",
      "target_power": 6,
      "target_toughness": 2
    },
    {
      "attached_event": {
        "power_boost": -2,
        "target_player": "Aura Target Opponent",
        "toughness_boost": -1
      },
      "card_name": "Feebleness",
      "moved_to_graveyard": false,
      "scenario": "Feebleness aura static P/T attaches",
      "target": "E2E Aura Target for Feebleness",
      "target_owner": "opponent",
      "target_power": 0,
      "target_toughness": 1
    },
    {
      "attached_event": {
        "power_boost": 2,
        "target_player": "Aura Controller",
        "toughness_boost": 2
      },
      "card_name": "Feral Invocation",
      "moved_to_graveyard": false,
      "scenario": "Feral Invocation aura static P/T attaches",
      "target": "E2E Aura Target for Feral Invocation",
      "target_owner": "controller",
      "target_power": 4,
      "target_toughness": 4
    },
    {
      "attached_event": {
        "power_boost": 2,
        "target_player": "Aura Controller",
        "toughness_boost": 2
      },
      "card_name": "Giant Strength",
      "moved_to_graveyard": false,
      "scenario": "Giant Strength aura static P/T attaches",
      "target": "E2E Aura Target for Giant Strength",
      "target_owner": "controller",
      "target_power": 4,
      "target_toughness": 4
    },
    {
      "attached_event": {
        "power_boost": 0,
        "target_player": "Aura Controller",
        "toughness_boost": 2
      },
      "card_name": "Gift of Granite",
      "moved_to_graveyard": false,
      "scenario": "Gift of Granite aura static P/T attaches",
      "target": "E2E Aura Target for Gift of Granite",
      "target_owner": "controller",
      "target_power": 2,
      "target_toughness": 4
    },
    {
      "attached_event": {
        "power_boost": -3,
        "target_player": "Aura Target Opponent",
        "toughness_boost": 0
      },
      "card_name": "Greel's Caress",
      "moved_to_graveyard": false,
      "scenario": "Greel's Caress aura static P/T attaches",
      "target": "E2E Aura Target for Greel's Caress",
      "target_owner": "opponent",
      "target_power": -1,
      "target_toughness": 2
    },
    {
      "attached_event": {
        "power_boost": 3,
        "target_player": "Aura Controller",
        "toughness_boost": 3
      },
      "card_name": "Hardened-Scale Armor",
      "moved_to_graveyard": false,
      "scenario": "Hardened-Scale Armor aura static P/T attaches",
      "target": "E2E Aura Target for Hardened-Scale Armor",
      "target_owner": "controller",
      "target_power": 5,
      "target_toughness": 5
    },
    {
      "attached_event": {
        "power_boost": 1,
        "target_player": "Aura Controller",
        "toughness_boost": 5
      },
      "card_name": "Hero's Resolve",
      "moved_to_graveyard": false,
      "scenario": "Hero's Resolve aura static P/T attaches",
      "target": "E2E Aura Target for Hero's Resolve",
      "target_owner": "controller",
      "target_power": 3,
      "target_toughness": 7
    },
    {
      "attached_event": {
        "power_boost": 1,
        "target_player": "Aura Controller",
        "toughness_boost": 2
      },
      "card_name": "Holy Strength",
      "moved_to_graveyard": false,
      "scenario": "Holy Strength aura static P/T attaches",
      "target": "E2E Aura Target for Holy Strength",
      "target_owner": "controller",
      "target_power": 3,
      "target_toughness": 4
    },
    {
      "attached_event": {
        "power_boost": 1,
        "target_player": "Aura Controller",
        "toughness_boost": 2
      },
      "card_name": "Indomitable Will",
      "moved_to_graveyard": false,
      "scenario": "Indomitable Will aura static P/T attaches",
      "target": "E2E Aura Target for Indomitable Will",
      "target_owner": "controller",
      "target_power": 3,
      "target_toughness": 4
    },
    {
      "attached_event": {
        "power_boost": 2,
        "target_player": "Aura Controller",
        "toughness_boost": 2
      },
      "card_name": "Knight's Pledge",
      "moved_to_graveyard": false,
      "scenario": "Knight's Pledge aura static P/T attaches",
      "target": "E2E Aura Target for Knight's Pledge",
      "target_owner": "controller",
      "target_power": 4,
      "target_toughness": 4
    },
    {
      "attached_event": {
        "power_boost": 1,
        "target_player": "Aura Controller",
        "toughness_boost": 2
      },
      "card_name": "Mageta's Boon",
      "moved_to_graveyard": false,
      "scenario": "Mageta's Boon aura static P/T attaches",
      "target": "E2E Aura Target for Mageta's Boon",
      "target_owner": "controller",
      "target_power": 3,
      "target_toughness": 4
    },
    {
      "attached_event": {
        "power_boost": 2,
        "target_player": "Aura Target Opponent",
        "toughness_boost": -2
      },
      "card_name": "Maggot Therapy",
      "moved_to_graveyard": true,
      "scenario": "Maggot Therapy aura static P/T attaches",
      "target": "E2E Aura Target for Maggot Therapy",
      "target_owner": "opponent",
      "target_power": 4,
      "target_toughness": 0
    },
    {
      "attached_event": {
        "power_boost": -3,
        "target_player": "Aura Target Opponent",
        "toughness_boost": -3
      },
      "card_name": "Mire's Grasp",
      "moved_to_graveyard": true,
      "scenario": "Mire's Grasp aura static P/T attaches",
      "target": "E2E Aura Target for Mire's Grasp",
      "target_owner": "opponent",
      "target_power": -1,
      "target_toughness": -1
    },
    {
      "attached_event": {
        "power_boost": 3,
        "target_player": "Aura Controller",
        "toughness_boost": 3
      },
      "card_name": "Oakenform",
      "moved_to_graveyard": false,
      "scenario": "Oakenform aura static P/T attaches",
      "target": "E2E Aura Target for Oakenform",
      "target_owner": "controller",
      "target_power": 5,
      "target_toughness": 5
    },
    {
      "attached_event": {
        "power_boost": -6,
        "target_player": "Aura Target Opponent",
        "toughness_boost": 0
      },
      "card_name": "Pin to the Earth",
      "moved_to_graveyard": false,
      "scenario": "Pin to the Earth aura static P/T attaches",
      "target": "E2E Aura Target for Pin to the Earth",
      "target_owner": "opponent",
      "target_power": -4,
      "target_toughness": 2
    },
    {
      "attached_event": {
        "power_boost": 2,
        "target_player": "Aura Target Opponent",
        "toughness_boost": -1
      },
      "card_name": "Riot Spikes",
      "moved_to_graveyard": false,
      "scenario": "Riot Spikes aura static P/T attaches",
      "target": "E2E Aura Target for Riot Spikes",
      "target_owner": "opponent",
      "target_power": 4,
      "target_toughness": 1
    },
    {
      "attached_event": {
        "power_boost": -3,
        "target_player": "Aura Target Opponent",
        "toughness_boost": 0
      },
      "card_name": "Sensory Deprivation",
      "moved_to_graveyard": false,
      "scenario": "Sensory Deprivation aura static P/T attaches",
      "target": "E2E Aura Target for Sensory Deprivation",
      "target_owner": "opponent",
      "target_power": -1,
      "target_toughness": 2
    },
    {
      "attached_event": {
        "power_boost": 2,
        "target_player": "Aura Controller",
        "toughness_boost": 4
      },
      "card_name": "Siegecraft",
      "moved_to_graveyard": false,
      "scenario": "Siegecraft aura static P/T attaches",
      "target": "E2E Aura Target for Siegecraft",
      "target_owner": "controller",
      "target_power": 4,
      "target_toughness": 6
    },
    {
      "attached_event": {
        "power_boost": -4,
        "target_player": "Aura Target Opponent",
        "toughness_boost": 0
      },
      "card_name": "Slimebind",
      "moved_to_graveyard": false,
      "scenario": "Slimebind aura static P/T attaches",
      "target": "E2E Aura Target for Slimebind",
      "target_owner": "opponent",
      "target_power": -2,
      "target_toughness": 2
    },
    {
      "attached_event": {
        "power_boost": 0,
        "target_player": "Aura Controller",
        "toughness_boost": 10
      },
      "card_name": "Stoneskin",
      "moved_to_graveyard": false,
      "scenario": "Stoneskin aura static P/T attaches",
      "target": "E2E Aura Target for Stoneskin",
      "target_owner": "controller",
      "target_power": 2,
      "target_toughness": 12
    },
    {
      "attached_event": {
        "power_boost": -3,
        "target_player": "Aura Target Opponent",
        "toughness_boost": 0
      },
      "card_name": "Torment",
      "moved_to_graveyard": false,
      "scenario": "Torment aura static P/T attaches",
      "target": "E2E Aura Target for Torment",
      "target_owner": "opponent",
      "target_power": -1,
      "target_toughness": 2
    },
    {
      "attached_event": {
        "power_boost": -3,
        "target_player": "Aura Target Opponent",
        "toughness_boost": 0
      },
      "card_name": "Torpor Dust",
      "moved_to_graveyard": false,
      "scenario": "Torpor Dust aura static P/T attaches",
      "target": "E2E Aura Target for Torpor Dust",
      "target_owner": "opponent",
      "target_power": -1,
      "target_toughness": 2
    },
    {
      "attached_event": {
        "power_boost": 3,
        "target_player": "Aura Target Opponent",
        "toughness_boost": -1
      },
      "card_name": "Twisted Experiment",
      "moved_to_graveyard": false,
      "scenario": "Twisted Experiment aura static P/T attaches",
      "target": "E2E Aura Target for Twisted Experiment",
      "target_owner": "opponent",
      "target_power": 5,
      "target_toughness": 1
    },
    {
      "attached_event": {
        "power_boost": 2,
        "target_player": "Aura Controller",
        "toughness_boost": 1
      },
      "card_name": "Unholy Strength",
      "moved_to_graveyard": false,
      "scenario": "Unholy Strength aura static P/T attaches",
      "target": "E2E Aura Target for Unholy Strength",
      "target_owner": "controller",
      "target_power": 4,
      "target_toughness": 3
    },
    {
      "attached_event": {
        "power_boost": -2,
        "target_player": "Aura Target Opponent",
        "toughness_boost": -1
      },
      "card_name": "Weakness",
      "moved_to_graveyard": false,
      "scenario": "Weakness aura static P/T attaches",
      "target": "E2E Aura Target for Weakness",
      "target_owner": "opponent",
      "target_power": 0,
      "target_toughness": 1
    },
    {
      "attached_event": {
        "power_boost": -3,
        "target_player": "Aura Target Opponent",
        "toughness_boost": -2
      },
      "card_name": "Weight of the Underworld",
      "moved_to_graveyard": true,
      "scenario": "Weight of the Underworld aura static P/T attaches",
      "target": "E2E Aura Target for Weight of the Underworld",
      "target_owner": "opponent",
      "target_power": -1,
      "target_toughness": 0
    }
  ],
  "scenario_count": 35
}
```
