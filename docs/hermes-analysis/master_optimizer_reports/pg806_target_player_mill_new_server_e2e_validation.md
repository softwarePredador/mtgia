# Battle Package End-to-End Validation

- Generated UTC: `2026-07-12T04:49:43.946397+00:00`
- Package ID: `pg806_target_player_mill_new_server_manifest`
- Status: `pass`
- Database target: `127.0.0.1:15432/halder`
- SQLite DB: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db`
- Snapshot: `docs/hermes-analysis/master_optimizer_reports/pg806_target_player_mill_new_server_canonical_fallback.json`

## Stage Results

| Stage | Status | Evidence |
| --- | --- | --- |
| postgres_source_of_truth | `pass` | `{"validated_rows": 3}` |
| sqlite_hermes_cache | `pass` | `{"validated_rows": 3}` |
| canonical_snapshot_fallback | `pass` | `{"validated_cards": 3}` |
| runtime_get_card_effect | `pass` | `{"validated_cards": 3}` |
| battle_execution | `pass` | `{"events": 6, "scenarios": 3}` |

## Battle Execution

```json
{
  "event_count": 6,
  "results": [
    {
      "card_name": "Glimpse the Unthinkable",
      "cards_milled": 10,
      "scenario": "Glimpse the Unthinkable target player mills cards",
      "target_player": "Opponent"
    },
    {
      "card_name": "Mind Sculpt",
      "cards_milled": 7,
      "scenario": "Mind Sculpt target player mills cards",
      "target_player": "Opponent"
    },
    {
      "card_name": "Tome Scour",
      "cards_milled": 5,
      "scenario": "Tome Scour target player mills cards",
      "target_player": "Opponent"
    }
  ],
  "scenario_count": 3
}
```
