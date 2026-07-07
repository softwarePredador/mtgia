# Battle Package End-to-End Validation

- Generated UTC: `2026-07-07T07:28:47.142592+00:00`
- Package ID: `pg601_static_filtered_count_pt_new_server_manifest`
- Status: `pass`
- Database target: `127.0.0.1:15432/halder`
- SQLite DB: `docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db`
- Snapshot: `docs/hermes-analysis/manaloom-knowledge/scripts/known_cards_canonical_snapshot.json`

## Stage Results

| Stage | Status | Evidence |
| --- | --- | --- |
| postgres_source_of_truth | `pass` | `{"validated_rows": 10}` |
| sqlite_hermes_cache | `pass` | `{"validated_rows": 10}` |
| canonical_snapshot_fallback | `pass` | `{"validated_cards": 10}` |
| runtime_get_card_effect | `pass` | `{"validated_cards": 10}` |
| battle_execution | `pass` | `{"events": 10, "scenarios": 10}` |

## Battle Execution

```json
{
  "event_count": 10,
  "results": [
    {
      "card_name": "Drove of Elves",
      "count": 2,
      "power": 2,
      "scenario": "Drove of Elves static count P/T recalculates",
      "toughness": 2
    },
    {
      "card_name": "Faerie Swarm",
      "count": 2,
      "power": 2,
      "scenario": "Faerie Swarm static count P/T recalculates",
      "toughness": 2
    },
    {
      "card_name": "Horde of Boggarts",
      "count": 2,
      "power": 2,
      "scenario": "Horde of Boggarts static count P/T recalculates",
      "toughness": 2
    },
    {
      "card_name": "Keldon Warlord",
      "count": 2,
      "power": 2,
      "scenario": "Keldon Warlord static count P/T recalculates",
      "toughness": 2
    },
    {
      "card_name": "Kithkin Rabble",
      "count": 2,
      "power": 2,
      "scenario": "Kithkin Rabble static count P/T recalculates",
      "toughness": 2
    },
    {
      "card_name": "Maraxus of Keld",
      "count": 3,
      "power": 3,
      "scenario": "Maraxus of Keld static count P/T recalculates",
      "toughness": 3
    },
    {
      "card_name": "Matca Rioters",
      "count": 4,
      "power": 4,
      "scenario": "Matca Rioters static count P/T recalculates",
      "toughness": 4
    },
    {
      "card_name": "Plague Rats",
      "count": 2,
      "power": 2,
      "scenario": "Plague Rats static count P/T recalculates",
      "toughness": 2
    },
    {
      "card_name": "Regal Bunnicorn",
      "count": 2,
      "power": 2,
      "scenario": "Regal Bunnicorn static count P/T recalculates",
      "toughness": 2
    },
    {
      "card_name": "Territorial Maro",
      "count": 4,
      "power": 8,
      "scenario": "Territorial Maro static count P/T recalculates",
      "toughness": 8
    }
  ],
  "scenario_count": 10
}
```
