# Battle Package End-to-End Validation

- Generated UTC: `2026-07-07T09:00:46.599017+00:00`
- Package ID: `xmage_pg605_boost_keyword_target_creature_manifest`
- Status: `pass`
- Database target: `127.0.0.1:15432/halder`
- SQLite DB: `docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db`
- Snapshot: `docs/hermes-analysis/manaloom-knowledge/scripts/known_cards_canonical_snapshot.json`

## Stage Results

| Stage | Status | Evidence |
| --- | --- | --- |
| postgres_source_of_truth | `pass` | `{"validated_rows": 4}` |
| sqlite_hermes_cache | `pass` | `{"validated_rows": 4}` |
| canonical_snapshot_fallback | `pass` | `{"validated_cards": 4}` |
| runtime_get_card_effect | `pass` | `{"validated_cards": 4}` |
| battle_execution | `pass` | `{"events": 8, "scenarios": 4}` |

## Battle Execution

```json
{
  "event_count": 8,
  "results": [
    {
      "card_name": "Armor of Shadows",
      "granted_keywords": [
        "indestructible"
      ],
      "scenario": "Armor of Shadows grants target keyword until EOT",
      "target": "E2E Target Creature",
      "target_power": 3,
      "target_toughness": 2
    },
    {
      "card_name": "Blitzball Shot",
      "granted_keywords": [
        "trample"
      ],
      "scenario": "Blitzball Shot grants target keyword until EOT",
      "target": "E2E Target Creature",
      "target_power": 5,
      "target_toughness": 5
    },
    {
      "card_name": "Massive Might",
      "granted_keywords": [
        "trample"
      ],
      "scenario": "Massive Might grants target keyword until EOT",
      "target": "E2E Target Creature",
      "target_power": 4,
      "target_toughness": 4
    },
    {
      "card_name": "Masterful Flourish",
      "granted_keywords": [
        "indestructible"
      ],
      "scenario": "Masterful Flourish grants target keyword until EOT",
      "target": "E2E Target Creature",
      "target_power": 3,
      "target_toughness": 2
    }
  ],
  "scenario_count": 4
}
```
