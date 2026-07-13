# Battle Package End-to-End Validation

- Generated UTC: `2026-07-13T05:35:37.414585+00:00`
- Package ID: `pg865_dynamic_target_player_life_gain_new_server_manifest`
- Status: `pass`
- Database target: `127.0.0.1:15432/halder`
- SQLite DB: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db`
- Snapshot: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/manaloom-knowledge/scripts/known_cards_canonical_snapshot.json`

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
      "card_name": "Congregate",
      "life_after": 30,
      "life_gain_amount_source": "battlefield_permanent_count",
      "life_gained": 10,
      "scenario": "Congregate target player gains life",
      "target_player": "Spell Controller",
      "x_value": null
    }
  ],
  "scenario_count": 1
}
```
