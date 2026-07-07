# Battle Package End-to-End Validation

- Generated UTC: `2026-07-07T07:51:45.915842+00:00`
- Package ID: `pg602_static_controlled_pt_filters_new_server_manifest`
- Status: `pass`
- Database target: `127.0.0.1:15432/halder`
- SQLite DB: `docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db`
- Snapshot: `docs/hermes-analysis/manaloom-knowledge/scripts/known_cards_canonical_snapshot.json`

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
      "card_name": "Builder's Blessing",
      "matching_target": "E2E Controlled P/T Target for Builder's Blessing",
      "refreshed_count": 1,
      "scenario": "Builder's Blessing static controlled P/T applies",
      "source_cards": [
        "Builder's Blessing"
      ],
      "target_power": 2,
      "target_toughness": 4
    },
    {
      "card_name": "Castle",
      "matching_target": "E2E Controlled P/T Target for Castle",
      "refreshed_count": 1,
      "scenario": "Castle static controlled P/T applies",
      "source_cards": [
        "Castle"
      ],
      "target_power": 2,
      "target_toughness": 4
    },
    {
      "card_name": "Dire Fleet Neckbreaker",
      "matching_target": "E2E Controlled P/T Target for Dire Fleet Neckbreaker",
      "refreshed_count": 1,
      "scenario": "Dire Fleet Neckbreaker static controlled P/T applies",
      "source_cards": [
        "Dire Fleet Neckbreaker"
      ],
      "target_power": 4,
      "target_toughness": 2
    },
    {
      "card_name": "Goblin Oriflamme",
      "matching_target": "E2E Controlled P/T Target for Goblin Oriflamme",
      "refreshed_count": 1,
      "scenario": "Goblin Oriflamme static controlled P/T applies",
      "source_cards": [
        "Goblin Oriflamme"
      ],
      "target_power": 3,
      "target_toughness": 2
    },
    {
      "card_name": "Honor of the Pure",
      "matching_target": "E2E Controlled P/T Target for Honor of the Pure",
      "refreshed_count": 1,
      "scenario": "Honor of the Pure static controlled P/T applies",
      "source_cards": [
        "Honor of the Pure"
      ],
      "target_power": 3,
      "target_toughness": 3
    },
    {
      "card_name": "Jacques le Vert",
      "matching_target": "E2E Controlled P/T Target for Jacques le Vert",
      "refreshed_count": 1,
      "scenario": "Jacques le Vert static controlled P/T applies",
      "source_cards": [
        "Jacques le Vert"
      ],
      "target_power": 2,
      "target_toughness": 4
    },
    {
      "card_name": "Kaysa",
      "matching_target": "E2E Controlled P/T Target for Kaysa",
      "refreshed_count": 1,
      "scenario": "Kaysa static controlled P/T applies",
      "source_cards": [
        "Kaysa"
      ],
      "target_power": 3,
      "target_toughness": 3
    },
    {
      "card_name": "Orcish Oriflamme",
      "matching_target": "E2E Controlled P/T Target for Orcish Oriflamme",
      "refreshed_count": 1,
      "scenario": "Orcish Oriflamme static controlled P/T applies",
      "source_cards": [
        "Orcish Oriflamme"
      ],
      "target_power": 3,
      "target_toughness": 2
    },
    {
      "card_name": "War Horn",
      "matching_target": "E2E Controlled P/T Target for War Horn",
      "refreshed_count": 1,
      "scenario": "War Horn static controlled P/T applies",
      "source_cards": [
        "War Horn"
      ],
      "target_power": 3,
      "target_toughness": 2
    }
  ],
  "scenario_count": 9
}
```
