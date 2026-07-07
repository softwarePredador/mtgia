# Battle Package End-to-End Validation

- Generated UTC: `2026-07-07T08:34:52.033329+00:00`
- Package ID: `pg604_destroy_surveil_new_server_manifest`
- Status: `pass`
- Database target: `127.0.0.1:15432/halder`
- SQLite DB: `docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db`
- Snapshot: `docs/hermes-analysis/manaloom-knowledge/scripts/known_cards_canonical_snapshot.json`

## Stage Results

| Stage | Status | Evidence |
| --- | --- | --- |
| postgres_source_of_truth | `pass` | `{"validated_rows": 3}` |
| sqlite_hermes_cache | `pass` | `{"validated_rows": 3}` |
| canonical_snapshot_fallback | `pass` | `{"validated_cards": 3}` |
| runtime_get_card_effect | `pass` | `{"validated_cards": 3}` |
| battle_execution | `pass` | `{"events": 21, "scenarios": 3}` |

## Battle Execution

```json
{
  "event_count": 21,
  "results": [
    {
      "card_name": "Deadly Visit",
      "destination": "graveyard",
      "moved_names": [
        "E2E Legal Removal Target"
      ],
      "nonmatching_target": "E2E Illegal Removal Target",
      "scenario": "Deadly Visit destroys one legal target and surveils",
      "surveil_count": 2,
      "surveil_looked_at": [
        "E2E Low Priority Land",
        "E2E High Priority Spell"
      ],
      "surveil_moved_to_graveyard": [
        "E2E Low Priority Land"
      ],
      "surveil_top_after": [
        "E2E High Priority Spell",
        "E2E Library Remainder"
      ],
      "target": "E2E Legal Removal Target"
    },
    {
      "card_name": "Pile On",
      "destination": "graveyard",
      "moved_names": [
        "E2E Legal Removal Target"
      ],
      "nonmatching_target": "E2E Illegal Removal Target",
      "scenario": "Pile On destroys one legal target and surveils",
      "surveil_count": 2,
      "surveil_looked_at": [
        "E2E Low Priority Land",
        "E2E High Priority Spell"
      ],
      "surveil_moved_to_graveyard": [
        "E2E Low Priority Land"
      ],
      "surveil_top_after": [
        "E2E High Priority Spell",
        "E2E Library Remainder"
      ],
      "target": "E2E Legal Removal Target"
    },
    {
      "card_name": "Shattered Wings",
      "destination": "graveyard",
      "moved_names": [
        "E2E Legal Removal Target"
      ],
      "nonmatching_target": "E2E Illegal Removal Target",
      "scenario": "Shattered Wings destroys one legal target and surveils",
      "surveil_count": 1,
      "surveil_looked_at": [
        "E2E Low Priority Land"
      ],
      "surveil_moved_to_graveyard": [
        "E2E Low Priority Land"
      ],
      "surveil_top_after": [
        "E2E High Priority Spell"
      ],
      "target": "E2E Legal Removal Target"
    }
  ],
  "scenario_count": 3
}
```
