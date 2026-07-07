# Battle Package End-to-End Validation

- Generated UTC: `2026-07-07T06:56:26.382155+00:00`
- Package ID: `pg599_static_count_pt_new_server_manifest`
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
| battle_execution | `pass` | `{"events": 13, "scenarios": 13}` |

## Battle Execution

```json
{
  "event_count": 13,
  "results": [
    {
      "card_name": "Battle Squadron",
      "count": 2,
      "power": 2,
      "scenario": "Battle Squadron static count P/T recalculates",
      "toughness": 2
    },
    {
      "card_name": "Beast of Burden",
      "count": 3,
      "power": 3,
      "scenario": "Beast of Burden static count P/T recalculates",
      "toughness": 3
    },
    {
      "card_name": "Burrowguard Mentor",
      "count": 2,
      "power": 2,
      "scenario": "Burrowguard Mentor static count P/T recalculates",
      "toughness": 2
    },
    {
      "card_name": "Crusader of Odric",
      "count": 2,
      "power": 2,
      "scenario": "Crusader of Odric static count P/T recalculates",
      "toughness": 2
    },
    {
      "card_name": "Dakkon Blackblade",
      "count": 2,
      "power": 2,
      "scenario": "Dakkon Blackblade static count P/T recalculates",
      "toughness": 2
    },
    {
      "card_name": "Dungrove Elder",
      "count": 2,
      "power": 2,
      "scenario": "Dungrove Elder static count P/T recalculates",
      "toughness": 2
    },
    {
      "card_name": "Heedless One",
      "count": 3,
      "power": 3,
      "scenario": "Heedless One static count P/T recalculates",
      "toughness": 3
    },
    {
      "card_name": "Krovikan Mist",
      "count": 3,
      "power": 3,
      "scenario": "Krovikan Mist static count P/T recalculates",
      "toughness": 3
    },
    {
      "card_name": "Molimo, Maro-Sorcerer",
      "count": 2,
      "power": 2,
      "scenario": "Molimo, Maro-Sorcerer static count P/T recalculates",
      "toughness": 2
    },
    {
      "card_name": "Nightmare",
      "count": 2,
      "power": 2,
      "scenario": "Nightmare static count P/T recalculates",
      "toughness": 2
    },
    {
      "card_name": "Reckless One",
      "count": 3,
      "power": 3,
      "scenario": "Reckless One static count P/T recalculates",
      "toughness": 3
    },
    {
      "card_name": "Scion of the Wild",
      "count": 2,
      "power": 2,
      "scenario": "Scion of the Wild static count P/T recalculates",
      "toughness": 2
    },
    {
      "card_name": "Squelching Leeches",
      "count": 2,
      "power": 2,
      "scenario": "Squelching Leeches static count P/T recalculates",
      "toughness": 2
    }
  ],
  "scenario_count": 13
}
```
