# Battle Package End-to-End Validation

- Generated UTC: `2026-07-10T14:06:49.728989+00:00`
- Package ID: `pg703_multi_target_boost_scope_new_server_package_manifest`
- Status: `pass`
- Database target: `127.0.0.1:15432/halder`
- SQLite DB: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db`
- Snapshot: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/manaloom-knowledge/scripts/known_cards_canonical_snapshot.json`

## Stage Results

| Stage | Status | Evidence |
| --- | --- | --- |
| postgres_source_of_truth | `pass` | `{"validated_rows": 7}` |
| sqlite_hermes_cache | `pass` | `{"validated_rows": 7}` |
| canonical_snapshot_fallback | `pass` | `{"validated_cards": 7}` |
| runtime_get_card_effect | `pass` | `{"validated_cards": 7}` |
| battle_execution | `pass` | `{"events": 14, "scenarios": 7}` |

## Battle Execution

```json
{
  "event_count": 14,
  "results": [
    {
      "card_name": "Dauntless Onslaught",
      "granted_keywords": [],
      "scenario": "Dauntless Onslaught grants target keyword until EOT",
      "target": "E2E Target Creature 1",
      "target_count": 2,
      "target_power": 4,
      "target_toughness": 4
    },
    {
      "card_name": "Hearts on Fire",
      "granted_keywords": [],
      "scenario": "Hearts on Fire grants target keyword until EOT",
      "target": "E2E Target Creature 1",
      "target_count": 2,
      "target_power": 4,
      "target_toughness": 3
    },
    {
      "card_name": "Mischief and Mayhem",
      "granted_keywords": [],
      "scenario": "Mischief and Mayhem grants target keyword until EOT",
      "target": "E2E Target Creature 1",
      "target_count": 2,
      "target_power": 6,
      "target_toughness": 6
    },
    {
      "card_name": "Nahiri's Stoneblades",
      "granted_keywords": [],
      "scenario": "Nahiri's Stoneblades grants target keyword until EOT",
      "target": "E2E Target Creature 1",
      "target_count": 2,
      "target_power": 4,
      "target_toughness": 2
    },
    {
      "card_name": "Sick and Tired",
      "granted_keywords": [],
      "scenario": "Sick and Tired grants target keyword until EOT",
      "target": "E2E Target Creature 1",
      "target_count": 2,
      "target_power": 1,
      "target_toughness": 1
    },
    {
      "card_name": "Symbiosis",
      "granted_keywords": [],
      "scenario": "Symbiosis grants target keyword until EOT",
      "target": "E2E Target Creature 1",
      "target_count": 2,
      "target_power": 4,
      "target_toughness": 4
    },
    {
      "card_name": "Windborne Charge",
      "granted_keywords": [
        "flying"
      ],
      "scenario": "Windborne Charge grants target keyword until EOT",
      "target": "E2E Target Creature 1",
      "target_count": 2,
      "target_power": 4,
      "target_toughness": 4
    }
  ],
  "scenario_count": 7
}
```
