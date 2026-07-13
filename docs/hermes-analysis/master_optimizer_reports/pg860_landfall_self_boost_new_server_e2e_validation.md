# Battle Package End-to-End Validation

- Generated UTC: `2026-07-13T03:26:18.705477+00:00`
- Package ID: `pg860_landfall_self_boost_new_server_package_manifest`
- Status: `pass`
- Database target: `127.0.0.1:15432/halder`
- SQLite DB: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db`
- Snapshot: `docs/hermes-analysis/master_optimizer_reports/pg860_landfall_self_boost_new_server_canonical_snapshot.json`

## Stage Results

| Stage | Status | Evidence |
| --- | --- | --- |
| postgres_source_of_truth | `pass` | `{"validated_rows": 9}` |
| sqlite_hermes_cache | `pass` | `{"validated_rows": 9}` |
| canonical_snapshot_fallback | `pass` | `{"validated_cards": 9}` |
| runtime_get_card_effect | `pass` | `{"validated_cards": 9}` |
| battle_execution | `pass` | `{"events": 18, "scenarios": 9}` |

## Battle Execution

```json
{
  "event_count": 18,
  "results": [
    {
      "card_name": "Akoum Hellhound",
      "power_delta": 2,
      "scenario": "Akoum Hellhound boosts itself on landfall",
      "source_power": 4,
      "source_toughness": 4,
      "toughness_delta": 2
    },
    {
      "card_name": "Canopy Baloth",
      "power_delta": 2,
      "scenario": "Canopy Baloth boosts itself on landfall",
      "source_power": 4,
      "source_toughness": 4,
      "toughness_delta": 2
    },
    {
      "card_name": "Hedron Rover",
      "power_delta": 2,
      "scenario": "Hedron Rover boosts itself on landfall",
      "source_power": 4,
      "source_toughness": 4,
      "toughness_delta": 2
    },
    {
      "card_name": "Hedron Scrabbler",
      "power_delta": 1,
      "scenario": "Hedron Scrabbler boosts itself on landfall",
      "source_power": 3,
      "source_toughness": 3,
      "toughness_delta": 1
    },
    {
      "card_name": "Scythe Leopard",
      "power_delta": 1,
      "scenario": "Scythe Leopard boosts itself on landfall",
      "source_power": 3,
      "source_toughness": 3,
      "toughness_delta": 1
    },
    {
      "card_name": "Snapping Gnarlid",
      "power_delta": 1,
      "scenario": "Snapping Gnarlid boosts itself on landfall",
      "source_power": 3,
      "source_toughness": 3,
      "toughness_delta": 1
    },
    {
      "card_name": "Steppe Lynx",
      "power_delta": 2,
      "scenario": "Steppe Lynx boosts itself on landfall",
      "source_power": 4,
      "source_toughness": 4,
      "toughness_delta": 2
    },
    {
      "card_name": "Territorial Baloth",
      "power_delta": 2,
      "scenario": "Territorial Baloth boosts itself on landfall",
      "source_power": 4,
      "source_toughness": 4,
      "toughness_delta": 2
    },
    {
      "card_name": "Valakut Predator",
      "power_delta": 2,
      "scenario": "Valakut Predator boosts itself on landfall",
      "source_power": 4,
      "source_toughness": 4,
      "toughness_delta": 2
    }
  ],
  "scenario_count": 9
}
```
