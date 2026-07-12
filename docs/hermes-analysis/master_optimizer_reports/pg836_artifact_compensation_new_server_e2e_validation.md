# Battle Package End-to-End Validation

- Generated UTC: `2026-07-12T18:20:35.786067+00:00`
- Package ID: `pg836_artifact_compensation_new_server_manifest`
- Status: `pass`
- Database target: `127.0.0.1:15432/halder`
- SQLite DB: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db`
- Snapshot: `docs/hermes-analysis/master_optimizer_reports/pg836_artifact_compensation_new_server_pg_to_sqlite_sync_tracked_snapshot.json`

## Stage Results

| Stage | Status | Evidence |
| --- | --- | --- |
| postgres_source_of_truth | `pass` | `{"validated_rows": 2}` |
| sqlite_hermes_cache | `pass` | `{"validated_rows": 2}` |
| canonical_snapshot_fallback | `pass` | `{"validated_cards": 2}` |
| runtime_get_card_effect | `pass` | `{"validated_cards": 2}` |
| battle_execution | `pass` | `{"events": 8, "scenarios": 2}` |

## Battle Execution

```json
{
  "event_count": 8,
  "results": [
    {
      "battlefield_names": [
        "E2E Illegal Removal Target",
        "Treasure Token"
      ],
      "card_name": "Buy Your Silence",
      "compensation_token_artifact_only": true,
      "compensation_token_name": "Treasure Token",
      "compensation_tokens_created": 1,
      "destination": "exile",
      "moved_names": [
        "E2E Legal Removal Target"
      ],
      "nonmatching_target": "E2E Illegal Removal Target",
      "scenario": "Buy Your Silence removes one legal target",
      "target": "E2E Legal Removal Target",
      "target_player": "Opponent"
    },
    {
      "battlefield_names": [
        "E2E Illegal Removal Target",
        "Clue Token"
      ],
      "card_name": "Zuko's Exile",
      "compensation_token_artifact_only": true,
      "compensation_token_name": "Clue Token",
      "compensation_tokens_created": 1,
      "destination": "exile",
      "moved_names": [
        "E2E Legal Removal Target"
      ],
      "nonmatching_target": "E2E Illegal Removal Target",
      "scenario": "Zuko's Exile removes one legal target",
      "target": "E2E Legal Removal Target",
      "target_player": "Opponent"
    }
  ],
  "scenario_count": 2
}
```
