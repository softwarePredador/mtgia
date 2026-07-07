# Battle Package End-to-End Validation

- Generated UTC: `2026-07-07T20:15:18.212525+00:00`
- Package ID: `pg636_delirium_threshold_boost_new_server_package_manifest`
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
      "active": true,
      "card_name": "Gnarlwood Dryad",
      "graveyard_count": 4,
      "power": 3,
      "scenario": "Gnarlwood Dryad graveyard threshold boost applies",
      "toughness": 3
    },
    {
      "active": true,
      "card_name": "Moldgraf Scavenger",
      "graveyard_count": 4,
      "power": 4,
      "scenario": "Moldgraf Scavenger graveyard threshold boost applies",
      "toughness": 1
    }
  ],
  "scenario_count": 2
}
```
