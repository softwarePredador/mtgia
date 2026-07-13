# Battle Package End-to-End Validation

- Generated UTC: `2026-07-13T04:49:59.075256+00:00`
- Package ID: `pg863_destroy_mana_ritual_new_server_manifest`
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
| battle_execution | `pass` | `{"events": 24, "scenarios": 4}` |

## Battle Execution

```json
{
  "event_count": 24,
  "results": [
    {
      "card_name": "Deconstruct",
      "mana_added": 3,
      "mana_delta": {
        "black": 0,
        "blue": 0,
        "colorless": 0,
        "generic": 0,
        "green": 3,
        "red": 0,
        "white": 0,
        "wildcard": 0
      },
      "scenario": "Deconstruct destroys target and adds modeled mana",
      "target": "E2E Legal Destroy Mana Target",
      "target_moved_to_graveyard": true
    },
    {
      "card_name": "Liturgy of Blood",
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
      "scenario": "Liturgy of Blood destroys target and adds modeled mana",
      "target": "E2E Legal Destroy Mana Target",
      "target_moved_to_graveyard": true
    },
    {
      "card_name": "Seismic Spike",
      "mana_added": 2,
      "mana_delta": {
        "black": 0,
        "blue": 0,
        "colorless": 0,
        "generic": 0,
        "green": 0,
        "red": 2,
        "white": 0,
        "wildcard": 0
      },
      "scenario": "Seismic Spike destroys target and adds modeled mana",
      "target": "E2E Legal Destroy Mana Target",
      "target_moved_to_graveyard": true
    },
    {
      "card_name": "Turn to Dust",
      "mana_added": 1,
      "mana_delta": {
        "black": 0,
        "blue": 0,
        "colorless": 0,
        "generic": 0,
        "green": 1,
        "red": 0,
        "white": 0,
        "wildcard": 0
      },
      "scenario": "Turn to Dust destroys target and adds modeled mana",
      "target": "E2E Legal Destroy Mana Target",
      "target_moved_to_graveyard": true
    }
  ],
  "scenario_count": 4
}
```
