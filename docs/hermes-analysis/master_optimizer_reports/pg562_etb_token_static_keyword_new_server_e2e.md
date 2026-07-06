# Battle Package End-to-End Validation

- Generated UTC: `2026-07-06T11:11:59.116924+00:00`
- Package ID: `pg562_etb_token_static_keyword_new_server_package_manifest`
- Status: `pass`
- Database target: `143.198.230.247:5433/halder`
- SQLite DB: `docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db`
- Snapshot: `docs/hermes-analysis/manaloom-knowledge/scripts/known_cards_canonical_snapshot.json`

## Stage Results

| Stage | Status | Evidence |
| --- | --- | --- |
| postgres_source_of_truth | `pass` | `{"validated_rows": 27}` |
| sqlite_hermes_cache | `pass` | `{"validated_rows": 27}` |
| canonical_snapshot_fallback | `pass` | `{"validated_cards": 27}` |
| runtime_get_card_effect | `pass` | `{"validated_cards": 27}` |
| battle_execution | `pass` | `{"events": 27, "scenarios": 27}` |

## Battle Execution

```json
{
  "event_count": 27,
  "results": [
    {
      "card_name": "Armada Wurm",
      "scenario": "Armada Wurm enters and creates modeled creature tokens",
      "token_names": [
        "Wurm Token"
      ],
      "tokens_created": 1,
      "validated_keywords": [
        "trample"
      ]
    },
    {
      "card_name": "Aspiring Aeronaut",
      "scenario": "Aspiring Aeronaut enters and creates modeled creature tokens",
      "token_names": [
        "Thopter Token"
      ],
      "tokens_created": 1,
      "validated_keywords": [
        "flying"
      ]
    },
    {
      "card_name": "Attended Knight",
      "scenario": "Attended Knight enters and creates modeled creature tokens",
      "token_names": [
        "Soldier Token"
      ],
      "tokens_created": 1,
      "validated_keywords": [
        "first_strike"
      ]
    },
    {
      "card_name": "Chimney Rabble",
      "scenario": "Chimney Rabble enters and creates modeled creature tokens",
      "token_names": [
        "Phyrexian Goblin Token"
      ],
      "tokens_created": 1,
      "validated_keywords": [
        "haste"
      ]
    },
    {
      "card_name": "Crested Herdcaller",
      "scenario": "Crested Herdcaller enters and creates modeled creature tokens",
      "token_names": [
        "Dinosaur Token"
      ],
      "tokens_created": 1,
      "validated_keywords": [
        "trample"
      ]
    },
    {
      "card_name": "Dragoon's Wyvern",
      "scenario": "Dragoon's Wyvern enters and creates modeled creature tokens",
      "token_names": [
        "Hero Token"
      ],
      "tokens_created": 1,
      "validated_keywords": [
        "flying"
      ]
    },
    {
      "card_name": "Elturgard Ranger",
      "scenario": "Elturgard Ranger enters and creates modeled creature tokens",
      "token_names": [
        "Wolf Token"
      ],
      "tokens_created": 1,
      "validated_keywords": [
        "reach"
      ]
    },
    {
      "card_name": "Experimental Aviator",
      "scenario": "Experimental Aviator enters and creates modeled creature tokens",
      "token_names": [
        "Thopter Token",
        "Thopter Token"
      ],
      "tokens_created": 2,
      "validated_keywords": [
        "flying"
      ]
    },
    {
      "card_name": "Flamekin Gildweaver",
      "controller_treasures_after": 1,
      "scenario": "Flamekin Gildweaver ETB creates Treasure",
      "treasures_created": 1,
      "validated_condition": null,
      "validated_keywords": [
        "trample"
      ]
    },
    {
      "card_name": "Gallant Cavalry",
      "scenario": "Gallant Cavalry enters and creates modeled creature tokens",
      "token_names": [
        "Knight Token"
      ],
      "tokens_created": 1,
      "validated_keywords": [
        "vigilance"
      ]
    },
    {
      "card_name": "Guarded Heir",
      "scenario": "Guarded Heir enters and creates modeled creature tokens",
      "token_names": [
        "Knight Token",
        "Knight Token"
      ],
      "tokens_created": 2,
      "validated_keywords": [
        "lifelink"
      ]
    },
    {
      "card_name": "Howling Giant",
      "scenario": "Howling Giant enters and creates modeled creature tokens",
      "token_names": [
        "Wolf Token",
        "Wolf Token"
      ],
      "tokens_created": 2,
      "validated_keywords": [
        "reach"
      ]
    },
    {
      "card_name": "Invasion Reinforcements",
      "scenario": "Invasion Reinforcements enters and creates modeled creature tokens",
      "token_names": [
        "Ally Token"
      ],
      "tokens_created": 1,
      "validated_keywords": [
        "flash"
      ]
    },
    {
      "card_name": "Jewel Thief",
      "controller_treasures_after": 1,
      "scenario": "Jewel Thief ETB creates Treasure",
      "treasures_created": 1,
      "validated_condition": null,
      "validated_keywords": [
        "trample",
        "vigilance"
      ]
    },
    {
      "card_name": "Knight of the New Coalition",
      "scenario": "Knight of the New Coalition enters and creates modeled creature tokens",
      "token_names": [
        "Knight Token"
      ],
      "tokens_created": 1,
      "validated_keywords": [
        "vigilance"
      ]
    },
    {
      "card_name": "News Helicopter",
      "scenario": "News Helicopter enters and creates modeled creature tokens",
      "token_names": [
        "Human Token"
      ],
      "tokens_created": 1,
      "validated_keywords": [
        "flying"
      ]
    },
    {
      "card_name": "Oltec Cloud Guard",
      "scenario": "Oltec Cloud Guard enters and creates modeled creature tokens",
      "token_names": [
        "Gnome Token"
      ],
      "tokens_created": 1,
      "validated_keywords": [
        "flying"
      ]
    },
    {
      "card_name": "Pack Guardian",
      "scenario": "Pack Guardian enters and creates modeled creature tokens",
      "token_names": [
        "Wolf Token"
      ],
      "tokens_created": 1,
      "validated_keywords": [
        "flash"
      ]
    },
    {
      "card_name": "Preening Champion",
      "scenario": "Preening Champion enters and creates modeled creature tokens",
      "token_names": [
        "Elemental Token"
      ],
      "tokens_created": 1,
      "validated_keywords": [
        "flying"
      ]
    },
    {
      "card_name": "Prideful Parent",
      "scenario": "Prideful Parent enters and creates modeled creature tokens",
      "token_names": [
        "Cat Token"
      ],
      "tokens_created": 1,
      "validated_keywords": [
        "vigilance"
      ]
    },
    {
      "card_name": "Rapacious Dragon",
      "controller_treasures_after": 2,
      "scenario": "Rapacious Dragon ETB creates Treasure",
      "treasures_created": 2,
      "validated_condition": null,
      "validated_keywords": [
        "flying"
      ]
    },
    {
      "card_name": "Resolute Reinforcements",
      "scenario": "Resolute Reinforcements enters and creates modeled creature tokens",
      "token_names": [
        "Soldier Token"
      ],
      "tokens_created": 1,
      "validated_keywords": [
        "flash"
      ]
    },
    {
      "card_name": "Searchlight Companion",
      "scenario": "Searchlight Companion enters and creates modeled creature tokens",
      "token_names": [
        "Spirit Token"
      ],
      "tokens_created": 1,
      "validated_keywords": [
        "flying"
      ]
    },
    {
      "card_name": "Treetop Freedom Fighters",
      "scenario": "Treetop Freedom Fighters enters and creates modeled creature tokens",
      "token_names": [
        "Ally Token"
      ],
      "tokens_created": 1,
      "validated_keywords": [
        "haste"
      ]
    },
    {
      "card_name": "Twin-Silk Spider",
      "scenario": "Twin-Silk Spider enters and creates modeled creature tokens",
      "token_names": [
        "Spider Token"
      ],
      "tokens_created": 1,
      "validated_keywords": [
        "reach"
      ]
    },
    {
      "card_name": "Valorous Steed",
      "scenario": "Valorous Steed enters and creates modeled creature tokens",
      "token_names": [
        "Knight Token"
      ],
      "tokens_created": 1,
      "validated_keywords": [
        "vigilance"
      ]
    },
    {
      "card_name": "Voice of the Provinces",
      "scenario": "Voice of the Provinces enters and creates modeled creature tokens",
      "token_names": [
        "Human Token"
      ],
      "tokens_created": 1,
      "validated_keywords": [
        "flying"
      ]
    }
  ],
  "scenario_count": 27
}
```
