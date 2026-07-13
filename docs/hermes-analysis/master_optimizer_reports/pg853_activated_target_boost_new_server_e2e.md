# Battle Package End-to-End Validation

- Generated UTC: `2026-07-13T00:29:21.373462+00:00`
- Package ID: `pg853_activated_target_boost_new_server_package_manifest`
- Status: `pass`
- Database target: `127.0.0.1:15432/halder`
- SQLite DB: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db`
- Snapshot: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/manaloom-knowledge/scripts/known_cards_canonical_snapshot.json`

## Stage Results

| Stage | Status | Evidence |
| --- | --- | --- |
| postgres_source_of_truth | `pass` | `{"validated_rows": 21}` |
| sqlite_hermes_cache | `pass` | `{"validated_rows": 21}` |
| canonical_snapshot_fallback | `pass` | `{"validated_cards": 21}` |
| runtime_get_card_effect | `pass` | `{"validated_cards": 21}` |
| battle_execution | `pass` | `{"events": 42, "scenarios": 21}` |

## Battle Execution

```json
{
  "event_count": 42,
  "results": [
    {
      "card_name": "Aegis of the Meek",
      "power_delta": 1,
      "sacrificed_source": false,
      "scenario": "Aegis of the Meek activates target boost ability",
      "source_tapped": true,
      "target": "E2E Target Boost Legal Target",
      "target_controller": "self",
      "target_power": 2,
      "target_toughness": 3,
      "toughness_delta": 2
    },
    {
      "card_name": "Alpha Kavu",
      "power_delta": -1,
      "sacrificed_source": false,
      "scenario": "Alpha Kavu activates target boost ability",
      "source_tapped": false,
      "target": "E2E Target Boost Legal Target",
      "target_controller": "opponent",
      "target_power": 3,
      "target_toughness": 5,
      "toughness_delta": 1
    },
    {
      "card_name": "Angelic Page",
      "power_delta": 1,
      "sacrificed_source": false,
      "scenario": "Angelic Page activates target boost ability",
      "source_tapped": true,
      "target": "E2E Target Boost Legal Target",
      "target_controller": "self",
      "target_power": 5,
      "target_toughness": 5,
      "toughness_delta": 1
    },
    {
      "card_name": "Anointer of Champions",
      "power_delta": 1,
      "sacrificed_source": false,
      "scenario": "Anointer of Champions activates target boost ability",
      "source_tapped": true,
      "target": "E2E Target Boost Legal Target",
      "target_controller": "self",
      "target_power": 5,
      "target_toughness": 5,
      "toughness_delta": 1
    },
    {
      "card_name": "Assembly-Worker",
      "power_delta": 1,
      "sacrificed_source": false,
      "scenario": "Assembly-Worker activates target boost ability",
      "source_tapped": true,
      "target": "E2E Target Boost Legal Target",
      "target_controller": "self",
      "target_power": 5,
      "target_toughness": 5,
      "toughness_delta": 1
    },
    {
      "card_name": "Crenellated Wall",
      "power_delta": 0,
      "sacrificed_source": false,
      "scenario": "Crenellated Wall activates target boost ability",
      "source_tapped": true,
      "target": "E2E Target Boost Legal Target",
      "target_controller": "self",
      "target_power": 4,
      "target_toughness": 8,
      "toughness_delta": 4
    },
    {
      "card_name": "Dwarven Lieutenant",
      "power_delta": 1,
      "sacrificed_source": false,
      "scenario": "Dwarven Lieutenant activates target boost ability",
      "source_tapped": false,
      "target": "E2E Target Boost Legal Target",
      "target_controller": "self",
      "target_power": 5,
      "target_toughness": 4,
      "toughness_delta": 0
    },
    {
      "card_name": "Grassland Crusader",
      "power_delta": 2,
      "sacrificed_source": false,
      "scenario": "Grassland Crusader activates target boost ability",
      "source_tapped": true,
      "target": "E2E Target Boost Legal Target",
      "target_controller": "self",
      "target_power": 6,
      "target_toughness": 6,
      "toughness_delta": 2
    },
    {
      "card_name": "Hate Weaver",
      "power_delta": 1,
      "sacrificed_source": false,
      "scenario": "Hate Weaver activates target boost ability",
      "source_tapped": false,
      "target": "E2E Target Boost Legal Target",
      "target_controller": "self",
      "target_power": 5,
      "target_toughness": 4,
      "toughness_delta": 0
    },
    {
      "card_name": "Hoof Skulkin",
      "power_delta": 1,
      "sacrificed_source": false,
      "scenario": "Hoof Skulkin activates target boost ability",
      "source_tapped": false,
      "target": "E2E Target Boost Legal Target",
      "target_controller": "self",
      "target_power": 5,
      "target_toughness": 5,
      "toughness_delta": 1
    },
    {
      "card_name": "Icatian Lieutenant",
      "power_delta": 1,
      "sacrificed_source": false,
      "scenario": "Icatian Lieutenant activates target boost ability",
      "source_tapped": false,
      "target": "E2E Target Boost Legal Target",
      "target_controller": "self",
      "target_power": 5,
      "target_toughness": 4,
      "toughness_delta": 0
    },
    {
      "card_name": "Infantry Veteran",
      "power_delta": 1,
      "sacrificed_source": false,
      "scenario": "Infantry Veteran activates target boost ability",
      "source_tapped": true,
      "target": "E2E Target Boost Legal Target",
      "target_controller": "self",
      "target_power": 5,
      "target_toughness": 5,
      "toughness_delta": 1
    },
    {
      "card_name": "Kabuto Moth",
      "power_delta": 1,
      "sacrificed_source": false,
      "scenario": "Kabuto Moth activates target boost ability",
      "source_tapped": true,
      "target": "E2E Target Boost Legal Target",
      "target_controller": "self",
      "target_power": 5,
      "target_toughness": 6,
      "toughness_delta": 2
    },
    {
      "card_name": "Kithkin Daggerdare",
      "power_delta": 2,
      "sacrificed_source": false,
      "scenario": "Kithkin Daggerdare activates target boost ability",
      "source_tapped": true,
      "target": "E2E Target Boost Legal Target",
      "target_controller": "self",
      "target_power": 6,
      "target_toughness": 6,
      "toughness_delta": 2
    },
    {
      "card_name": "Phyrexian Debaser",
      "power_delta": -2,
      "sacrificed_source": true,
      "scenario": "Phyrexian Debaser activates target boost ability",
      "source_tapped": true,
      "target": "E2E Target Boost Legal Target",
      "target_controller": "opponent",
      "target_power": 2,
      "target_toughness": 2,
      "toughness_delta": -2
    },
    {
      "card_name": "Serra Advocate",
      "power_delta": 2,
      "sacrificed_source": false,
      "scenario": "Serra Advocate activates target boost ability",
      "source_tapped": true,
      "target": "E2E Target Boost Legal Target",
      "target_controller": "self",
      "target_power": 6,
      "target_toughness": 6,
      "toughness_delta": 2
    },
    {
      "card_name": "Spirit Weaver",
      "power_delta": 0,
      "sacrificed_source": false,
      "scenario": "Spirit Weaver activates target boost ability",
      "source_tapped": false,
      "target": "E2E Target Boost Legal Target",
      "target_controller": "self",
      "target_power": 4,
      "target_toughness": 5,
      "toughness_delta": 1
    },
    {
      "card_name": "Sword Dancer",
      "power_delta": -1,
      "sacrificed_source": false,
      "scenario": "Sword Dancer activates target boost ability",
      "source_tapped": false,
      "target": "E2E Target Boost Legal Target",
      "target_controller": "opponent",
      "target_power": 3,
      "target_toughness": 4,
      "toughness_delta": 0
    },
    {
      "card_name": "Sword of the Chosen",
      "power_delta": 2,
      "sacrificed_source": false,
      "scenario": "Sword of the Chosen activates target boost ability",
      "source_tapped": true,
      "target": "E2E Target Boost Legal Target",
      "target_controller": "self",
      "target_power": 6,
      "target_toughness": 6,
      "toughness_delta": 2
    },
    {
      "card_name": "Tuknir Deathlock",
      "power_delta": 2,
      "sacrificed_source": false,
      "scenario": "Tuknir Deathlock activates target boost ability",
      "source_tapped": true,
      "target": "E2E Target Boost Legal Target",
      "target_controller": "self",
      "target_power": 6,
      "target_toughness": 6,
      "toughness_delta": 2
    },
    {
      "card_name": "Wilderness Hypnotist",
      "power_delta": -2,
      "sacrificed_source": false,
      "scenario": "Wilderness Hypnotist activates target boost ability",
      "source_tapped": true,
      "target": "E2E Target Boost Legal Target",
      "target_controller": "opponent",
      "target_power": 2,
      "target_toughness": 4,
      "toughness_delta": 0
    }
  ],
  "scenario_count": 21
}
```
