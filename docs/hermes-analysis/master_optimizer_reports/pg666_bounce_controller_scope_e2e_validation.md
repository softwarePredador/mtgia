# Battle Package End-to-End Validation

- Generated UTC: `2026-07-08T18:40:43.770350+00:00`
- Package ID: `pg666_bounce_controller_scope_package_manifest`
- Status: `pass`
- Database target: `127.0.0.1:15432/halder`
- SQLite DB: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db`
- Snapshot: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/manaloom-knowledge/scripts/known_cards_canonical_snapshot.json`

## Stage Results

| Stage | Status | Evidence |
| --- | --- | --- |
| postgres_source_of_truth | `pass` | `{"validated_rows": 2}` |
| sqlite_hermes_cache | `pass` | `{"validated_rows": 2}` |
| canonical_snapshot_fallback | `pass` | `{"validated_cards": 2}` |
| runtime_get_card_effect | `pass` | `{"validated_cards": 2}` |
| battle_execution | `pass` | `{"events": 6, "scenarios": 2}` |

## Battle Execution

```json
{
  "event_count": 6,
  "results": [
    {
      "battlefield_names": [
        "E2E Illegal Removal Target"
      ],
      "card_name": "Rescue",
      "destination": "hand",
      "moved_names": [
        "E2E Legal Removal Target"
      ],
      "nonmatching_target": "E2E Illegal Removal Target",
      "scenario": "Rescue removes one legal target",
      "target": "E2E Legal Removal Target",
      "target_player": "Active"
    },
    {
      "battlefield_names": [
        "E2E Illegal Removal Target"
      ],
      "card_name": "Stern Dismissal",
      "destination": "hand",
      "moved_names": [
        "E2E Legal Removal Target"
      ],
      "nonmatching_target": "E2E Illegal Removal Target",
      "scenario": "Stern Dismissal removes one legal target",
      "target": "E2E Legal Removal Target",
      "target_player": "Opponent"
    }
  ],
  "scenario_count": 2
}
```
