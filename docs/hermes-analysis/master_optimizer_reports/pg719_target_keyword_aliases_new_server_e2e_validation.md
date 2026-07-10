# Battle Package End-to-End Validation

- Generated UTC: `2026-07-10T20:13:38.809682+00:00`
- Package ID: `pg719_target_keyword_aliases_new_server_package_manifest`
- Status: `pass`
- Database target: `127.0.0.1:15432/halder`
- SQLite DB: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db`
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
      "card_name": "Breach",
      "granted_keywords": [
        "fear"
      ],
      "scenario": "Breach grants target keyword until EOT",
      "target": "E2E Target Creature",
      "target_count": 1,
      "target_power": 4,
      "target_toughness": 2
    },
    {
      "card_name": "Hooded Kavu",
      "discarded_count": 0,
      "granted_keywords": [
        "fear"
      ],
      "life_paid": 0,
      "scenario": "Hooded Kavu activates self keyword ability",
      "source_keywords": [
        "fear"
      ],
      "source_tapped": false
    },
    {
      "card_name": "Shriek of Dread",
      "granted_keywords": [
        "fear"
      ],
      "scenario": "Shriek of Dread grants target keyword until EOT",
      "target": "E2E Target Creature",
      "target_count": 1,
      "target_power": 2,
      "target_toughness": 2
    },
    {
      "card_name": "Withstand Death",
      "granted_keywords": [
        "indestructible"
      ],
      "scenario": "Withstand Death grants target keyword until EOT",
      "target": "E2E Target Creature",
      "target_count": 1,
      "target_power": 2,
      "target_toughness": 2
    }
  ],
  "scenario_count": 4
}
```
