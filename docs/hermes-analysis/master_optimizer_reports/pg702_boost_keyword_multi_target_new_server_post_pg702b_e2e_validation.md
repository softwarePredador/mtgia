# Battle Package End-to-End Validation

- Generated UTC: `2026-07-09T08:21:23.442547+00:00`
- Package ID: `pg702_boost_keyword_multi_target_new_server_package_manifest`
- Status: `pass`
- Database target: `127.0.0.1:15432/halder`
- SQLite DB: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db`
- Snapshot: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/manaloom-knowledge/scripts/known_cards_canonical_snapshot.json`

## Stage Results

| Stage | Status | Evidence |
| --- | --- | --- |
| postgres_source_of_truth | `pass` | `{"validated_rows": 3}` |
| sqlite_hermes_cache | `pass` | `{"validated_rows": 3}` |
| canonical_snapshot_fallback | `pass` | `{"validated_cards": 3}` |
| runtime_get_card_effect | `pass` | `{"validated_cards": 3}` |
| battle_execution | `pass` | `{"events": 6, "scenarios": 3}` |

## Battle Execution

```json
{
  "event_count": 6,
  "results": [
    {
      "card_name": "Coordinated Assault",
      "granted_keywords": [
        "first_strike"
      ],
      "scenario": "Coordinated Assault grants target keyword until EOT",
      "target": "E2E Target Creature 1",
      "target_count": 2,
      "target_power": 3,
      "target_toughness": 2
    },
    {
      "card_name": "Cutthroat Maneuver",
      "granted_keywords": [
        "lifelink"
      ],
      "scenario": "Cutthroat Maneuver grants target keyword until EOT",
      "target": "E2E Target Creature 1",
      "target_count": 2,
      "target_power": 3,
      "target_toughness": 3
    },
    {
      "card_name": "Press the Advantage",
      "granted_keywords": [
        "trample"
      ],
      "scenario": "Press the Advantage grants target keyword until EOT",
      "target": "E2E Target Creature 1",
      "target_count": 2,
      "target_power": 4,
      "target_toughness": 4
    }
  ],
  "scenario_count": 3
}
```
