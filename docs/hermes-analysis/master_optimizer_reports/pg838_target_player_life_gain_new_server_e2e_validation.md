# Battle Package End-to-End Validation

- Generated UTC: `2026-07-12T19:09:06.775885+00:00`
- Package ID: `pg838_target_player_life_gain_new_server_manifest`
- Status: `pass`
- Database target: `127.0.0.1:15432/halder`
- SQLite DB: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db`
- Snapshot: `docs/hermes-analysis/master_optimizer_reports/pg838_target_player_life_gain_new_server_pg_to_sqlite_sync_tracked_snapshot.json`

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
      "card_name": "Heroes' Reunion",
      "life_after": 27,
      "life_gained": 7,
      "scenario": "Heroes' Reunion target player gains life",
      "target_player": "Spell Controller"
    },
    {
      "card_name": "Natural Spring",
      "life_after": 28,
      "life_gained": 8,
      "scenario": "Natural Spring target player gains life",
      "target_player": "Spell Controller"
    },
    {
      "card_name": "Soothing Balm",
      "life_after": 25,
      "life_gained": 5,
      "scenario": "Soothing Balm target player gains life",
      "target_player": "Spell Controller"
    }
  ],
  "scenario_count": 3
}
```
