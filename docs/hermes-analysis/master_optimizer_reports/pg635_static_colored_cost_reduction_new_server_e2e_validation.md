# Battle Package End-to-End Validation

- Generated UTC: `2026-07-07T19:54:22.206566+00:00`
- Package ID: `pg635_static_colored_cost_reduction_new_server_package_manifest`
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
| battle_execution | `pass` | `{"events": 0, "scenarios": 2}` |

## Battle Execution

```json
{
  "event_count": 0,
  "results": [
    {
      "card_name": "Edgewalker",
      "colored": {
        "black": 0,
        "white": 0
      },
      "generic": 1,
      "scenario": "Edgewalker reduces matching spell cost",
      "static_cost_reduction_color_symbols": [
        "W",
        "B"
      ],
      "static_cost_reduction_total": 2,
      "target_spell": "E2E Matching Reduced Spell"
    },
    {
      "card_name": "Ragemonger",
      "colored": {
        "black": 0,
        "red": 0
      },
      "generic": 1,
      "scenario": "Ragemonger reduces matching spell cost",
      "static_cost_reduction_color_symbols": [
        "B",
        "R"
      ],
      "static_cost_reduction_total": 2,
      "target_spell": "E2E Matching Reduced Spell"
    }
  ],
  "scenario_count": 2
}
```
