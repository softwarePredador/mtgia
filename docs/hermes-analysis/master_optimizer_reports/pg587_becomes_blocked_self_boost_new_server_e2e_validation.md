# Battle Package End-to-End Validation

- Generated UTC: `2026-07-07T02:43:26.956804+00:00`
- Package ID: `pg587_becomes_blocked_self_boost_new_server_package_manifest`
- Status: `pass`
- Database target: `127.0.0.1:15432/halder`
- SQLite DB: `docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db`
- Snapshot: `docs/hermes-analysis/manaloom-knowledge/scripts/known_cards_canonical_snapshot.json`

## Stage Results

| Stage | Status | Evidence |
| --- | --- | --- |
| postgres_source_of_truth | `pass` | `{"validated_rows": 13}` |
| sqlite_hermes_cache | `pass` | `{"validated_rows": 13}` |
| canonical_snapshot_fallback | `pass` | `{"validated_cards": 13}` |
| runtime_get_card_effect | `pass` | `{"validated_cards": 13}` |
| battle_execution | `pass` | `{"events": 26, "scenarios": 13}` |

## Battle Execution

```json
{
  "event_count": 26,
  "results": [
    {
      "blocker_count": 1,
      "blocker_count_mode": "fixed",
      "card_name": "Deeproot Warrior",
      "power_delta": 1,
      "scenario": "Deeproot Warrior boosts itself when blocked",
      "source_power": 3,
      "source_toughness": 3,
      "toughness_delta": 1
    },
    {
      "blocker_count": 1,
      "blocker_count_mode": "fixed",
      "card_name": "Deepwood Wolverine",
      "power_delta": 2,
      "scenario": "Deepwood Wolverine boosts itself when blocked",
      "source_power": 4,
      "source_toughness": 2,
      "toughness_delta": 0
    },
    {
      "blocker_count": 3,
      "blocker_count_mode": "per_blocker",
      "card_name": "Elvish Berserker",
      "power_delta": 3,
      "scenario": "Elvish Berserker boosts itself when blocked",
      "source_power": 5,
      "source_toughness": 5,
      "toughness_delta": 3
    },
    {
      "blocker_count": 3,
      "blocker_count_mode": "per_blocker",
      "card_name": "Gang of Elk",
      "power_delta": 6,
      "scenario": "Gang of Elk boosts itself when blocked",
      "source_power": 8,
      "source_toughness": 8,
      "toughness_delta": 6
    },
    {
      "blocker_count": 3,
      "blocker_count_mode": "beyond_first",
      "card_name": "Johtull Wurm",
      "power_delta": -4,
      "scenario": "Johtull Wurm boosts itself when blocked",
      "source_power": 2,
      "source_toughness": 4,
      "toughness_delta": -2
    },
    {
      "blocker_count": 3,
      "blocker_count_mode": "beyond_first",
      "card_name": "Jungle Wurm",
      "power_delta": -2,
      "scenario": "Jungle Wurm boosts itself when blocked",
      "source_power": 4,
      "source_toughness": 4,
      "toughness_delta": -2
    },
    {
      "blocker_count": 1,
      "blocker_count_mode": "fixed",
      "card_name": "Norwood Warrior",
      "power_delta": 1,
      "scenario": "Norwood Warrior boosts itself when blocked",
      "source_power": 3,
      "source_toughness": 3,
      "toughness_delta": 1
    },
    {
      "blocker_count": 3,
      "blocker_count_mode": "per_blocker",
      "card_name": "Rabid Elephant",
      "power_delta": 6,
      "scenario": "Rabid Elephant boosts itself when blocked",
      "source_power": 8,
      "source_toughness": 8,
      "toughness_delta": 6
    },
    {
      "blocker_count": 1,
      "blocker_count_mode": "fixed",
      "card_name": "Razorclaw Bear",
      "power_delta": 2,
      "scenario": "Razorclaw Bear boosts itself when blocked",
      "source_power": 4,
      "source_toughness": 4,
      "toughness_delta": 2
    },
    {
      "blocker_count": 1,
      "blocker_count_mode": "fixed",
      "card_name": "Slashing Tiger",
      "power_delta": 2,
      "scenario": "Slashing Tiger boosts itself when blocked",
      "source_power": 4,
      "source_toughness": 4,
      "toughness_delta": 2
    },
    {
      "blocker_count": 1,
      "blocker_count_mode": "fixed",
      "card_name": "Snorting Gahr",
      "power_delta": 2,
      "scenario": "Snorting Gahr boosts itself when blocked",
      "source_power": 4,
      "source_toughness": 4,
      "toughness_delta": 2
    },
    {
      "blocker_count": 3,
      "blocker_count_mode": "per_blocker",
      "card_name": "Sparring Golem",
      "power_delta": 3,
      "scenario": "Sparring Golem boosts itself when blocked",
      "source_power": 5,
      "source_toughness": 5,
      "toughness_delta": 3
    },
    {
      "blocker_count": 1,
      "blocker_count_mode": "fixed",
      "card_name": "Trained Cheetah",
      "power_delta": 1,
      "scenario": "Trained Cheetah boosts itself when blocked",
      "source_power": 3,
      "source_toughness": 3,
      "toughness_delta": 1
    }
  ],
  "scenario_count": 13
}
```
