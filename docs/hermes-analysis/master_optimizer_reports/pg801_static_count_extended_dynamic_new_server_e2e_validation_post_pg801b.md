# Battle Package End-to-End Validation

- Generated UTC: `2026-07-12T02:28:01.440912+00:00`
- Package ID: `pg801_static_count_extended_dynamic_new_server_package_manifest`
- Status: `pass`
- Database target: `127.0.0.1:15432/halder`
- SQLite DB: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db`
- Snapshot: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/manaloom-knowledge/scripts/known_cards_canonical_snapshot.json`

## Stage Results

| Stage | Status | Evidence |
| --- | --- | --- |
| postgres_source_of_truth | `pass` | `{"validated_rows": 6}` |
| sqlite_hermes_cache | `pass` | `{"validated_rows": 6}` |
| canonical_snapshot_fallback | `pass` | `{"validated_cards": 6}` |
| runtime_get_card_effect | `pass` | `{"validated_cards": 6}` |
| battle_execution | `pass` | `{"events": 6, "scenarios": 6}` |

## Battle Execution

```json
{
  "event_count": 6,
  "results": [
    {
      "card_name": "Abomination of Llanowar",
      "count": 3,
      "power": 3,
      "scenario": "Abomination of Llanowar static count P/T recalculates",
      "toughness": 3
    },
    {
      "card_name": "Ancient Ooze",
      "count": 5,
      "power": 5,
      "scenario": "Ancient Ooze static count P/T recalculates",
      "toughness": 5
    },
    {
      "card_name": "Awakened Amalgam",
      "count": 2,
      "power": 2,
      "scenario": "Awakened Amalgam static count P/T recalculates",
      "toughness": 2
    },
    {
      "card_name": "Primalcrux",
      "count": 4,
      "power": 4,
      "scenario": "Primalcrux static count P/T recalculates",
      "toughness": 4
    },
    {
      "card_name": "Soulless One",
      "count": 5,
      "power": 5,
      "scenario": "Soulless One static count P/T recalculates",
      "toughness": 5
    },
    {
      "card_name": "Umbra Stalker",
      "count": 3,
      "power": 3,
      "scenario": "Umbra Stalker static count P/T recalculates",
      "toughness": 3
    }
  ],
  "scenario_count": 6
}
```
