# Battle Package End-to-End Validation

- Generated UTC: `2026-07-06T02:49:28.693763+00:00`
- Package ID: `pg544_multi_trigger_tokens_new_server_package_manifest`
- Status: `pass`
- Database target: `143.198.230.247:5433/halder`
- SQLite DB: `docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db`
- Snapshot: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/manaloom-knowledge/scripts/known_cards_canonical_snapshot.json`

## Stage Results

| Stage | Status | Evidence |
| --- | --- | --- |
| postgres_source_of_truth | `pass` | `{"validated_rows": 4}` |
| sqlite_hermes_cache | `pass` | `{"validated_rows": 4}` |
| canonical_snapshot_fallback | `pass` | `{"validated_cards": 4}` |
| runtime_get_card_effect | `pass` | `{"validated_cards": 4}` |
| battle_execution | `pass` | `{"events": 7, "scenarios": 4}` |

## Battle Execution

```json
{
  "event_count": 7,
  "results": [
    {
      "card_name": "Triplicate Titan",
      "sacrifice_for_colorless_mana": false,
      "scenario": "Triplicate Titan dies and creates modeled creature tokens",
      "token_name": null,
      "token_names": [
        "Golem Token",
        "Golem Token",
        "Golem Token"
      ],
      "token_tapped": false,
      "tokens_created": 3,
      "validated_keywords": [
        "flying",
        "trample",
        "vigilance"
      ]
    },
    {
      "card_name": "Trostani's Summoner",
      "scenario": "Trostani's Summoner enters and creates modeled creature tokens",
      "token_names": [
        "Centaur Token",
        "Knight Token",
        "Rhino Token"
      ],
      "tokens_created": 3,
      "validated_keywords": []
    },
    {
      "card_name": "Wurmcoil Engine",
      "sacrifice_for_colorless_mana": false,
      "scenario": "Wurmcoil Engine dies and creates modeled creature tokens",
      "token_name": null,
      "token_names": [
        "Phyrexian Wurm Token",
        "Phyrexian Wurm Token"
      ],
      "token_tapped": false,
      "tokens_created": 2,
      "validated_keywords": [
        "deathtouch",
        "lifelink"
      ]
    },
    {
      "card_name": "Wurmcoil Larva",
      "sacrifice_for_colorless_mana": false,
      "scenario": "Wurmcoil Larva dies and creates modeled creature tokens",
      "token_name": null,
      "token_names": [
        "Phyrexian Wurm Token",
        "Phyrexian Wurm Token"
      ],
      "token_tapped": false,
      "tokens_created": 2,
      "validated_keywords": [
        "deathtouch",
        "lifelink"
      ]
    }
  ],
  "scenario_count": 4
}
```
