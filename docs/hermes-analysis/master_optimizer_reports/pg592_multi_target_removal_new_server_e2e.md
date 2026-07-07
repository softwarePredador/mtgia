# Battle Package End-to-End Validation

- Generated UTC: `2026-07-07T04:12:59.606535+00:00`
- Package ID: `pg592_multi_target_removal_new_server_package_manifest`
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
| battle_execution | `pass` | `{"events": 67, "scenarios": 15}` |

## Battle Execution

```json
{
  "event_count": 67,
  "results": [
    {
      "battlefield_names": [
        "E2E Illegal Removal Target"
      ],
      "card_name": "Aether Gale",
      "destination": "hand",
      "moved_names": [
        "E2E Legal Removal Target 1",
        "E2E Legal Removal Target 2",
        "E2E Legal Removal Target 3",
        "E2E Legal Removal Target 4",
        "E2E Legal Removal Target 5",
        "E2E Legal Removal Target 6"
      ],
      "nonmatching_target": "E2E Illegal Removal Target",
      "resolved_names": [
        "E2E Legal Removal Target 1",
        "E2E Legal Removal Target 2",
        "E2E Legal Removal Target 3",
        "E2E Legal Removal Target 4",
        "E2E Legal Removal Target 5",
        "E2E Legal Removal Target 6"
      ],
      "scenario": "Aether Gale removes 6 legal targets",
      "targets": [
        "E2E Legal Removal Target 1",
        "E2E Legal Removal Target 2",
        "E2E Legal Removal Target 3",
        "E2E Legal Removal Target 4",
        "E2E Legal Removal Target 5",
        "E2E Legal Removal Target 6"
      ]
    },
    {
      "battlefield_names": [
        "E2E Illegal Removal Target"
      ],
      "card_name": "Captivating Gyre",
      "destination": "hand",
      "moved_names": [
        "E2E Legal Removal Target 1",
        "E2E Legal Removal Target 2",
        "E2E Legal Removal Target 3"
      ],
      "nonmatching_target": "E2E Illegal Removal Target",
      "resolved_names": [
        "E2E Legal Removal Target 1",
        "E2E Legal Removal Target 2",
        "E2E Legal Removal Target 3"
      ],
      "scenario": "Captivating Gyre removes 3 legal targets",
      "targets": [
        "E2E Legal Removal Target 1",
        "E2E Legal Removal Target 2",
        "E2E Legal Removal Target 3"
      ]
    },
    {
      "battlefield_names": [
        "E2E Illegal Removal Target"
      ],
      "card_name": "Curtains' Call",
      "destination": "graveyard",
      "moved_names": [
        "E2E Legal Removal Target 1",
        "E2E Legal Removal Target 2"
      ],
      "nonmatching_target": "E2E Illegal Removal Target",
      "resolved_names": [
        "E2E Legal Removal Target 1",
        "E2E Legal Removal Target 2"
      ],
      "scenario": "Curtains' Call removes 2 legal targets",
      "targets": [
        "E2E Legal Removal Target 1",
        "E2E Legal Removal Target 2"
      ]
    },
    {
      "battlefield_names": [
        "E2E Illegal Removal Target"
      ],
      "card_name": "Dust to Dust",
      "destination": "exile",
      "moved_names": [
        "E2E Legal Removal Target 1",
        "E2E Legal Removal Target 2"
      ],
      "nonmatching_target": "E2E Illegal Removal Target",
      "resolved_names": [
        "E2E Legal Removal Target 1",
        "E2E Legal Removal Target 2"
      ],
      "scenario": "Dust to Dust removes 2 legal targets",
      "targets": [
        "E2E Legal Removal Target 1",
        "E2E Legal Removal Target 2"
      ]
    },
    {
      "battlefield_names": [
        "E2E Illegal Removal Target"
      ],
      "card_name": "Hex",
      "destination": "graveyard",
      "moved_names": [
        "E2E Legal Removal Target 1",
        "E2E Legal Removal Target 2",
        "E2E Legal Removal Target 3",
        "E2E Legal Removal Target 4",
        "E2E Legal Removal Target 5",
        "E2E Legal Removal Target 6"
      ],
      "nonmatching_target": "E2E Illegal Removal Target",
      "resolved_names": [
        "E2E Legal Removal Target 1",
        "E2E Legal Removal Target 2",
        "E2E Legal Removal Target 3",
        "E2E Legal Removal Target 4",
        "E2E Legal Removal Target 5",
        "E2E Legal Removal Target 6"
      ],
      "scenario": "Hex removes 6 legal targets",
      "targets": [
        "E2E Legal Removal Target 1",
        "E2E Legal Removal Target 2",
        "E2E Legal Removal Target 3",
        "E2E Legal Removal Target 4",
        "E2E Legal Removal Target 5",
        "E2E Legal Removal Target 6"
      ]
    },
    {
      "battlefield_names": [
        "E2E Illegal Removal Target"
      ],
      "card_name": "Into the Core",
      "destination": "exile",
      "moved_names": [
        "E2E Legal Removal Target 1",
        "E2E Legal Removal Target 2"
      ],
      "nonmatching_target": "E2E Illegal Removal Target",
      "resolved_names": [
        "E2E Legal Removal Target 1",
        "E2E Legal Removal Target 2"
      ],
      "scenario": "Into the Core removes 2 legal targets",
      "targets": [
        "E2E Legal Removal Target 1",
        "E2E Legal Removal Target 2"
      ]
    },
    {
      "battlefield_names": [
        "E2E Illegal Removal Target"
      ],
      "card_name": "Into the Void",
      "destination": "hand",
      "moved_names": [
        "E2E Legal Removal Target 1",
        "E2E Legal Removal Target 2"
      ],
      "nonmatching_target": "E2E Illegal Removal Target",
      "resolved_names": [
        "E2E Legal Removal Target 1",
        "E2E Legal Removal Target 2"
      ],
      "scenario": "Into the Void removes 2 legal targets",
      "targets": [
        "E2E Legal Removal Target 1",
        "E2E Legal Removal Target 2"
      ]
    },
    {
      "battlefield_names": [
        "E2E Illegal Removal Target"
      ],
      "card_name": "Peace and Quiet",
      "destination": "graveyard",
      "moved_names": [
        "E2E Legal Removal Target 1",
        "E2E Legal Removal Target 2"
      ],
      "nonmatching_target": "E2E Illegal Removal Target",
      "resolved_names": [
        "E2E Legal Removal Target 1",
        "E2E Legal Removal Target 2"
      ],
      "scenario": "Peace and Quiet removes 2 legal targets",
      "targets": [
        "E2E Legal Removal Target 1",
        "E2E Legal Removal Target 2"
      ]
    },
    {
      "battlefield_names": [
        "E2E Illegal Removal Target"
      ],
      "card_name": "Quicksilver Geyser",
      "destination": "hand",
      "moved_names": [
        "E2E Legal Removal Target 1",
        "E2E Legal Removal Target 2"
      ],
      "nonmatching_target": "E2E Illegal Removal Target",
      "resolved_names": [
        "E2E Legal Removal Target 1",
        "E2E Legal Removal Target 2"
      ],
      "scenario": "Quicksilver Geyser removes 2 legal targets",
      "targets": [
        "E2E Legal Removal Target 1",
        "E2E Legal Removal Target 2"
      ]
    },
    {
      "battlefield_names": [
        "E2E Illegal Removal Target"
      ],
      "card_name": "Rack and Ruin",
      "destination": "graveyard",
      "moved_names": [
        "E2E Legal Removal Target 1",
        "E2E Legal Removal Target 2"
      ],
      "nonmatching_target": "E2E Illegal Removal Target",
      "resolved_names": [
        "E2E Legal Removal Target 1",
        "E2E Legal Removal Target 2"
      ],
      "scenario": "Rack and Ruin removes 2 legal targets",
      "targets": [
        "E2E Legal Removal Target 1",
        "E2E Legal Removal Target 2"
      ]
    },
    {
      "battlefield_names": [
        "E2E Illegal Removal Target"
      ],
      "card_name": "Rain of Salt",
      "destination": "graveyard",
      "moved_names": [
        "E2E Legal Removal Target 1",
        "E2E Legal Removal Target 2"
      ],
      "nonmatching_target": "E2E Illegal Removal Target",
      "resolved_names": [
        "E2E Legal Removal Target 1",
        "E2E Legal Removal Target 2"
      ],
      "scenario": "Rain of Salt removes 2 legal targets",
      "targets": [
        "E2E Legal Removal Target 1",
        "E2E Legal Removal Target 2"
      ]
    },
    {
      "battlefield_names": [
        "E2E Illegal Removal Target"
      ],
      "card_name": "Sea God's Scorn",
      "destination": "hand",
      "moved_names": [
        "E2E Legal Removal Target 1",
        "E2E Legal Removal Target 2",
        "E2E Legal Removal Target 3"
      ],
      "nonmatching_target": "E2E Illegal Removal Target",
      "resolved_names": [
        "E2E Legal Removal Target 1",
        "E2E Legal Removal Target 2",
        "E2E Legal Removal Target 3"
      ],
      "scenario": "Sea God's Scorn removes 3 legal targets",
      "targets": [
        "E2E Legal Removal Target 1",
        "E2E Legal Removal Target 2",
        "E2E Legal Removal Target 3"
      ]
    },
    {
      "battlefield_names": [
        "E2E Illegal Removal Target"
      ],
      "card_name": "Undo",
      "destination": "hand",
      "moved_names": [
        "E2E Legal Removal Target 1",
        "E2E Legal Removal Target 2"
      ],
      "nonmatching_target": "E2E Illegal Removal Target",
      "resolved_names": [
        "E2E Legal Removal Target 1",
        "E2E Legal Removal Target 2"
      ],
      "scenario": "Undo removes 2 legal targets",
      "targets": [
        "E2E Legal Removal Target 1",
        "E2E Legal Removal Target 2"
      ]
    },
    {
      "battlefield_names": [
        "E2E Illegal Removal Target"
      ],
      "card_name": "Violent Ultimatum",
      "destination": "graveyard",
      "moved_names": [
        "E2E Legal Removal Target 1",
        "E2E Legal Removal Target 2",
        "E2E Legal Removal Target 3"
      ],
      "nonmatching_target": "E2E Illegal Removal Target",
      "resolved_names": [
        "E2E Legal Removal Target 1",
        "E2E Legal Removal Target 2",
        "E2E Legal Removal Target 3"
      ],
      "scenario": "Violent Ultimatum removes 3 legal targets",
      "targets": [
        "E2E Legal Removal Target 1",
        "E2E Legal Removal Target 2",
        "E2E Legal Removal Target 3"
      ]
    },
    {
      "battlefield_names": [
        "E2E Illegal Removal Target"
      ],
      "card_name": "Waterwhirl",
      "destination": "hand",
      "moved_names": [
        "E2E Legal Removal Target 1",
        "E2E Legal Removal Target 2"
      ],
      "nonmatching_target": "E2E Illegal Removal Target",
      "resolved_names": [
        "E2E Legal Removal Target 1",
        "E2E Legal Removal Target 2"
      ],
      "scenario": "Waterwhirl removes 2 legal targets",
      "targets": [
        "E2E Legal Removal Target 1",
        "E2E Legal Removal Target 2"
      ]
    }
  ],
  "scenario_count": 15
}
```
