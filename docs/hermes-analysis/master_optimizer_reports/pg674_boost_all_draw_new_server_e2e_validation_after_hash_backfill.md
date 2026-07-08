# Battle Package End-to-End Validation

- Generated UTC: `2026-07-08T22:18:08.973223+00:00`
- Package ID: `pg674_boost_all_draw_new_server_package_manifest`
- Status: `pass`
- Database target: `127.0.0.1:15432/halder`
- SQLite DB: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db`
- Snapshot: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/manaloom-knowledge/scripts/known_cards_canonical_snapshot.json`

## Stage Results

| Stage | Status | Evidence |
| --- | --- | --- |
| postgres_source_of_truth | `pass` | `{"validated_rows": 3}` |
| sqlite_hermes_cache | `pass` | `{"validated_rows": 3}` |
| canonical_snapshot_fallback | `pass` | `{"validated_cards": 3}` |
| runtime_get_card_effect | `pass` | `{"validated_cards": 3}` |
| battle_execution | `pass` | `{"events": 15, "scenarios": 3}` |

## Battle Execution

```json
{
  "event_count": 15,
  "results": [
    {
      "affected_count": 1,
      "card_name": "Bewildering Blizzard",
      "creature_filter": {},
      "draw_count": 3,
      "scenario": "Bewildering Blizzard globally modifies creatures and draws 3",
      "target_controller": "opponents"
    },
    {
      "affected_count": 1,
      "card_name": "Blinding Spray",
      "creature_filter": {},
      "draw_count": 1,
      "scenario": "Blinding Spray globally modifies creatures and draws 1",
      "target_controller": "opponents"
    },
    {
      "affected_count": 2,
      "card_name": "Hydrolash",
      "creature_filter": {
        "combat_state": "attacking"
      },
      "draw_count": 1,
      "scenario": "Hydrolash globally modifies creatures and draws 1",
      "target_controller": "all"
    }
  ],
  "scenario_count": 3
}
```
