# Battle Package End-to-End Validation

- Generated UTC: `2026-07-07T21:25:28.414380+00:00`
- Package ID: `pg640_destroy_restricted_creature_targets_new_server_manifest`
- Status: `pass`
- Database target: `127.0.0.1:15432/halder`
- SQLite DB: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db`
- Snapshot: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/manaloom-knowledge/scripts/known_cards_canonical_snapshot.json`

## Stage Results

| Stage | Status | Evidence |
| --- | --- | --- |
| postgres_source_of_truth | `pass` | `{"validated_rows": 4}` |
| sqlite_hermes_cache | `pass` | `{"validated_rows": 4}` |
| canonical_snapshot_fallback | `pass` | `{"validated_cards": 4}` |
| runtime_get_card_effect | `pass` | `{"validated_cards": 4}` |
| battle_execution | `pass` | `{"events": 12, "scenarios": 4}` |

## Battle Execution

```json
{
  "event_count": 12,
  "results": [
    {
      "battlefield_names": [
        "E2E Illegal Removal Target"
      ],
      "card_name": "Feast of Dreams",
      "destination": "graveyard",
      "moved_names": [
        "E2E Legal Removal Target"
      ],
      "nonmatching_target": "E2E Illegal Removal Target",
      "scenario": "Feast of Dreams removes one legal target",
      "target": "E2E Legal Removal Target"
    },
    {
      "battlefield_names": [
        "E2E Illegal Removal Target"
      ],
      "card_name": "Pitfall Trap",
      "destination": "graveyard",
      "moved_names": [
        "E2E Legal Removal Target"
      ],
      "nonmatching_target": "E2E Illegal Removal Target",
      "scenario": "Pitfall Trap removes one legal target",
      "target": "E2E Legal Removal Target"
    },
    {
      "battlefield_names": [
        "E2E Illegal Removal Target"
      ],
      "card_name": "Shoot the Sheriff",
      "destination": "graveyard",
      "moved_names": [
        "E2E Legal Removal Target"
      ],
      "nonmatching_target": "E2E Illegal Removal Target",
      "scenario": "Shoot the Sheriff removes one legal target",
      "target": "E2E Legal Removal Target"
    },
    {
      "battlefield_names": [
        "E2E Illegal Removal Target"
      ],
      "card_name": "Smite",
      "destination": "graveyard",
      "moved_names": [
        "E2E Legal Removal Target"
      ],
      "nonmatching_target": "E2E Illegal Removal Target",
      "scenario": "Smite removes one legal target",
      "target": "E2E Legal Removal Target"
    }
  ],
  "scenario_count": 4
}
```
