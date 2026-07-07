# Battle Package End-to-End Validation

- Generated UTC: `2026-07-07T01:51:32.019135+00:00`
- Package ID: `pg585_attack_self_boost_new_server_package_manifest`
- Status: `pass`
- Database target: `127.0.0.1:15432/halder`
- SQLite DB: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db`
- Snapshot: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/manaloom-knowledge/scripts/known_cards_canonical_snapshot.json`

## Stage Results

| Stage | Status | Evidence |
| --- | --- | --- |
| postgres_source_of_truth | `pass` | `{"validated_rows": 16}` |
| sqlite_hermes_cache | `pass` | `{"validated_rows": 16}` |
| canonical_snapshot_fallback | `pass` | `{"validated_cards": 16}` |
| runtime_get_card_effect | `pass` | `{"validated_cards": 16}` |
| battle_execution | `pass` | `{"events": 33, "scenarios": 16}` |

## Battle Execution

```json
{
  "event_count": 33,
  "results": [
    {
      "card_name": "Benalish Veteran",
      "power_delta": 1,
      "scenario": "Benalish Veteran boosts itself when attacking",
      "source_power": 3,
      "source_toughness": 3,
      "toughness_delta": 1
    },
    {
      "card_name": "Borderland Marauder",
      "power_delta": 2,
      "scenario": "Borderland Marauder boosts itself when attacking",
      "source_power": 4,
      "source_toughness": 2,
      "toughness_delta": 0
    },
    {
      "card_name": "Bramble Creeper",
      "power_delta": 5,
      "scenario": "Bramble Creeper boosts itself when attacking",
      "source_power": 7,
      "source_toughness": 2,
      "toughness_delta": 0
    },
    {
      "card_name": "Brazen Wolves",
      "power_delta": 2,
      "scenario": "Brazen Wolves boosts itself when attacking",
      "source_power": 4,
      "source_toughness": 2,
      "toughness_delta": 0
    },
    {
      "card_name": "Charging Bandits",
      "power_delta": 2,
      "scenario": "Charging Bandits boosts itself when attacking",
      "source_power": 4,
      "source_toughness": 2,
      "toughness_delta": 0
    },
    {
      "card_name": "Charging Paladin",
      "power_delta": 0,
      "scenario": "Charging Paladin boosts itself when attacking",
      "source_power": 2,
      "source_toughness": 5,
      "toughness_delta": 3
    },
    {
      "card_name": "Flowstone Charger",
      "power_delta": 3,
      "scenario": "Flowstone Charger boosts itself when attacking",
      "source_power": 5,
      "source_toughness": -1,
      "toughness_delta": -3
    },
    {
      "card_name": "Graceful Cat",
      "power_delta": 1,
      "scenario": "Graceful Cat boosts itself when attacking",
      "source_power": 3,
      "source_toughness": 3,
      "toughness_delta": 1
    },
    {
      "card_name": "Hollow Dogs",
      "power_delta": 2,
      "scenario": "Hollow Dogs boosts itself when attacking",
      "source_power": 4,
      "source_toughness": 2,
      "toughness_delta": 0
    },
    {
      "card_name": "Jumbo Cactuar",
      "power_delta": 9999,
      "scenario": "Jumbo Cactuar boosts itself when attacking",
      "source_power": 10001,
      "source_toughness": 2,
      "toughness_delta": 0
    },
    {
      "card_name": "Kiln Walker",
      "power_delta": 3,
      "scenario": "Kiln Walker boosts itself when attacking",
      "source_power": 5,
      "source_toughness": 2,
      "toughness_delta": 0
    },
    {
      "card_name": "Lurking Nightstalker",
      "power_delta": 2,
      "scenario": "Lurking Nightstalker boosts itself when attacking",
      "source_power": 4,
      "source_toughness": 2,
      "toughness_delta": 0
    },
    {
      "card_name": "Reckless Pangolin",
      "power_delta": 1,
      "scenario": "Reckless Pangolin boosts itself when attacking",
      "source_power": 3,
      "source_toughness": 3,
      "toughness_delta": 1
    },
    {
      "card_name": "Steadfast Cathar",
      "power_delta": 0,
      "scenario": "Steadfast Cathar boosts itself when attacking",
      "source_power": 2,
      "source_toughness": 4,
      "toughness_delta": 2
    },
    {
      "card_name": "Vicious Kavu",
      "power_delta": 2,
      "scenario": "Vicious Kavu boosts itself when attacking",
      "source_power": 4,
      "source_toughness": 2,
      "toughness_delta": 0
    },
    {
      "card_name": "Wei Ambush Force",
      "power_delta": 2,
      "scenario": "Wei Ambush Force boosts itself when attacking",
      "source_power": 4,
      "source_toughness": 2,
      "toughness_delta": 0
    }
  ],
  "scenario_count": 16
}
```
