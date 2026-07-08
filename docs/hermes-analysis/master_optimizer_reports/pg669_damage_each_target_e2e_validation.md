# Battle Package End-to-End Validation

- Generated UTC: `2026-07-08T19:19:47.754190+00:00`
- Package ID: `pg669_damage_each_target_package_manifest`
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
| battle_execution | `pass` | `{"events": 24, "scenarios": 6}` |

## Battle Execution

```json
{
  "event_count": 24,
  "results": [
    {
      "assigned_total": 2,
      "card_name": "Dual Shot",
      "damage_markers": {
        "E2E Illegal Damage Target": 0,
        "E2E Legal Damage Target 1": 1,
        "E2E Legal Damage Target 2": 1
      },
      "damaged_names": [
        "E2E Legal Damage Target 1",
        "E2E Legal Damage Target 2"
      ],
      "nonmatching_target": "E2E Illegal Damage Target",
      "scenario": "Dual Shot deals 1 damage to each target",
      "targets": [
        "E2E Legal Damage Target 1",
        "E2E Legal Damage Target 2"
      ]
    },
    {
      "assigned_total": 4,
      "card_name": "Furious Reprisal",
      "damage_markers": {
        "E2E Illegal Damage Target": 0,
        "E2E Legal Damage Target 1": 2,
        "E2E Legal Damage Target 2": 2
      },
      "damaged_names": [
        "E2E Legal Damage Target 1",
        "E2E Legal Damage Target 2"
      ],
      "nonmatching_target": "E2E Illegal Damage Target",
      "scenario": "Furious Reprisal deals 2 damage to each target",
      "targets": [
        "E2E Legal Damage Target 1",
        "E2E Legal Damage Target 2"
      ]
    },
    {
      "assigned_total": 6,
      "card_name": "Jagged Lightning",
      "damage_markers": {
        "E2E Illegal Damage Target": 0,
        "E2E Legal Damage Target 1": 3,
        "E2E Legal Damage Target 2": 3
      },
      "damaged_names": [
        "E2E Legal Damage Target 1",
        "E2E Legal Damage Target 2"
      ],
      "nonmatching_target": "E2E Illegal Damage Target",
      "scenario": "Jagged Lightning deals 3 damage to each target",
      "targets": [
        "E2E Legal Damage Target 1",
        "E2E Legal Damage Target 2"
      ]
    },
    {
      "assigned_total": 6,
      "card_name": "Pinnacle of Rage",
      "damage_markers": {
        "E2E Illegal Damage Target": 0,
        "E2E Legal Damage Target 1": 3,
        "E2E Legal Damage Target 2": 3
      },
      "damaged_names": [
        "E2E Legal Damage Target 1",
        "E2E Legal Damage Target 2"
      ],
      "nonmatching_target": "E2E Illegal Damage Target",
      "scenario": "Pinnacle of Rage deals 3 damage to each target",
      "targets": [
        "E2E Legal Damage Target 1",
        "E2E Legal Damage Target 2"
      ]
    },
    {
      "assigned_total": 4,
      "card_name": "Storm of Steel",
      "damage_markers": {
        "E2E Illegal Damage Target": 0,
        "E2E Legal Damage Target 1": 2,
        "E2E Legal Damage Target 2": 2
      },
      "damaged_names": [
        "E2E Legal Damage Target 1",
        "E2E Legal Damage Target 2"
      ],
      "nonmatching_target": "E2E Illegal Damage Target",
      "scenario": "Storm of Steel deals 2 damage to each target",
      "targets": [
        "E2E Legal Damage Target 1",
        "E2E Legal Damage Target 2"
      ]
    },
    {
      "assigned_total": 4,
      "card_name": "Swelter",
      "damage_markers": {
        "E2E Illegal Damage Target": 0,
        "E2E Legal Damage Target 1": 2,
        "E2E Legal Damage Target 2": 2
      },
      "damaged_names": [
        "E2E Legal Damage Target 1",
        "E2E Legal Damage Target 2"
      ],
      "nonmatching_target": "E2E Illegal Damage Target",
      "scenario": "Swelter deals 2 damage to each target",
      "targets": [
        "E2E Legal Damage Target 1",
        "E2E Legal Damage Target 2"
      ]
    }
  ],
  "scenario_count": 6
}
```
