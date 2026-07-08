# Battle Package End-to-End Validation

- Generated UTC: `2026-07-08T14:29:56.348447+00:00`
- Package ID: `pg660_combat_damage_optional_draw_new_server_package_manifest`
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
      "card_name": "Academy Raider",
      "cards_drawn": 1,
      "optional_cost": "discard_card",
      "scenario": "Academy Raider combat damage draw trigger",
      "source_sacrificed": false
    },
    {
      "card_name": "Impaler Shrike",
      "cards_drawn": 3,
      "optional_cost": "sacrifice_source",
      "scenario": "Impaler Shrike combat damage draw trigger",
      "source_sacrificed": true
    }
  ],
  "scenario_count": 2
}
```
