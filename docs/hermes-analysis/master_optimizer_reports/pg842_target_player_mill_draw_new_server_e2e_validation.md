# Battle Package End-to-End Validation

- Generated UTC: `2026-07-12T20:01:19.091544+00:00`
- Package ID: `pg842_target_player_mill_draw_new_server_manifest`
- Status: `pass`
- Database target: `127.0.0.1:15432/halder`
- SQLite DB: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db`
- Snapshot: `docs/hermes-analysis/master_optimizer_reports/pg842_target_player_mill_draw_new_server_canonical_snapshot.json`

## Stage Results

| Stage | Status | Evidence |
| --- | --- | --- |
| postgres_source_of_truth | `pass` | `{"validated_rows": 4}` |
| sqlite_hermes_cache | `pass` | `{"validated_rows": 4}` |
| canonical_snapshot_fallback | `pass` | `{"validated_cards": 4}` |
| runtime_get_card_effect | `pass` | `{"validated_cards": 4}` |
| battle_execution | `pass` | `{"events": 20, "scenarios": 4}` |

## Battle Execution

```json
{
  "event_count": 20,
  "results": [
    {
      "card_name": "Pilfered Plans",
      "cards_drawn": 2,
      "cards_milled": 2,
      "resolution_order": "mill_then_draw",
      "scenario": "Pilfered Plans target player mills then draw component",
      "target_player": "Opponent"
    },
    {
      "card_name": "Thassa's Bounty",
      "cards_drawn": 3,
      "cards_milled": 3,
      "resolution_order": "draw_then_mill",
      "scenario": "Thassa's Bounty target player mills then draw component",
      "target_player": "Opponent"
    },
    {
      "card_name": "Thought Scour",
      "cards_drawn": 1,
      "cards_milled": 2,
      "resolution_order": "mill_then_draw",
      "scenario": "Thought Scour target player mills then draw component",
      "target_player": "Opponent"
    },
    {
      "card_name": "Weight of Memory",
      "cards_drawn": 3,
      "cards_milled": 3,
      "resolution_order": "draw_then_mill",
      "scenario": "Weight of Memory target player mills then draw component",
      "target_player": "Opponent"
    }
  ],
  "scenario_count": 4
}
```
