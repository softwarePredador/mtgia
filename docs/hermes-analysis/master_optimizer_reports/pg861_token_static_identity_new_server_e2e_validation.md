# Battle Package End-to-End Validation

- Generated UTC: `2026-07-13T04:06:13.264625+00:00`
- Package ID: `pg861_token_static_identity_new_server_package_manifest`
- Status: `pass`
- Database target: `127.0.0.1:15432/halder`
- SQLite DB: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db`
- Snapshot: `docs/hermes-analysis/master_optimizer_reports/pg861_token_static_identity_new_server_canonical_snapshot.json`

## Stage Results

| Stage | Status | Evidence |
| --- | --- | --- |
| postgres_source_of_truth | `pass` | `{"validated_rows": 1}` |
| sqlite_hermes_cache | `pass` | `{"validated_rows": 1}` |
| canonical_snapshot_fallback | `pass` | `{"validated_cards": 1}` |
| runtime_get_card_effect | `pass` | `{"validated_cards": 1}` |
| battle_execution | `pass` | `{"events": 1, "scenarios": 1}` |

## Battle Execution

```json
{
  "event_count": 1,
  "results": [
    {
      "card_name": "Birthing Boughs",
      "discard_target": null,
      "discarded_count": 0,
      "exiled_source_from_graveyard": false,
      "scenario": "Birthing Boughs activates token ability",
      "token_name": "Shapeshifter Token",
      "tokens_created": 1
    }
  ],
  "scenario_count": 1
}
```
