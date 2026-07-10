# Battle Package End-to-End Validation

- Generated UTC: `2026-07-10T20:34:01.145829+00:00`
- Package ID: `pg720_token_variable_arg_new_server_package_manifest`
- Status: `pass`
- Database target: `127.0.0.1:15432/halder`
- SQLite DB: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db`
- Snapshot: `docs/hermes-analysis/manaloom-knowledge/scripts/known_cards_canonical_snapshot.json`

## Stage Results

| Stage | Status | Evidence |
| --- | --- | --- |
| postgres_source_of_truth | `pass` | `{"validated_rows": 4}` |
| sqlite_hermes_cache | `pass` | `{"validated_rows": 4}` |
| canonical_snapshot_fallback | `pass` | `{"validated_cards": 4}` |
| runtime_get_card_effect | `pass` | `{"validated_cards": 4}` |
| battle_execution | `pass` | `{"events": 6, "scenarios": 4}` |

## Battle Execution

```json
{
  "event_count": 6,
  "results": [
    {
      "card_name": "Ant Queen",
      "discard_target": null,
      "discarded_count": 0,
      "exiled_source_from_graveyard": false,
      "scenario": "Ant Queen activates token ability",
      "token_name": "Insect Token",
      "tokens_created": 1
    },
    {
      "card_name": "Broodmate Dragon",
      "scenario": "Broodmate Dragon enters and creates modeled creature tokens",
      "token_cant_block": false,
      "token_names": [
        "Dragon Token"
      ],
      "tokens_created": 1,
      "validated_keywords": [
        "flying"
      ]
    },
    {
      "card_name": "Roc Egg",
      "sacrifice_for_colorless_mana": false,
      "scenario": "Roc Egg dies and creates modeled creature tokens",
      "token_cant_block": false,
      "token_name": "Bird Token",
      "token_names": [
        "Bird Token"
      ],
      "token_tapped": false,
      "tokens_created": 1,
      "validated_keywords": [
        "defender"
      ]
    },
    {
      "card_name": "Sprouting Thrinax",
      "sacrifice_for_colorless_mana": false,
      "scenario": "Sprouting Thrinax dies and creates modeled creature tokens",
      "token_cant_block": false,
      "token_name": "Saproling Token",
      "token_names": [
        "Saproling Token",
        "Saproling Token",
        "Saproling Token"
      ],
      "token_tapped": false,
      "tokens_created": 3,
      "validated_keywords": []
    }
  ],
  "scenario_count": 4
}
```
