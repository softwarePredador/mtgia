# Battle Package End-to-End Validation

- Generated UTC: `2026-07-12T05:05:50.551693+00:00`
- Package ID: `pg807_exile_ace_target_new_server_manifest`
- Status: `pass`
- Database target: `127.0.0.1:15432/halder`
- SQLite DB: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db`
- Snapshot: `docs/hermes-analysis/master_optimizer_reports/pg807_exile_ace_target_new_server_canonical_fallback.json`

## Stage Results

| Stage | Status | Evidence |
| --- | --- | --- |
| postgres_source_of_truth | `pass` | `{"validated_rows": 1}` |
| sqlite_hermes_cache | `pass` | `{"validated_rows": 1}` |
| canonical_snapshot_fallback | `pass` | `{"validated_cards": 1}` |
| runtime_get_card_effect | `pass` | `{"validated_cards": 1}` |
| battle_execution | `pass` | `{"events": 4, "scenarios": 1}` |

## Battle Execution

```json
{
  "event_count": 4,
  "results": [
    {
      "additional_cost": "sacrifice_permanent",
      "battlefield_names": [
        "E2E Illegal Removal Target"
      ],
      "card_name": "Angelic Purge",
      "destination": "exile",
      "moved_names": [
        "E2E Legal Removal Target"
      ],
      "nonmatching_target": "E2E Illegal Removal Target",
      "scenario": "Angelic Purge removes one legal target",
      "target": "E2E Legal Removal Target",
      "target_player": "Opponent"
    }
  ],
  "scenario_count": 1
}
```
