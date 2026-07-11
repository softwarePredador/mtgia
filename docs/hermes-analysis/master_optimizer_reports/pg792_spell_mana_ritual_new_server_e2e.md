# Battle Package End-to-End Validation

- Generated UTC: `2026-07-11T22:59:30.038606+00:00`
- Package ID: `pg792_spell_mana_ritual_new_server_manifest`
- Status: `pass`
- Database target: `127.0.0.1:15432/halder`
- SQLite DB: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db`
- Snapshot: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/manaloom-knowledge/scripts/known_cards_canonical_snapshot.json`

## Stage Results

| Stage | Status | Evidence |
| --- | --- | --- |
| postgres_source_of_truth | `pass` | `{"validated_rows": 4}` |
| sqlite_hermes_cache | `pass` | `{"validated_rows": 4}` |
| canonical_snapshot_fallback | `pass` | `{"validated_cards": 4}` |
| runtime_get_card_effect | `pass` | `{"validated_cards": 4}` |
| battle_execution | `pass` | `{"events": 8, "scenarios": 4}` |

## Battle Execution

```json
{
  "event_count": 8,
  "results": [
    {
      "card": "Battle Hymn",
      "event": "ritual_mana_added",
      "mana_added": 3,
      "mana_delta": {
        "black": 0,
        "blue": 0,
        "colorless": 0,
        "generic": 0,
        "green": 0,
        "red": 3,
        "white": 0,
        "wildcard": 0
      },
      "scenario": "Battle Hymn resolves modeled mana ritual"
    },
    {
      "card": "Channel the Suns",
      "event": "ritual_mana_added",
      "mana_added": 5,
      "mana_delta": {
        "black": 1,
        "blue": 1,
        "colorless": 0,
        "generic": 0,
        "green": 1,
        "red": 1,
        "white": 1,
        "wildcard": 0
      },
      "scenario": "Channel the Suns resolves modeled mana ritual"
    },
    {
      "card": "Inner Fire",
      "event": "ritual_mana_added",
      "mana_added": 3,
      "mana_delta": {
        "black": 0,
        "blue": 0,
        "colorless": 0,
        "generic": 0,
        "green": 0,
        "red": 3,
        "white": 0,
        "wildcard": 0
      },
      "scenario": "Inner Fire resolves modeled mana ritual"
    },
    {
      "card": "Songs of the Damned",
      "event": "ritual_mana_added",
      "mana_added": 3,
      "mana_delta": {
        "black": 3,
        "blue": 0,
        "colorless": 0,
        "generic": 0,
        "green": 0,
        "red": 0,
        "white": 0,
        "wildcard": 0
      },
      "scenario": "Songs of the Damned resolves modeled mana ritual"
    }
  ],
  "scenario_count": 4
}
```
