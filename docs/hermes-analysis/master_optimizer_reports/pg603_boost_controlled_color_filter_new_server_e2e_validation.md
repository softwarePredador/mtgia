# Battle Package End-to-End Validation

- Generated UTC: `2026-07-07T08:08:36.541256+00:00`
- Package ID: `pg603_boost_controlled_color_filter_new_server_manifest`
- Status: `pass`
- Database target: `127.0.0.1:15432/halder`
- SQLite DB: `docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db`
- Snapshot: `docs/hermes-analysis/manaloom-knowledge/scripts/known_cards_canonical_snapshot.json`

## Stage Results

| Stage | Status | Evidence |
| --- | --- | --- |
| postgres_source_of_truth | `pass` | `{"validated_rows": 1}` |
| sqlite_hermes_cache | `pass` | `{"validated_rows": 1}` |
| canonical_snapshot_fallback | `pass` | `{"validated_cards": 1}` |
| runtime_get_card_effect | `pass` | `{"validated_cards": 1}` |
| battle_execution | `pass` | `{"events": 2, "scenarios": 1}` |

## Battle Execution

```json
{
  "event_count": 2,
  "results": [
    {
      "affected_count": 1,
      "card_name": "Guardians' Pledge",
      "creature_filter": {
        "colors": [
          "W"
        ]
      },
      "matching_power": 4,
      "matching_target": "E2E Matching Controlled Creature",
      "matching_toughness": 4,
      "scenario": "Guardians' Pledge boosts controlled filtered creatures until EOT"
    }
  ],
  "scenario_count": 1
}
```
