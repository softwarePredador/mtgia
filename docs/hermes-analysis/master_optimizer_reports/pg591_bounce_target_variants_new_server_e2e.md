# Battle Package End-to-End Validation

- Generated UTC: `2026-07-07T03:56:59.043348+00:00`
- Package ID: `pg591_bounce_target_variants_new_server_package_manifest`
- Status: `pass`
- Database target: `127.0.0.1:15432/halder`
- SQLite DB: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db`
- Snapshot: `docs/hermes-analysis/manaloom-knowledge/scripts/known_cards_canonical_snapshot.json`

## Stage Results

| Stage | Status | Evidence |
| --- | --- | --- |
| postgres_source_of_truth | `pass` | `{"validated_rows": 6}` |
| sqlite_hermes_cache | `pass` | `{"validated_rows": 6}` |
| canonical_snapshot_fallback | `pass` | `{"validated_cards": 6}` |
| runtime_get_card_effect | `pass` | `{"validated_cards": 6}` |
| battle_execution | `pass` | `{"events": 18, "scenarios": 6}` |

## Battle Execution

```json
{
  "event_count": 18,
  "results": [
    {
      "battlefield_names": [
        "E2E Illegal Removal Target"
      ],
      "card_name": "Bounce Off",
      "destination": "hand",
      "moved_names": [
        "E2E Legal Removal Target"
      ],
      "nonmatching_target": "E2E Illegal Removal Target",
      "scenario": "Bounce Off removes one legal target",
      "target": "E2E Legal Removal Target"
    },
    {
      "battlefield_names": [
        "E2E Illegal Removal Target"
      ],
      "card_name": "Cut the Earthly Bond",
      "destination": "hand",
      "moved_names": [
        "E2E Legal Removal Target"
      ],
      "nonmatching_target": "E2E Illegal Removal Target",
      "scenario": "Cut the Earthly Bond removes one legal target",
      "target": "E2E Legal Removal Target"
    },
    {
      "battlefield_names": [
        "E2E Illegal Removal Target"
      ],
      "card_name": "Depart the Realm",
      "destination": "hand",
      "moved_names": [
        "E2E Legal Removal Target"
      ],
      "nonmatching_target": "E2E Illegal Removal Target",
      "scenario": "Depart the Realm removes one legal target",
      "target": "E2E Legal Removal Target"
    },
    {
      "battlefield_names": [
        "E2E Illegal Removal Target"
      ],
      "card_name": "Hoodwink",
      "destination": "hand",
      "moved_names": [
        "E2E Legal Removal Target"
      ],
      "nonmatching_target": "E2E Illegal Removal Target",
      "scenario": "Hoodwink removes one legal target",
      "target": "E2E Legal Removal Target"
    },
    {
      "battlefield_names": [
        "E2E Illegal Removal Target"
      ],
      "card_name": "Into Thin Air",
      "destination": "hand",
      "moved_names": [
        "E2E Legal Removal Target"
      ],
      "nonmatching_target": "E2E Illegal Removal Target",
      "scenario": "Into Thin Air removes one legal target",
      "target": "E2E Legal Removal Target"
    },
    {
      "battlefield_names": [
        "E2E Illegal Removal Target"
      ],
      "card_name": "Wipe Away",
      "destination": "hand",
      "moved_names": [
        "E2E Legal Removal Target"
      ],
      "nonmatching_target": "E2E Illegal Removal Target",
      "scenario": "Wipe Away removes one legal target",
      "target": "E2E Legal Removal Target"
    }
  ],
  "scenario_count": 6
}
```
