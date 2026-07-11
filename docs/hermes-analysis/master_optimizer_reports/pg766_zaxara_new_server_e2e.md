# Battle Package End-to-End Validation

- Generated UTC: `2026-07-11T14:08:23.139544+00:00`
- Package ID: `pg766_zaxara_new_server_manifest`
- Status: `pass`
- Database target: `127.0.0.1:15432/halder`
- SQLite DB: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db`
- Snapshot: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/manaloom-knowledge/scripts/known_cards_canonical_snapshot.json`

## Stage Results

| Stage | Status | Evidence |
| --- | --- | --- |
| postgres_source_of_truth | `pass` | `{"validated_rows": 1}` |
| sqlite_hermes_cache | `pass` | `{"validated_rows": 1}` |
| canonical_snapshot_fallback | `pass` | `{"validated_cards": 1}` |
| runtime_get_card_effect | `pass` | `{"validated_cards": 1}` |
| battle_execution | `pass` | `{"events": 1, "scenarios": 1}` |

## Battle Execution

```json
{
  "event_count": 1,
  "results": [
    {
      "card_name": "Zaxara, the Exemplary",
      "scenario": "Zaxara, the Exemplary creates tokens when matching spell is cast",
      "token_names": [
        "Hydra Token"
      ],
      "token_plus_one_counters": [
        2
      ],
      "tokens_created": 1,
      "trigger": "spell_cast",
      "trigger_spell": "E2E X Spell for Zaxara, the Exemplary",
      "x_value": 2
    }
  ],
  "scenario_count": 1
}
```
