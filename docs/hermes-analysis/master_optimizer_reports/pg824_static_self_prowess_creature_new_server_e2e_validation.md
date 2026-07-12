# Battle Package End-to-End Validation

- Generated UTC: `2026-07-12T09:59:06.077168+00:00`
- Package ID: `pg824_static_self_prowess_creature_new_server_package_manifest`
- Status: `pass`
- Database target: `127.0.0.1:15432/halder`
- SQLite DB: `docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db`
- Snapshot: `docs/hermes-analysis/master_optimizer_reports/pg824_static_self_prowess_creature_new_server_canonical_rules.json`

## Stage Results

| Stage | Status | Evidence |
| --- | --- | --- |
| postgres_source_of_truth | `pass` | `{"validated_rows": 23}` |
| sqlite_hermes_cache | `pass` | `{"validated_rows": 23}` |
| canonical_snapshot_fallback | `pass` | `{"validated_cards": 23}` |
| runtime_get_card_effect | `pass` | `{"validated_cards": 23}` |
| battle_execution | `pass` | `{"events": 23, "scenarios": 23}` |

## Battle Execution

```json
{
  "event_count": 23,
  "results": [
    {
      "card_name": "Bloodfire Expert",
      "keywords": [
        "prowess"
      ],
      "power_after": 3,
      "scenario": "Bloodfire Expert triggers prowess from noncreature spell",
      "toughness_after": 3,
      "trigger_spell": "E2E Prowess Instant"
    },
    {
      "card_name": "Dragon Bell Monk",
      "keywords": [
        "prowess",
        "vigilance"
      ],
      "power_after": 3,
      "scenario": "Dragon Bell Monk triggers prowess from noncreature spell",
      "toughness_after": 3,
      "trigger_spell": "E2E Prowess Instant"
    },
    {
      "card_name": "Dragon-Style Twins",
      "keywords": [
        "double_strike",
        "prowess"
      ],
      "power_after": 3,
      "scenario": "Dragon-Style Twins triggers prowess from noncreature spell",
      "toughness_after": 3,
      "trigger_spell": "E2E Prowess Instant"
    },
    {
      "card_name": "Elementalist Adept",
      "keywords": [
        "flash",
        "prowess"
      ],
      "power_after": 3,
      "scenario": "Elementalist Adept triggers prowess from noncreature spell",
      "toughness_after": 3,
      "trigger_spell": "E2E Prowess Instant"
    },
    {
      "card_name": "Iguana Parrot",
      "keywords": [
        "flying",
        "prowess",
        "vigilance"
      ],
      "power_after": 3,
      "scenario": "Iguana Parrot triggers prowess from noncreature spell",
      "toughness_after": 3,
      "trigger_spell": "E2E Prowess Instant"
    },
    {
      "card_name": "Jeskai Brushmaster",
      "keywords": [
        "double_strike",
        "prowess"
      ],
      "power_after": 3,
      "scenario": "Jeskai Brushmaster triggers prowess from noncreature spell",
      "toughness_after": 3,
      "trigger_spell": "E2E Prowess Instant"
    },
    {
      "card_name": "Jeskai Student",
      "keywords": [
        "prowess"
      ],
      "power_after": 3,
      "scenario": "Jeskai Student triggers prowess from noncreature spell",
      "toughness_after": 3,
      "trigger_spell": "E2E Prowess Instant"
    },
    {
      "card_name": "Jeskai Windscout",
      "keywords": [
        "flying",
        "prowess"
      ],
      "power_after": 3,
      "scenario": "Jeskai Windscout triggers prowess from noncreature spell",
      "toughness_after": 3,
      "trigger_spell": "E2E Prowess Instant"
    },
    {
      "card_name": "Lightning Visionary",
      "keywords": [
        "prowess"
      ],
      "power_after": 3,
      "scenario": "Lightning Visionary triggers prowess from noncreature spell",
      "toughness_after": 3,
      "trigger_spell": "E2E Prowess Instant"
    },
    {
      "card_name": "Lotus Path Djinn",
      "keywords": [
        "flying",
        "prowess"
      ],
      "power_after": 3,
      "scenario": "Lotus Path Djinn triggers prowess from noncreature spell",
      "toughness_after": 3,
      "trigger_spell": "E2E Prowess Instant"
    },
    {
      "card_name": "Mistral Singer",
      "keywords": [
        "flying",
        "prowess"
      ],
      "power_after": 3,
      "scenario": "Mistral Singer triggers prowess from noncreature spell",
      "toughness_after": 3,
      "trigger_spell": "E2E Prowess Instant"
    },
    {
      "card_name": "Monastery Swiftspear",
      "keywords": [
        "haste",
        "prowess"
      ],
      "power_after": 3,
      "scenario": "Monastery Swiftspear triggers prowess from noncreature spell",
      "toughness_after": 3,
      "trigger_spell": "E2E Prowess Instant"
    },
    {
      "card_name": "Niblis of Dusk",
      "keywords": [
        "flying",
        "prowess"
      ],
      "power_after": 3,
      "scenario": "Niblis of Dusk triggers prowess from noncreature spell",
      "toughness_after": 3,
      "trigger_spell": "E2E Prowess Instant"
    },
    {
      "card_name": "Nimble-Blade Khenra",
      "keywords": [
        "prowess"
      ],
      "power_after": 3,
      "scenario": "Nimble-Blade Khenra triggers prowess from noncreature spell",
      "toughness_after": 3,
      "trigger_spell": "E2E Prowess Instant"
    },
    {
      "card_name": "Ringwarden Owl",
      "keywords": [
        "flying",
        "prowess"
      ],
      "power_after": 3,
      "scenario": "Ringwarden Owl triggers prowess from noncreature spell",
      "toughness_after": 3,
      "trigger_spell": "E2E Prowess Instant"
    },
    {
      "card_name": "Riverwheel Aerialists",
      "keywords": [
        "flying",
        "prowess"
      ],
      "power_after": 3,
      "scenario": "Riverwheel Aerialists triggers prowess from noncreature spell",
      "toughness_after": 3,
      "trigger_spell": "E2E Prowess Instant"
    },
    {
      "card_name": "Sanguinary Mage",
      "keywords": [
        "prowess"
      ],
      "power_after": 3,
      "scenario": "Sanguinary Mage triggers prowess from noncreature spell",
      "toughness_after": 3,
      "trigger_spell": "E2E Prowess Instant"
    },
    {
      "card_name": "Stormchaser Mage",
      "keywords": [
        "flying",
        "haste",
        "prowess"
      ],
      "power_after": 3,
      "scenario": "Stormchaser Mage triggers prowess from noncreature spell",
      "toughness_after": 3,
      "trigger_spell": "E2E Prowess Instant"
    },
    {
      "card_name": "Thor Odinson",
      "keywords": [
        "flying",
        "prowess",
        "vigilance"
      ],
      "power_after": 3,
      "scenario": "Thor Odinson triggers prowess from noncreature spell",
      "toughness_after": 3,
      "trigger_spell": "E2E Prowess Instant"
    },
    {
      "card_name": "Umara Entangler",
      "keywords": [
        "prowess"
      ],
      "power_after": 3,
      "scenario": "Umara Entangler triggers prowess from noncreature spell",
      "toughness_after": 3,
      "trigger_spell": "E2E Prowess Instant"
    },
    {
      "card_name": "Vedalken Blademaster",
      "keywords": [
        "prowess"
      ],
      "power_after": 3,
      "scenario": "Vedalken Blademaster triggers prowess from noncreature spell",
      "toughness_after": 3,
      "trigger_spell": "E2E Prowess Instant"
    },
    {
      "card_name": "Whirlwind Adept",
      "keywords": [
        "hexproof",
        "prowess"
      ],
      "power_after": 3,
      "scenario": "Whirlwind Adept triggers prowess from noncreature spell",
      "toughness_after": 3,
      "trigger_spell": "E2E Prowess Instant"
    },
    {
      "card_name": "Wing Commando",
      "keywords": [
        "flying",
        "prowess"
      ],
      "power_after": 3,
      "scenario": "Wing Commando triggers prowess from noncreature spell",
      "toughness_after": 3,
      "trigger_spell": "E2E Prowess Instant"
    }
  ],
  "scenario_count": 23
}
```
