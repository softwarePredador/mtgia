# Battle Package End-to-End Validation

- Generated UTC: `2026-07-08T17:58:17.776228+00:00`
- Package ID: `pg665_etb_conditional_cast_mana_new_server_package_manifest`
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
      "card_name": "Coal Stoker",
      "cast_from_zone": "hand",
      "mana_added": 3,
      "produced_mana_symbols": [
        "R",
        "R",
        "R"
      ],
      "scenario": "Coal Stoker ETB adds fixed mana",
      "validated_condition": "cast_from_hand"
    },
    {
      "card_name": "Iridescent Tiger",
      "cast_from_zone": "graveyard",
      "mana_added": 5,
      "produced_mana_symbols": [
        "W",
        "U",
        "B",
        "R",
        "G"
      ],
      "scenario": "Iridescent Tiger ETB adds fixed mana",
      "validated_condition": "cast"
    }
  ],
  "scenario_count": 2
}
```
