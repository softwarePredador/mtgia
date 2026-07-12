# Battle Package End-to-End Validation

- Generated UTC: `2026-07-12T19:39:11.553633+00:00`
- Package ID: `pg840_target_player_x_life_gain_new_server_manifest`
- Status: `pass`
- Database target: `127.0.0.1:15432/halder`
- SQLite DB: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db`
- Snapshot: `docs/hermes-analysis/master_optimizer_reports/pg840_target_player_x_life_gain_new_server_canonical_snapshot.json`

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
      "card_name": "Stream of Life",
      "life_after": 25,
      "life_gain_amount_source": "x_value",
      "life_gained": 5,
      "scenario": "Stream of Life target player gains life",
      "target_player": "Spell Controller",
      "x_value": 5
    }
  ],
  "scenario_count": 1
}
```
