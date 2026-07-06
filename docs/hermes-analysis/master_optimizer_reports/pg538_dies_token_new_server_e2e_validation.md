# Battle Package End-to-End Validation

- Generated UTC: `2026-07-06T00:15:51.346356+00:00`
- Package ID: `pg538_dies_token_new_server_package_manifest`
- Status: `pass`
- Database target: `143.198.230.247:5433/halder`
- SQLite DB: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db`
- Snapshot: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/manaloom-knowledge/scripts/known_cards_canonical_snapshot.json`

## Stage Results

| Stage | Status | Evidence |
| --- | --- | --- |
| postgres_source_of_truth | `pass` | `{"validated_rows": 2}` |
| sqlite_hermes_cache | `pass` | `{"validated_rows": 2}` |
| canonical_snapshot_fallback | `pass` | `{"validated_cards": 2}` |
| runtime_get_card_effect | `pass` | `{"validated_cards": 2}` |
| battle_execution | `pass` | `{"events": 4, "scenarios": 2}` |

## Battle Execution

```json
{
  "event_count": 4,
  "results": [
    {
      "card_name": "Carrier Thrall",
      "sacrifice_for_colorless_mana": true,
      "scenario": "Carrier Thrall dies and creates modeled creature tokens",
      "token_name": "Eldrazi Scion Token",
      "token_tapped": false,
      "tokens_created": 1,
      "validated_keywords": []
    },
    {
      "card_name": "Gravpack Monoist",
      "sacrifice_for_colorless_mana": false,
      "scenario": "Gravpack Monoist dies and creates modeled creature tokens",
      "token_name": "Robot Token",
      "token_tapped": true,
      "tokens_created": 1,
      "validated_keywords": [
        "flying"
      ]
    }
  ],
  "scenario_count": 2
}
```
