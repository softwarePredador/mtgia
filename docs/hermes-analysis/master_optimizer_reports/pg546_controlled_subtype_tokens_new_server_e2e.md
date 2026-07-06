# Battle Package End-to-End Validation

- Generated UTC: `2026-07-06T03:20:13.932863+00:00`
- Package ID: `pg546_controlled_subtype_tokens_new_server_package_manifest`
- Status: `pass`
- Database target: `143.198.230.247:5433/halder`
- SQLite DB: `docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db`
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
      "card_name": "Elven Ambush",
      "scenario": "Elven Ambush creates modeled creature tokens",
      "token_name": "Elf Warrior Token",
      "token_tapped": false,
      "tokens_created": 3
    },
    {
      "card_name": "Elvish Promenade",
      "scenario": "Elvish Promenade creates modeled creature tokens",
      "token_name": "Elf Warrior Token",
      "token_tapped": false,
      "tokens_created": 3
    }
  ],
  "scenario_count": 2
}
```
