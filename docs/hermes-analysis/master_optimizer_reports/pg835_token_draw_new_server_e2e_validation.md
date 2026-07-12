# Battle Package End-to-End Validation

- Generated UTC: `2026-07-12T17:59:09.931947+00:00`
- Package ID: `pg835_token_draw_new_server_manifest`
- Status: `pass`
- Database target: `127.0.0.1:15432/halder`
- SQLite DB: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db`
- Snapshot: `docs/hermes-analysis/master_optimizer_reports/pg835_token_draw_new_server_pg_to_sqlite_sync_tracked_snapshot.json`

## Stage Results

| Stage | Status | Evidence |
| --- | --- | --- |
| postgres_source_of_truth | `pass` | `{"validated_rows": 4}` |
| sqlite_hermes_cache | `pass` | `{"validated_rows": 4}` |
| canonical_snapshot_fallback | `pass` | `{"validated_cards": 4}` |
| runtime_get_card_effect | `pass` | `{"validated_cards": 4}` |
| battle_execution | `pass` | `{"events": 13, "scenarios": 4}` |

## Battle Execution

```json
{
  "event_count": 13,
  "results": [
    {
      "card_name": "Glimmerburst",
      "cards_drawn": 2,
      "scenario": "Glimmerburst creates modeled creature tokens",
      "token_cant_block": false,
      "token_name": "Glimmer Token",
      "token_tapped": false,
      "tokens_created": 1
    },
    {
      "card_name": "Glittermonger",
      "discard_target": null,
      "discarded_count": 0,
      "exiled_source_from_graveyard": false,
      "scenario": "Glittermonger activates token ability",
      "token_name": "Treasure Token",
      "tokens_created": 1
    },
    {
      "card_name": "Halo Scarab",
      "discard_target": null,
      "discarded_count": 0,
      "exiled_source_from_graveyard": true,
      "scenario": "Halo Scarab activates token ability",
      "token_name": "Treasure Token",
      "tokens_created": 1
    },
    {
      "card_name": "Pirate's Prize",
      "cards_drawn": 2,
      "scenario": "Pirate's Prize creates modeled creature tokens",
      "token_cant_block": false,
      "token_name": "Treasure Token",
      "token_tapped": false,
      "tokens_created": 1
    }
  ],
  "scenario_count": 4
}
```
