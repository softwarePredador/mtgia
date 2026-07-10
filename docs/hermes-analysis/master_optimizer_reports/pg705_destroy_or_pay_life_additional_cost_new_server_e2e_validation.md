# Battle Package End-to-End Validation

- Generated UTC: `2026-07-10T15:03:16.377926+00:00`
- Package ID: `pg705_destroy_or_pay_life_additional_cost_new_server_package_manifest`
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
| battle_execution | `pass` | `{"events": 20, "scenarios": 4}` |

## Battle Execution

```json
{
  "event_count": 20,
  "results": [
    {
      "additional_cost": "discard_card",
      "battlefield_names": [
        "E2E Illegal Removal Target"
      ],
      "card_name": "Bitter Triumph",
      "destination": "graveyard",
      "moved_names": [
        "E2E Legal Removal Target"
      ],
      "nonmatching_target": "E2E Illegal Removal Target",
      "scenario": "Bitter Triumph removes one legal target",
      "target": "E2E Legal Removal Target",
      "target_player": "Opponent"
    },
    {
      "additional_cost": "sacrifice_creature",
      "battlefield_names": [
        "E2E Illegal Removal Target"
      ],
      "card_name": "Bone Shards",
      "destination": "graveyard",
      "moved_names": [
        "E2E Legal Removal Target"
      ],
      "nonmatching_target": "E2E Illegal Removal Target",
      "scenario": "Bone Shards removes one legal target",
      "target": "E2E Legal Removal Target",
      "target_player": "Opponent"
    },
    {
      "additional_cost": "pay_life",
      "battlefield_names": [
        "E2E Illegal Removal Target"
      ],
      "card_name": "Final Payment",
      "destination": "graveyard",
      "moved_names": [
        "E2E Legal Removal Target"
      ],
      "nonmatching_target": "E2E Illegal Removal Target",
      "pay_life_amount": 5,
      "scenario": "Final Payment removes one legal target",
      "target": "E2E Legal Removal Target",
      "target_player": "Opponent"
    },
    {
      "additional_cost": "pay_life",
      "battlefield_names": [
        "E2E Illegal Removal Target"
      ],
      "card_name": "Fumarole",
      "destination": "graveyard",
      "moved_names": [
        "E2E Legal Removal Target"
      ],
      "nonmatching_target": "E2E Illegal Removal Target",
      "pay_life_amount": 3,
      "scenario": "Fumarole removes one legal target",
      "target": "E2E Legal Removal Target",
      "target_player": "Opponent"
    }
  ],
  "scenario_count": 4
}
```
