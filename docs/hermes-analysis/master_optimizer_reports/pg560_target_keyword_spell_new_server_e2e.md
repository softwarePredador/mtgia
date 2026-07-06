# Battle Package End-to-End Validation

- Generated UTC: `2026-07-06T10:29:42.788490+00:00`
- Package ID: `pg560_target_keyword_spell_new_server_package_manifest`
- Status: `pass`
- Database target: `143.198.230.247:5433/halder`
- SQLite DB: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db`
- Snapshot: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/manaloom-knowledge/scripts/known_cards_canonical_snapshot.json`

## Stage Results

| Stage | Status | Evidence |
| --- | --- | --- |
| postgres_source_of_truth | `pass` | `{"validated_rows": 10}` |
| sqlite_hermes_cache | `pass` | `{"validated_rows": 10}` |
| canonical_snapshot_fallback | `pass` | `{"validated_cards": 10}` |
| runtime_get_card_effect | `pass` | `{"validated_cards": 10}` |
| battle_execution | `pass` | `{"events": 20, "scenarios": 10}` |

## Battle Execution

```json
{
  "event_count": 20,
  "results": [
    {
      "card_name": "Alesha's Legacy",
      "granted_keywords": [
        "deathtouch",
        "indestructible"
      ],
      "scenario": "Alesha's Legacy grants target keyword until EOT",
      "target": "E2E Target Creature",
      "target_power": 2,
      "target_toughness": 2
    },
    {
      "card_name": "Assault Strobe",
      "granted_keywords": [
        "double_strike"
      ],
      "scenario": "Assault Strobe grants target keyword until EOT",
      "target": "E2E Target Creature",
      "target_power": 2,
      "target_toughness": 2
    },
    {
      "card_name": "Battle-Rage Blessing",
      "granted_keywords": [
        "deathtouch",
        "indestructible"
      ],
      "scenario": "Battle-Rage Blessing grants target keyword until EOT",
      "target": "E2E Target Creature",
      "target_power": 2,
      "target_toughness": 2
    },
    {
      "card_name": "Double Cleave",
      "granted_keywords": [
        "double_strike"
      ],
      "scenario": "Double Cleave grants target keyword until EOT",
      "target": "E2E Target Creature",
      "target_power": 2,
      "target_toughness": 2
    },
    {
      "card_name": "Horrid Vigor",
      "granted_keywords": [
        "deathtouch",
        "indestructible"
      ],
      "scenario": "Horrid Vigor grants target keyword until EOT",
      "target": "E2E Target Creature",
      "target_power": 2,
      "target_toughness": 2
    },
    {
      "card_name": "Jump",
      "granted_keywords": [
        "flying"
      ],
      "scenario": "Jump grants target keyword until EOT",
      "target": "E2E Target Creature",
      "target_power": 2,
      "target_toughness": 2
    },
    {
      "card_name": "Offer Immortality",
      "granted_keywords": [
        "deathtouch",
        "indestructible"
      ],
      "scenario": "Offer Immortality grants target keyword until EOT",
      "target": "E2E Target Creature",
      "target_power": 2,
      "target_toughness": 2
    },
    {
      "card_name": "Serpent's Gift",
      "granted_keywords": [
        "deathtouch"
      ],
      "scenario": "Serpent's Gift grants target keyword until EOT",
      "target": "E2E Target Creature",
      "target_power": 2,
      "target_toughness": 2
    },
    {
      "card_name": "Ticked Off",
      "granted_keywords": [
        "double_strike"
      ],
      "scenario": "Ticked Off grants target keyword until EOT",
      "target": "E2E Target Creature",
      "target_power": 2,
      "target_toughness": 2
    },
    {
      "card_name": "Unnatural Speed",
      "granted_keywords": [
        "haste"
      ],
      "scenario": "Unnatural Speed grants target keyword until EOT",
      "target": "E2E Target Creature",
      "target_power": 2,
      "target_toughness": 2
    }
  ],
  "scenario_count": 10
}
```
