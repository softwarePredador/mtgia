# Battle Package End-to-End Validation

- Generated UTC: `2026-07-12T18:41:30.665997+00:00`
- Package ID: `pg837_discard_hand_draw_new_server_manifest`
- Status: `pass`
- Database target: `127.0.0.1:15432/halder`
- SQLite DB: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db`
- Snapshot: `docs/hermes-analysis/master_optimizer_reports/pg837_discard_hand_draw_new_server_pg_to_sqlite_sync_tracked_snapshot.json`

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
      "card_name": "Dangerous Wager",
      "cards_discarded": 3,
      "cards_drawn": 2,
      "discard_random": false,
      "order": "discard_then_draw",
      "scenario": "Dangerous Wager draws then discards"
    }
  ],
  "scenario_count": 1
}
```
