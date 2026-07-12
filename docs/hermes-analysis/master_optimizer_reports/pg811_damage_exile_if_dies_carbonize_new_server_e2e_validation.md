# Battle Package End-to-End Validation

- Generated UTC: `2026-07-12T06:44:08.112803+00:00`
- Package ID: `pg811_damage_exile_if_dies_carbonize_new_server_manifest`
- Status: `pass`
- Database target: `127.0.0.1:15432/halder`
- SQLite DB: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db`
- Snapshot: `docs/hermes-analysis/master_optimizer_reports/pg811_damage_exile_if_dies_carbonize_new_server_canonical_fallback.json`

## Stage Results

| Stage | Status | Evidence |
| --- | --- | --- |
| postgres_source_of_truth | `pass` | `{"validated_rows": 1}` |
| sqlite_hermes_cache | `pass` | `{"validated_rows": 1}` |
| canonical_snapshot_fallback | `pass` | `{"validated_cards": 1}` |
| runtime_get_card_effect | `pass` | `{"validated_cards": 1}` |
| battle_execution | `pass` | `{"events": 3, "scenarios": 1}` |

## Battle Execution

```json
{
  "event_count": 3,
  "results": [
    {
      "additional_cost": null,
      "card_name": "Carbonize",
      "controller_life": 10,
      "controller_treasures": 0,
      "damage": 3,
      "exile_if_dies_from_damage": true,
      "life_gained": 0,
      "opponent_life": 20,
      "scenario": "Carbonize deals fixed target damage",
      "shuffled_self_into_library": false,
      "target": "E2E Fixed Damage Legal Target",
      "treasures_created": 0
    }
  ],
  "scenario_count": 1
}
```
