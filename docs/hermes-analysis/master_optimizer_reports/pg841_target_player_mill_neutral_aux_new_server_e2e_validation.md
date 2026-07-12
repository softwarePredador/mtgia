# Battle Package End-to-End Validation

- Generated UTC: `2026-07-12T19:46:32.123866+00:00`
- Package ID: `pg841_target_player_mill_neutral_aux_new_server_manifest`
- Status: `pass`
- Database target: `127.0.0.1:15432/halder`
- SQLite DB: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db`
- Snapshot: `docs/hermes-analysis/master_optimizer_reports/pg841_target_player_mill_neutral_aux_new_server_canonical_snapshot.json`

## Stage Results

| Stage | Status | Evidence |
| --- | --- | --- |
| postgres_source_of_truth | `pass` | `{"validated_rows": 2}` |
| sqlite_hermes_cache | `pass` | `{"validated_rows": 2}` |
| canonical_snapshot_fallback | `pass` | `{"validated_cards": 2}` |
| runtime_get_card_effect | `pass` | `{"validated_cards": 2}` |
| battle_execution | `pass` | `{"events": 4, "scenarios": 2}` |

## Battle Execution

```json
{
  "event_count": 4,
  "results": [
    {
      "card_name": "Compelling Argument",
      "cards_milled": 5,
      "scenario": "Compelling Argument target player mills cards",
      "target_player": "Opponent"
    },
    {
      "card_name": "Dream Twist",
      "cards_milled": 3,
      "scenario": "Dream Twist target player mills cards",
      "target_player": "Opponent"
    }
  ],
  "scenario_count": 2
}
```
