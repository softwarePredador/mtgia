# Battle Package End-to-End Validation

- Generated UTC: `2026-07-08T19:04:52.904281+00:00`
- Package ID: `pg668_cant_be_countered_damage_package_manifest`
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
| battle_execution | `pass` | `{"events": 6, "scenarios": 2}` |

## Battle Execution

```json
{
  "event_count": 6,
  "results": [
    {
      "cant_be_countered": true,
      "card_name": "Heated Debate",
      "controller_life": 10,
      "damage": 4,
      "life_gained": 0,
      "opponent_life": 20,
      "scenario": "Heated Debate deals fixed target damage",
      "target": "E2E Fixed Damage Legal Target"
    },
    {
      "cant_be_countered": true,
      "card_name": "Rending Volley",
      "controller_life": 10,
      "damage": 4,
      "life_gained": 0,
      "opponent_life": 20,
      "scenario": "Rending Volley deals fixed target damage",
      "target": "E2E Fixed Damage Legal Target"
    }
  ],
  "scenario_count": 2
}
```
