# Battle Package End-to-End Validation

- Generated UTC: `2026-07-12T20:20:37.290272+00:00`
- Package ID: `pg843_target_player_discard_mill_new_server_manifest`
- Status: `pass`
- Database target: `127.0.0.1:15432/halder`
- SQLite DB: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db`
- Snapshot: `docs/hermes-analysis/master_optimizer_reports/pg843b_trusted_rule_oracle_hash_backfill_new_server_canonical_snapshot.json`

## Stage Results

| Stage | Status | Evidence |
| --- | --- | --- |
| postgres_source_of_truth | `pass` | `{"validated_rows": 1}` |
| sqlite_hermes_cache | `pass` | `{"validated_rows": 1}` |
| canonical_snapshot_fallback | `pass` | `{"validated_cards": 1}` |
| runtime_get_card_effect | `pass` | `{"validated_cards": 1}` |
| battle_execution | `pass` | `{"events": 6, "scenarios": 1}` |

## Battle Execution

```json
{
  "event_count": 6,
  "results": [
    {
      "card_name": "Horrifying Revelation",
      "cards_discarded": 1,
      "cards_milled": 1,
      "resolution_order": "discard_then_mill",
      "scenario": "Horrifying Revelation target player discards then mills",
      "target_player": "Opponent"
    }
  ],
  "scenario_count": 1
}
```
