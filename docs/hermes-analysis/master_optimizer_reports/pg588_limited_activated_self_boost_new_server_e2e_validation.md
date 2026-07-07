# Battle Package End-to-End Validation

- Generated UTC: `2026-07-07T03:02:22.809269+00:00`
- Package ID: `pg588_limited_activated_self_boost_new_server_package_manifest`
- Status: `pass`
- Database target: `127.0.0.1:15432/halder`
- SQLite DB: `docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db`
- Snapshot: `docs/hermes-analysis/manaloom-knowledge/scripts/known_cards_canonical_snapshot.json`

## Stage Results

| Stage | Status | Evidence |
| --- | --- | --- |
| postgres_source_of_truth | `pass` | `{"validated_rows": 16}` |
| sqlite_hermes_cache | `pass` | `{"validated_rows": 16}` |
| canonical_snapshot_fallback | `pass` | `{"validated_cards": 16}` |
| runtime_get_card_effect | `pass` | `{"validated_cards": 16}` |
| battle_execution | `pass` | `{"events": 32, "scenarios": 16}` |

## Battle Execution

```json
{
  "event_count": 32,
  "results": [
    {
      "activation_limit_per_turn": 1,
      "card_name": "Azimaet Drake",
      "power_delta": 1,
      "scenario": "Azimaet Drake activates self boost ability",
      "source_power": 3,
      "source_toughness": 2,
      "toughness_delta": 0
    },
    {
      "activation_limit_per_turn": 1,
      "card_name": "Darkthicket Wolf",
      "power_delta": 2,
      "scenario": "Darkthicket Wolf activates self boost ability",
      "source_power": 4,
      "source_toughness": 4,
      "toughness_delta": 2
    },
    {
      "activation_limit_per_turn": 1,
      "card_name": "Drake Hatchling",
      "power_delta": 1,
      "scenario": "Drake Hatchling activates self boost ability",
      "source_power": 3,
      "source_toughness": 2,
      "toughness_delta": 0
    },
    {
      "activation_limit_per_turn": 1,
      "card_name": "Fire Drake",
      "power_delta": 1,
      "scenario": "Fire Drake activates self boost ability",
      "source_power": 3,
      "source_toughness": 2,
      "toughness_delta": 0
    },
    {
      "activation_limit_per_turn": 1,
      "card_name": "Frilled Oculus",
      "power_delta": 2,
      "scenario": "Frilled Oculus activates self boost ability",
      "source_power": 4,
      "source_toughness": 4,
      "toughness_delta": 2
    },
    {
      "activation_limit_per_turn": 1,
      "card_name": "Frilled Sandwalla",
      "power_delta": 2,
      "scenario": "Frilled Sandwalla activates self boost ability",
      "source_power": 4,
      "source_toughness": 4,
      "toughness_delta": 2
    },
    {
      "activation_limit_per_turn": 1,
      "card_name": "Ghor-Clan Bloodscale",
      "power_delta": 2,
      "scenario": "Ghor-Clan Bloodscale activates self boost ability",
      "source_power": 4,
      "source_toughness": 4,
      "toughness_delta": 2
    },
    {
      "activation_limit_per_turn": 1,
      "card_name": "Knight of the Skyward Eye",
      "power_delta": 3,
      "scenario": "Knight of the Skyward Eye activates self boost ability",
      "source_power": 5,
      "source_toughness": 5,
      "toughness_delta": 3
    },
    {
      "activation_limit_per_turn": 1,
      "card_name": "Kraven's Cats",
      "power_delta": 2,
      "scenario": "Kraven's Cats activates self boost ability",
      "source_power": 4,
      "source_toughness": 4,
      "toughness_delta": 2
    },
    {
      "activation_limit_per_turn": 1,
      "card_name": "Plated Rootwalla",
      "power_delta": 3,
      "scenario": "Plated Rootwalla activates self boost ability",
      "source_power": 5,
      "source_toughness": 5,
      "toughness_delta": 3
    },
    {
      "activation_limit_per_turn": 1,
      "card_name": "Rootwalla",
      "power_delta": 2,
      "scenario": "Rootwalla activates self boost ability",
      "source_power": 4,
      "source_toughness": 4,
      "toughness_delta": 2
    },
    {
      "activation_limit_per_turn": 1,
      "card_name": "Setessan Griffin",
      "power_delta": 2,
      "scenario": "Setessan Griffin activates self boost ability",
      "source_power": 4,
      "source_toughness": 4,
      "toughness_delta": 2
    },
    {
      "activation_limit_per_turn": 1,
      "card_name": "Snarling Wolf",
      "power_delta": 2,
      "scenario": "Snarling Wolf activates self boost ability",
      "source_power": 4,
      "source_toughness": 4,
      "toughness_delta": 2
    },
    {
      "activation_limit_per_turn": 1,
      "card_name": "Spitting Drake",
      "power_delta": 1,
      "scenario": "Spitting Drake activates self boost ability",
      "source_power": 3,
      "source_toughness": 2,
      "toughness_delta": 0
    },
    {
      "activation_limit_per_turn": 1,
      "card_name": "Viashino Slaughtermaster",
      "power_delta": 1,
      "scenario": "Viashino Slaughtermaster activates self boost ability",
      "source_power": 3,
      "source_toughness": 3,
      "toughness_delta": 1
    },
    {
      "activation_limit_per_turn": 1,
      "card_name": "Wild Aesthir",
      "power_delta": 2,
      "scenario": "Wild Aesthir activates self boost ability",
      "source_power": 4,
      "source_toughness": 2,
      "toughness_delta": 0
    }
  ],
  "scenario_count": 16
}
```
