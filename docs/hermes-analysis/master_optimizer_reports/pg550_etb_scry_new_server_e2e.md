# Battle Package End-to-End Validation

- Generated UTC: `2026-07-06T04:46:57.402058+00:00`
- Package ID: `pg550_etb_scry_new_server_package_manifest`
- Status: `pass`
- Database target: `143.198.230.247:5433/halder`
- SQLite DB: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db`
- Snapshot: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/manaloom-knowledge/scripts/known_cards_canonical_snapshot.json`

## Stage Results

| Stage | Status | Evidence |
| --- | --- | --- |
| postgres_source_of_truth | `pass` | `{"validated_rows": 9}` |
| sqlite_hermes_cache | `pass` | `{"validated_rows": 9}` |
| canonical_snapshot_fallback | `pass` | `{"validated_cards": 9}` |
| runtime_get_card_effect | `pass` | `{"validated_cards": 9}` |
| battle_execution | `pass` | `{"events": 9, "scenarios": 9}` |

## Battle Execution

```json
{
  "event_count": 9,
  "results": [
    {
      "card_name": "Automatic Librarian",
      "looked_at": [
        "Low Priority Land",
        "High Priority Spell"
      ],
      "scenario": "Automatic Librarian enters and scries 2",
      "scry_count": 2,
      "top_after": [
        "High Priority Spell",
        "Low Priority Land"
      ]
    },
    {
      "card_name": "Chrome Cat",
      "looked_at": [
        "Low Priority Land"
      ],
      "scenario": "Chrome Cat enters and scries 1",
      "scry_count": 1,
      "top_after": [
        "Low Priority Land"
      ]
    },
    {
      "card_name": "Galadhrim Guide",
      "looked_at": [
        "Low Priority Land",
        "High Priority Spell"
      ],
      "scenario": "Galadhrim Guide enters and scries 2",
      "scry_count": 2,
      "top_after": [
        "High Priority Spell",
        "Low Priority Land"
      ]
    },
    {
      "card_name": "Lost Legion",
      "looked_at": [
        "Low Priority Land",
        "High Priority Spell"
      ],
      "scenario": "Lost Legion enters and scries 2",
      "scry_count": 2,
      "top_after": [
        "High Priority Spell",
        "Low Priority Land"
      ]
    },
    {
      "card_name": "Octoprophet",
      "looked_at": [
        "Low Priority Land",
        "High Priority Spell"
      ],
      "scenario": "Octoprophet enters and scries 2",
      "scry_count": 2,
      "top_after": [
        "High Priority Spell",
        "Low Priority Land"
      ]
    },
    {
      "card_name": "Omenspeaker",
      "looked_at": [
        "Low Priority Land",
        "High Priority Spell"
      ],
      "scenario": "Omenspeaker enters and scries 2",
      "scry_count": 2,
      "top_after": [
        "High Priority Spell",
        "Low Priority Land"
      ]
    },
    {
      "card_name": "Prophet of the Peak",
      "looked_at": [
        "Low Priority Land",
        "High Priority Spell"
      ],
      "scenario": "Prophet of the Peak enters and scries 2",
      "scry_count": 2,
      "top_after": [
        "High Priority Spell",
        "Low Priority Land"
      ]
    },
    {
      "card_name": "Rumbling Sentry",
      "looked_at": [
        "Low Priority Land"
      ],
      "scenario": "Rumbling Sentry enters and scries 1",
      "scry_count": 1,
      "top_after": [
        "Low Priority Land"
      ]
    },
    {
      "card_name": "Sage's Row Savant",
      "looked_at": [
        "Low Priority Land",
        "High Priority Spell"
      ],
      "scenario": "Sage's Row Savant enters and scries 2",
      "scry_count": 2,
      "top_after": [
        "High Priority Spell",
        "Low Priority Land"
      ]
    }
  ],
  "scenario_count": 9
}
```
