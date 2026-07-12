# Battle Package End-to-End Validation

- Generated UTC: `2026-07-12T21:46:09.569088+00:00`
- Package ID: `pg846_etb_context_draw_new_server_manifest`
- Status: `pass`
- Database target: `127.0.0.1:15432/halder`
- SQLite DB: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db`
- Snapshot: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/manaloom-knowledge/scripts/known_cards_canonical_snapshot.json`

## Stage Results

| Stage | Status | Evidence |
| --- | --- | --- |
| postgres_source_of_truth | `pass` | `{"validated_rows": 5}` |
| sqlite_hermes_cache | `pass` | `{"validated_rows": 5}` |
| canonical_snapshot_fallback | `pass` | `{"validated_cards": 5}` |
| runtime_get_card_effect | `pass` | `{"validated_cards": 5}` |
| battle_execution | `pass` | `{"events": 5, "scenarios": 5}` |

## Battle Execution

```json
{
  "event_count": 5,
  "results": [
    {
      "card_name": "Clockwork Servant",
      "cards_drawn": 1,
      "hand_after": 1,
      "scenario": "Clockwork Servant draws on ETB",
      "validated_keywords": []
    },
    {
      "card_name": "Orator of Ojutai",
      "cards_drawn": 1,
      "hand_after": 1,
      "scenario": "Orator of Ojutai draws on ETB",
      "validated_keywords": [
        "flying",
        "defender"
      ]
    },
    {
      "card_name": "Silkweaver Elite",
      "cards_drawn": 1,
      "hand_after": 1,
      "scenario": "Silkweaver Elite draws on ETB",
      "validated_keywords": [
        "reach"
      ]
    },
    {
      "card_name": "Skyship Buccaneer",
      "cards_drawn": 1,
      "hand_after": 1,
      "scenario": "Skyship Buccaneer draws on ETB",
      "validated_keywords": [
        "flying"
      ]
    },
    {
      "card_name": "Storm Fleet Spy",
      "cards_drawn": 1,
      "hand_after": 1,
      "scenario": "Storm Fleet Spy draws on ETB",
      "validated_keywords": []
    }
  ],
  "scenario_count": 5
}
```
