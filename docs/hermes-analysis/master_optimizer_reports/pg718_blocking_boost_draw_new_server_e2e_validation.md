# Battle Package End-to-End Validation

- Generated UTC: `2026-07-10T20:02:18.464081+00:00`
- Package ID: `pg718_blocking_boost_draw_new_server_package_manifest`
- Status: `pass`
- Database target: `127.0.0.1:15432/halder`
- SQLite DB: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db`
- Snapshot: `docs/hermes-analysis/manaloom-knowledge/scripts/known_cards_canonical_snapshot.json`

## Stage Results

| Stage | Status | Evidence |
| --- | --- | --- |
| postgres_source_of_truth | `pass` | `{"validated_rows": 2}` |
| sqlite_hermes_cache | `pass` | `{"validated_rows": 2}` |
| canonical_snapshot_fallback | `pass` | `{"validated_cards": 2}` |
| runtime_get_card_effect | `pass` | `{"validated_cards": 2}` |
| battle_execution | `pass` | `{"events": 10, "scenarios": 2}` |

## Battle Execution

```json
{
  "event_count": 10,
  "results": [
    {
      "card_name": "Aang's Defense",
      "cards_drawn": 1,
      "granted_keywords": [],
      "hand": [
        "E2E Draw Card 1"
      ],
      "nonmatching_target": "E2E Illegal Target Creature",
      "scenario": "Aang's Defense grants target keyword and draws 1",
      "target": "E2E Target Creature",
      "target_power": 4,
      "target_toughness": 4
    },
    {
      "card_name": "Gallantry",
      "cards_drawn": 1,
      "granted_keywords": [],
      "hand": [
        "E2E Draw Card 1"
      ],
      "nonmatching_target": "E2E Illegal Target Creature",
      "scenario": "Gallantry grants target keyword and draws 1",
      "target": "E2E Target Creature",
      "target_power": 6,
      "target_toughness": 6
    }
  ],
  "scenario_count": 2
}
```
