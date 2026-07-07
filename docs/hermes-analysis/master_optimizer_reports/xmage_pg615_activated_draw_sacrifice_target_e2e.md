# Battle Package End-to-End Validation

- Generated UTC: `2026-07-07T12:51:22.275732+00:00`
- Package ID: `xmage_pg615_activated_draw_sacrifice_target_manifest`
- Status: `pass`
- Database target: `127.0.0.1:15432/halder`
- SQLite DB: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db`
- Snapshot: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/manaloom-knowledge/scripts/known_cards_canonical_snapshot.json`

## Stage Results

| Stage | Status | Evidence |
| --- | --- | --- |
| postgres_source_of_truth | `pass` | `{"validated_rows": 2}` |
| sqlite_hermes_cache | `pass` | `{"validated_rows": 2}` |
| canonical_snapshot_fallback | `pass` | `{"validated_cards": 2}` |
| runtime_get_card_effect | `pass` | `{"validated_cards": 2}` |
| battle_execution | `pass` | `{"events": 2, "scenarios": 2}` |

## Battle Execution

```json
{
  "event_count": 2,
  "results": [
    {
      "card_name": "Sage of Lat-Nam",
      "cards_drawn": 1,
      "discarded_count": 0,
      "life_paid": 0,
      "sacrificed_source": false,
      "scenario": "Sage of Lat-Nam activates draw ability",
      "source_tapped": true,
      "target_sacrificed": true
    },
    {
      "card_name": "Thraxodemon",
      "cards_drawn": 1,
      "discarded_count": 0,
      "life_paid": 0,
      "sacrificed_source": false,
      "scenario": "Thraxodemon activates draw ability",
      "source_tapped": true,
      "target_sacrificed": true
    }
  ],
  "scenario_count": 2
}
```
