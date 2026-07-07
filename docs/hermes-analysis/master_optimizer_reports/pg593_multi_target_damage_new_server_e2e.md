# Battle Package End-to-End Validation

- Generated UTC: `2026-07-07T04:35:48.040354+00:00`
- Package ID: `pg593_multi_target_damage_new_server_package_manifest`
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
| battle_execution | `pass` | `{"events": 74, "scenarios": 15}` |

## Battle Execution

```json
{
  "event_count": 74,
  "results": [
    {
      "assigned_total": 3,
      "card_name": "Aerial Volley",
      "damage_markers": {
        "E2E Illegal Damage Target": 0,
        "E2E Legal Damage Target 1": 1,
        "E2E Legal Damage Target 2": 1,
        "E2E Legal Damage Target 3": 1
      },
      "damaged_names": [
        "E2E Legal Damage Target 1",
        "E2E Legal Damage Target 2",
        "E2E Legal Damage Target 3"
      ],
      "nonmatching_target": "E2E Illegal Damage Target",
      "scenario": "Aerial Volley divides 3 damage",
      "targets": [
        "E2E Legal Damage Target 1",
        "E2E Legal Damage Target 2",
        "E2E Legal Damage Target 3"
      ]
    },
    {
      "assigned_total": 3,
      "card_name": "Arc Lightning",
      "damage_markers": {
        "E2E Illegal Damage Target": 0,
        "E2E Legal Damage Target 1": 1,
        "E2E Legal Damage Target 2": 1,
        "E2E Legal Damage Target 3": 1
      },
      "damaged_names": [
        "E2E Legal Damage Target 1",
        "E2E Legal Damage Target 2",
        "E2E Legal Damage Target 3"
      ],
      "nonmatching_target": "E2E Illegal Damage Target",
      "scenario": "Arc Lightning divides 3 damage",
      "targets": [
        "E2E Legal Damage Target 1",
        "E2E Legal Damage Target 2",
        "E2E Legal Damage Target 3"
      ]
    },
    {
      "assigned_total": 5,
      "card_name": "Boulderfall",
      "damage_markers": {
        "E2E Illegal Damage Target": 0,
        "E2E Legal Damage Target 1": 2,
        "E2E Legal Damage Target 2": 1,
        "E2E Legal Damage Target 3": 1
      },
      "damaged_names": [
        "E2E Legal Damage Target 1",
        "E2E Legal Damage Target 2",
        "E2E Legal Damage Target 3",
        "Opponent"
      ],
      "nonmatching_target": "E2E Illegal Damage Target",
      "scenario": "Boulderfall divides 5 damage",
      "targets": [
        "E2E Legal Damage Target 1",
        "E2E Legal Damage Target 2",
        "E2E Legal Damage Target 3"
      ]
    },
    {
      "assigned_total": 2,
      "card_name": "Chandra's Pyrohelix",
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
      "scenario": "Chandra's Pyrohelix divides 2 damage",
      "targets": [
        "E2E Legal Damage Target 1",
        "E2E Legal Damage Target 2"
      ]
    },
    {
      "assigned_total": 3,
      "card_name": "Deft Dismissal",
      "damage_markers": {
        "E2E Illegal Damage Target": 0,
        "E2E Legal Damage Target 1": 1,
        "E2E Legal Damage Target 2": 1,
        "E2E Legal Damage Target 3": 1
      },
      "damaged_names": [
        "E2E Legal Damage Target 1",
        "E2E Legal Damage Target 2",
        "E2E Legal Damage Target 3"
      ],
      "nonmatching_target": "E2E Illegal Damage Target",
      "scenario": "Deft Dismissal divides 3 damage",
      "targets": [
        "E2E Legal Damage Target 1",
        "E2E Legal Damage Target 2",
        "E2E Legal Damage Target 3"
      ]
    },
    {
      "assigned_total": 3,
      "card_name": "Fire at Will",
      "damage_markers": {
        "E2E Illegal Damage Target": 0,
        "E2E Legal Damage Target 1": 1,
        "E2E Legal Damage Target 2": 1,
        "E2E Legal Damage Target 3": 1
      },
      "damaged_names": [
        "E2E Legal Damage Target 1",
        "E2E Legal Damage Target 2",
        "E2E Legal Damage Target 3"
      ],
      "nonmatching_target": "E2E Illegal Damage Target",
      "scenario": "Fire at Will divides 3 damage",
      "targets": [
        "E2E Legal Damage Target 1",
        "E2E Legal Damage Target 2",
        "E2E Legal Damage Target 3"
      ]
    },
    {
      "assigned_total": 3,
      "card_name": "Flames of the Firebrand",
      "damage_markers": {
        "E2E Illegal Damage Target": 0,
        "E2E Legal Damage Target 1": 1,
        "E2E Legal Damage Target 2": 1,
        "E2E Legal Damage Target 3": 1
      },
      "damaged_names": [
        "E2E Legal Damage Target 1",
        "E2E Legal Damage Target 2",
        "E2E Legal Damage Target 3"
      ],
      "nonmatching_target": "E2E Illegal Damage Target",
      "scenario": "Flames of the Firebrand divides 3 damage",
      "targets": [
        "E2E Legal Damage Target 1",
        "E2E Legal Damage Target 2",
        "E2E Legal Damage Target 3"
      ]
    },
    {
      "assigned_total": 2,
      "card_name": "Forked Bolt",
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
      "scenario": "Forked Bolt divides 2 damage",
      "targets": [
        "E2E Legal Damage Target 1",
        "E2E Legal Damage Target 2"
      ]
    },
    {
      "assigned_total": 4,
      "card_name": "Forked Lightning",
      "damage_markers": {
        "E2E Illegal Damage Target": 0,
        "E2E Legal Damage Target 1": 2,
        "E2E Legal Damage Target 2": 1,
        "E2E Legal Damage Target 3": 1
      },
      "damaged_names": [
        "E2E Legal Damage Target 1",
        "E2E Legal Damage Target 2",
        "E2E Legal Damage Target 3"
      ],
      "nonmatching_target": "E2E Illegal Damage Target",
      "scenario": "Forked Lightning divides 4 damage",
      "targets": [
        "E2E Legal Damage Target 1",
        "E2E Legal Damage Target 2",
        "E2E Legal Damage Target 3"
      ]
    },
    {
      "assigned_total": 3,
      "card_name": "Ignite Disorder",
      "damage_markers": {
        "E2E Illegal Damage Target": 0,
        "E2E Legal Damage Target 1": 1,
        "E2E Legal Damage Target 2": 1,
        "E2E Legal Damage Target 3": 1
      },
      "damaged_names": [
        "E2E Legal Damage Target 1",
        "E2E Legal Damage Target 2",
        "E2E Legal Damage Target 3"
      ],
      "nonmatching_target": "E2E Illegal Damage Target",
      "scenario": "Ignite Disorder divides 3 damage",
      "targets": [
        "E2E Legal Damage Target 1",
        "E2E Legal Damage Target 2",
        "E2E Legal Damage Target 3"
      ]
    },
    {
      "assigned_total": 3,
      "card_name": "Magic Missile",
      "damage_markers": {
        "E2E Illegal Damage Target": 0,
        "E2E Legal Damage Target 1": 1,
        "E2E Legal Damage Target 2": 1,
        "E2E Legal Damage Target 3": 1
      },
      "damaged_names": [
        "E2E Legal Damage Target 1",
        "E2E Legal Damage Target 2",
        "E2E Legal Damage Target 3"
      ],
      "nonmatching_target": "E2E Illegal Damage Target",
      "scenario": "Magic Missile divides 3 damage",
      "targets": [
        "E2E Legal Damage Target 1",
        "E2E Legal Damage Target 2",
        "E2E Legal Damage Target 3"
      ]
    },
    {
      "assigned_total": 4,
      "card_name": "Pyrotechnics",
      "damage_markers": {
        "E2E Illegal Damage Target": 0,
        "E2E Legal Damage Target 1": 1,
        "E2E Legal Damage Target 2": 1,
        "E2E Legal Damage Target 3": 1
      },
      "damaged_names": [
        "E2E Legal Damage Target 1",
        "E2E Legal Damage Target 2",
        "E2E Legal Damage Target 3",
        "Opponent"
      ],
      "nonmatching_target": "E2E Illegal Damage Target",
      "scenario": "Pyrotechnics divides 4 damage",
      "targets": [
        "E2E Legal Damage Target 1",
        "E2E Legal Damage Target 2",
        "E2E Legal Damage Target 3"
      ]
    },
    {
      "assigned_total": 5,
      "card_name": "Roil's Retribution",
      "damage_markers": {
        "E2E Illegal Damage Target": 0,
        "E2E Legal Damage Target 1": 3,
        "E2E Legal Damage Target 2": 1,
        "E2E Legal Damage Target 3": 1
      },
      "damaged_names": [
        "E2E Legal Damage Target 1",
        "E2E Legal Damage Target 2",
        "E2E Legal Damage Target 3"
      ],
      "nonmatching_target": "E2E Illegal Damage Target",
      "scenario": "Roil's Retribution divides 5 damage",
      "targets": [
        "E2E Legal Damage Target 1",
        "E2E Legal Damage Target 2",
        "E2E Legal Damage Target 3"
      ]
    },
    {
      "assigned_total": 6,
      "card_name": "Spreading Flames",
      "damage_markers": {
        "E2E Illegal Damage Target": 0,
        "E2E Legal Damage Target 1": 4,
        "E2E Legal Damage Target 2": 1,
        "E2E Legal Damage Target 3": 1
      },
      "damaged_names": [
        "E2E Legal Damage Target 1",
        "E2E Legal Damage Target 2",
        "E2E Legal Damage Target 3"
      ],
      "nonmatching_target": "E2E Illegal Damage Target",
      "scenario": "Spreading Flames divides 6 damage",
      "targets": [
        "E2E Legal Damage Target 1",
        "E2E Legal Damage Target 2",
        "E2E Legal Damage Target 3"
      ]
    },
    {
      "assigned_total": 2,
      "card_name": "Twin Bolt",
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
      "scenario": "Twin Bolt divides 2 damage",
      "targets": [
        "E2E Legal Damage Target 1",
        "E2E Legal Damage Target 2"
      ]
    }
  ],
  "scenario_count": 15
}
```
