# Battle Package End-to-End Validation

- Generated UTC: `2026-07-09T07:48:40.308818+00:00`
- Package ID: `pg701_boost_multi_keyword_new_server_package_manifest`
- Status: `pass`
- Database target: `127.0.0.1:15432/halder`
- SQLite DB: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db`
- Snapshot: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/manaloom-knowledge/scripts/known_cards_canonical_snapshot.json`

## Stage Results

| Stage | Status | Evidence |
| --- | --- | --- |
| postgres_source_of_truth | `pass` | `{"validated_rows": 8}` |
| sqlite_hermes_cache | `pass` | `{"validated_rows": 8}` |
| canonical_snapshot_fallback | `pass` | `{"validated_cards": 8}` |
| runtime_get_card_effect | `pass` | `{"validated_cards": 8}` |
| battle_execution | `pass` | `{"events": 16, "scenarios": 8}` |

## Battle Execution

```json
{
  "event_count": 16,
  "results": [
    {
      "card_name": "Aerial Maneuver",
      "granted_keywords": [
        "flying",
        "first_strike"
      ],
      "scenario": "Aerial Maneuver grants target keyword until EOT",
      "target": "E2E Target Creature",
      "target_power": 3,
      "target_toughness": 3
    },
    {
      "card_name": "Daring Leap",
      "granted_keywords": [
        "flying",
        "first_strike"
      ],
      "scenario": "Daring Leap grants target keyword until EOT",
      "target": "E2E Target Creature",
      "target_power": 3,
      "target_toughness": 3
    },
    {
      "card_name": "Fervent Strike",
      "granted_keywords": [
        "first_strike",
        "haste"
      ],
      "scenario": "Fervent Strike grants target keyword until EOT",
      "target": "E2E Target Creature",
      "target_power": 3,
      "target_toughness": 2
    },
    {
      "card_name": "Overprotect",
      "granted_keywords": [
        "trample",
        "hexproof",
        "indestructible"
      ],
      "scenario": "Overprotect grants target keyword until EOT",
      "target": "E2E Target Creature",
      "target_power": 5,
      "target_toughness": 5
    },
    {
      "card_name": "Rig for War",
      "granted_keywords": [
        "first_strike",
        "reach"
      ],
      "scenario": "Rig for War grants target keyword until EOT",
      "target": "E2E Target Creature",
      "target_power": 5,
      "target_toughness": 2
    },
    {
      "card_name": "Rush of Vitality",
      "granted_keywords": [
        "lifelink",
        "indestructible"
      ],
      "scenario": "Rush of Vitality grants target keyword until EOT",
      "target": "E2E Target Creature",
      "target_power": 3,
      "target_toughness": 2
    },
    {
      "card_name": "Swift Justice",
      "granted_keywords": [
        "first_strike",
        "lifelink"
      ],
      "scenario": "Swift Justice grants target keyword until EOT",
      "target": "E2E Target Creature",
      "target_power": 3,
      "target_toughness": 2
    },
    {
      "card_name": "Whirling Strike",
      "granted_keywords": [
        "first_strike",
        "trample"
      ],
      "scenario": "Whirling Strike grants target keyword until EOT",
      "target": "E2E Target Creature",
      "target_power": 4,
      "target_toughness": 2
    }
  ],
  "scenario_count": 8
}
```
