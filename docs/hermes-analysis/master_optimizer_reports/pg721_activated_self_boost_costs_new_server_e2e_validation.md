# Battle Package End-to-End Validation

- Generated UTC: `2026-07-10T21:07:38.469542+00:00`
- Package ID: `pg721_activated_self_boost_costs_new_server_package_manifest`
- Status: `pass`
- Database target: `127.0.0.1:15432/halder`
- SQLite DB: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db`
- Snapshot: `docs/hermes-analysis/manaloom-knowledge/scripts/known_cards_canonical_snapshot.json`

## Stage Results

| Stage | Status | Evidence |
| --- | --- | --- |
| postgres_source_of_truth | `pass` | `{"validated_rows": 15}` |
| sqlite_hermes_cache | `pass` | `{"validated_rows": 15}` |
| canonical_snapshot_fallback | `pass` | `{"validated_cards": 15}` |
| runtime_get_card_effect | `pass` | `{"validated_cards": 15}` |
| battle_execution | `pass` | `{"events": 30, "scenarios": 15}` |

## Battle Execution

```json
{
  "event_count": 30,
  "results": [
    {
      "activation_limit_per_turn": 0,
      "card_name": "Aven Trooper",
      "discarded_count": 1,
      "life_paid": 0,
      "power_delta": 1,
      "scenario": "Aven Trooper activates self boost ability",
      "source_power": 3,
      "source_toughness": 4,
      "toughness_delta": 2
    },
    {
      "activation_limit_per_turn": 0,
      "card_name": "Burning-Fist Minotaur",
      "discarded_count": 1,
      "life_paid": 0,
      "power_delta": 2,
      "scenario": "Burning-Fist Minotaur activates self boost ability",
      "source_power": 4,
      "source_toughness": 2,
      "toughness_delta": 0
    },
    {
      "activation_limit_per_turn": 0,
      "card_name": "Canyon Drake",
      "discarded_count": 1,
      "life_paid": 0,
      "power_delta": 2,
      "scenario": "Canyon Drake activates self boost ability",
      "source_power": 4,
      "source_toughness": 2,
      "toughness_delta": 0
    },
    {
      "activation_limit_per_turn": 0,
      "card_name": "Carrion Howler",
      "discarded_count": 0,
      "life_paid": 1,
      "power_delta": 2,
      "scenario": "Carrion Howler activates self boost ability",
      "source_power": 4,
      "source_toughness": 1,
      "toughness_delta": -1
    },
    {
      "activation_limit_per_turn": 1,
      "card_name": "Cutthroat Contender",
      "discarded_count": 0,
      "life_paid": 1,
      "power_delta": 1,
      "scenario": "Cutthroat Contender activates self boost ability",
      "source_power": 3,
      "source_toughness": 2,
      "toughness_delta": 0
    },
    {
      "activation_limit_per_turn": 0,
      "card_name": "Fleshgrafter",
      "discarded_count": 1,
      "life_paid": 0,
      "power_delta": 2,
      "scenario": "Fleshgrafter activates self boost ability",
      "source_power": 4,
      "source_toughness": 4,
      "toughness_delta": 2
    },
    {
      "activation_limit_per_turn": 0,
      "card_name": "Frenetic Ogre",
      "discarded_count": 1,
      "life_paid": 0,
      "power_delta": 3,
      "scenario": "Frenetic Ogre activates self boost ability",
      "source_power": 5,
      "source_toughness": 2,
      "toughness_delta": 0
    },
    {
      "activation_limit_per_turn": 0,
      "card_name": "Grimclaw Bats",
      "discarded_count": 0,
      "life_paid": 1,
      "power_delta": 1,
      "scenario": "Grimclaw Bats activates self boost ability",
      "source_power": 3,
      "source_toughness": 3,
      "toughness_delta": 1
    },
    {
      "activation_limit_per_turn": 0,
      "card_name": "Krosan Archer",
      "discarded_count": 1,
      "life_paid": 0,
      "power_delta": 0,
      "scenario": "Krosan Archer activates self boost ability",
      "source_power": 2,
      "source_toughness": 4,
      "toughness_delta": 2
    },
    {
      "activation_limit_per_turn": 0,
      "card_name": "Noose Constrictor",
      "discarded_count": 1,
      "life_paid": 0,
      "power_delta": 1,
      "scenario": "Noose Constrictor activates self boost ability",
      "source_power": 3,
      "source_toughness": 3,
      "toughness_delta": 1
    },
    {
      "activation_limit_per_turn": 0,
      "card_name": "Pardic Swordsmith",
      "discarded_count": 1,
      "life_paid": 0,
      "power_delta": 2,
      "scenario": "Pardic Swordsmith activates self boost ability",
      "source_power": 4,
      "source_toughness": 2,
      "toughness_delta": 0
    },
    {
      "activation_limit_per_turn": 1,
      "card_name": "Putrid Leech",
      "discarded_count": 0,
      "life_paid": 2,
      "power_delta": 2,
      "scenario": "Putrid Leech activates self boost ability",
      "source_power": 4,
      "source_toughness": 4,
      "toughness_delta": 2
    },
    {
      "activation_limit_per_turn": 0,
      "card_name": "Ravenous Bloodseeker",
      "discarded_count": 1,
      "life_paid": 0,
      "power_delta": 2,
      "scenario": "Ravenous Bloodseeker activates self boost ability",
      "source_power": 4,
      "source_toughness": 1,
      "toughness_delta": -2
    },
    {
      "activation_limit_per_turn": 0,
      "card_name": "Stalking Bloodsucker",
      "discarded_count": 1,
      "life_paid": 0,
      "power_delta": 2,
      "scenario": "Stalking Bloodsucker activates self boost ability",
      "source_power": 4,
      "source_toughness": 4,
      "toughness_delta": 2
    },
    {
      "activation_limit_per_turn": 0,
      "card_name": "Wall of Blood",
      "discarded_count": 0,
      "life_paid": 1,
      "power_delta": 1,
      "scenario": "Wall of Blood activates self boost ability",
      "source_power": 3,
      "source_toughness": 3,
      "toughness_delta": 1
    }
  ],
  "scenario_count": 15
}
```
