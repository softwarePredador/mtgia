# Battle Package End-to-End Validation

- Generated UTC: `2026-07-12T21:21:43.179271+00:00`
- Package ID: `pg845_conditional_activated_draw_new_server_manifest`
- Status: `pass`
- Database target: `127.0.0.1:15432/halder`
- SQLite DB: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db`
- Snapshot: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/manaloom-knowledge/scripts/known_cards_canonical_snapshot.json`

## Stage Results

| Stage | Status | Evidence |
| --- | --- | --- |
| postgres_source_of_truth | `pass` | `{"validated_rows": 5}` |
| sqlite_hermes_cache | `pass` | `{"validated_rows": 5}` |
| canonical_snapshot_fallback | `pass` | `{"validated_cards": 5}` |
| runtime_get_card_effect | `pass` | `{"validated_cards": 5}` |
| battle_execution | `pass` | `{"events": 5, "scenarios": 5}` |

## Battle Execution

```json
{
  "event_count": 5,
  "results": [
    {
      "card_name": "Endless Atlas",
      "cards_drawn": 1,
      "discarded_count": 0,
      "exiled_source_from_graveyard": false,
      "life_paid": 0,
      "removed_counter_cost_count": 0,
      "removed_counter_cost_type": null,
      "sacrificed_source": false,
      "scenario": "Endless Atlas activates draw ability",
      "source_tapped": true,
      "source_zone": "battlefield",
      "tapped_cost_targets": [],
      "target_sacrificed": false
    },
    {
      "card_name": "Falkenrath Pit Fighter",
      "cards_drawn": 2,
      "discarded_count": 1,
      "exiled_source_from_graveyard": false,
      "life_paid": 0,
      "removed_counter_cost_count": 0,
      "removed_counter_cost_type": null,
      "sacrificed_source": false,
      "scenario": "Falkenrath Pit Fighter activates draw ability",
      "source_tapped": false,
      "source_zone": "battlefield",
      "tapped_cost_targets": [],
      "target_sacrificed": true
    },
    {
      "card_name": "Fool's Tome",
      "cards_drawn": 1,
      "discarded_count": 0,
      "exiled_source_from_graveyard": false,
      "life_paid": 0,
      "removed_counter_cost_count": 0,
      "removed_counter_cost_type": null,
      "sacrificed_source": false,
      "scenario": "Fool's Tome activates draw ability",
      "source_tapped": true,
      "source_zone": "battlefield",
      "tapped_cost_targets": [],
      "target_sacrificed": false
    },
    {
      "card_name": "Ragamuffyn",
      "cards_drawn": 1,
      "discarded_count": 0,
      "exiled_source_from_graveyard": false,
      "life_paid": 0,
      "removed_counter_cost_count": 0,
      "removed_counter_cost_type": null,
      "sacrificed_source": false,
      "scenario": "Ragamuffyn activates draw ability",
      "source_tapped": true,
      "source_zone": "battlefield",
      "tapped_cost_targets": [],
      "target_sacrificed": true
    },
    {
      "card_name": "Tapestry of the Ages",
      "cards_drawn": 1,
      "discarded_count": 0,
      "exiled_source_from_graveyard": false,
      "life_paid": 0,
      "removed_counter_cost_count": 0,
      "removed_counter_cost_type": null,
      "sacrificed_source": false,
      "scenario": "Tapestry of the Ages activates draw ability",
      "source_tapped": true,
      "source_zone": "battlefield",
      "tapped_cost_targets": [],
      "target_sacrificed": false
    }
  ],
  "scenario_count": 5
}
```
