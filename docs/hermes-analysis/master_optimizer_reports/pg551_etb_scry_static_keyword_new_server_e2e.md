# Battle Package End-to-End Validation

- Generated UTC: `2026-07-06T05:01:26.940588+00:00`
- Package ID: `pg551_etb_scry_static_keyword_new_server_package_manifest`
- Status: `pass`
- Database target: `143.198.230.247:5433/halder`
- SQLite DB: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db`
- Snapshot: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/manaloom-knowledge/scripts/known_cards_canonical_snapshot.json`

## Stage Results

| Stage | Status | Evidence |
| --- | --- | --- |
| postgres_source_of_truth | `pass` | `{"validated_rows": 11}` |
| sqlite_hermes_cache | `pass` | `{"validated_rows": 11}` |
| canonical_snapshot_fallback | `pass` | `{"validated_cards": 11}` |
| runtime_get_card_effect | `pass` | `{"validated_cards": 11}` |
| battle_execution | `pass` | `{"events": 11, "scenarios": 11}` |

## Battle Execution

```json
{
  "event_count": 11,
  "results": [
    {
      "card_name": "Augury Owl",
      "looked_at": [
        "Low Priority Land",
        "High Priority Spell",
        "Medium Priority Creature"
      ],
      "scenario": "Augury Owl enters and scries 3",
      "scry_count": 3,
      "top_after": [
        "Medium Priority Creature",
        "High Priority Spell",
        "Low Priority Land"
      ],
      "validated_keywords": [
        "flying"
      ]
    },
    {
      "card_name": "Cloudreader Sphinx",
      "looked_at": [
        "Low Priority Land",
        "High Priority Spell"
      ],
      "scenario": "Cloudreader Sphinx enters and scries 2",
      "scry_count": 2,
      "top_after": [
        "High Priority Spell",
        "Low Priority Land"
      ],
      "validated_keywords": [
        "flying"
      ]
    },
    {
      "card_name": "Faerie Seer",
      "looked_at": [
        "Low Priority Land",
        "High Priority Spell"
      ],
      "scenario": "Faerie Seer enters and scries 2",
      "scry_count": 2,
      "top_after": [
        "High Priority Spell",
        "Low Priority Land"
      ],
      "validated_keywords": [
        "flying"
      ]
    },
    {
      "card_name": "Glider Kids",
      "looked_at": [
        "Low Priority Land"
      ],
      "scenario": "Glider Kids enters and scries 1",
      "scry_count": 1,
      "top_after": [
        "Low Priority Land"
      ],
      "validated_keywords": [
        "flying"
      ]
    },
    {
      "card_name": "Grey Havens Navigator",
      "looked_at": [
        "Low Priority Land"
      ],
      "scenario": "Grey Havens Navigator enters and scries 1",
      "scry_count": 1,
      "top_after": [
        "Low Priority Land"
      ],
      "validated_keywords": [
        "flash"
      ]
    },
    {
      "card_name": "Horizon Scholar",
      "looked_at": [
        "Low Priority Land",
        "High Priority Spell"
      ],
      "scenario": "Horizon Scholar enters and scries 2",
      "scry_count": 2,
      "top_after": [
        "High Priority Spell",
        "Low Priority Land"
      ],
      "validated_keywords": [
        "flying"
      ]
    },
    {
      "card_name": "Senate Griffin",
      "looked_at": [
        "Low Priority Land"
      ],
      "scenario": "Senate Griffin enters and scries 1",
      "scry_count": 1,
      "top_after": [
        "Low Priority Land"
      ],
      "validated_keywords": [
        "flying"
      ]
    },
    {
      "card_name": "Silver Raven",
      "looked_at": [
        "Low Priority Land"
      ],
      "scenario": "Silver Raven enters and scries 1",
      "scry_count": 1,
      "top_after": [
        "Low Priority Land"
      ],
      "validated_keywords": [
        "flying"
      ]
    },
    {
      "card_name": "Thaumaturge's Familiar",
      "looked_at": [
        "Low Priority Land"
      ],
      "scenario": "Thaumaturge's Familiar enters and scries 1",
      "scry_count": 1,
      "top_after": [
        "Low Priority Land"
      ],
      "validated_keywords": [
        "flying"
      ]
    },
    {
      "card_name": "Wall of Runes",
      "looked_at": [
        "Low Priority Land"
      ],
      "scenario": "Wall of Runes enters and scries 1",
      "scry_count": 1,
      "top_after": [
        "Low Priority Land"
      ],
      "validated_keywords": [
        "defender"
      ]
    },
    {
      "card_name": "Willow-Wind",
      "looked_at": [
        "Low Priority Land",
        "High Priority Spell"
      ],
      "scenario": "Willow-Wind enters and scries 2",
      "scry_count": 2,
      "top_after": [
        "High Priority Spell",
        "Low Priority Land"
      ],
      "validated_keywords": [
        "flying"
      ]
    }
  ],
  "scenario_count": 11
}
```
