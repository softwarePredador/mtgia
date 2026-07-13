# Battle Package End-to-End Validation

- Generated UTC: `2026-07-13T00:06:55.522033+00:00`
- Package ID: `pg852_activated_x_damage_new_server_package_manifest`
- Status: `pass`
- Database target: `127.0.0.1:15432/halder`
- SQLite DB: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db`
- Snapshot: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/manaloom-knowledge/scripts/known_cards_canonical_snapshot.json`

## Stage Results

| Stage | Status | Evidence |
| --- | --- | --- |
| postgres_source_of_truth | `pass` | `{"validated_rows": 3}` |
| sqlite_hermes_cache | `pass` | `{"validated_rows": 3}` |
| canonical_snapshot_fallback | `pass` | `{"validated_cards": 3}` |
| runtime_get_card_effect | `pass` | `{"validated_cards": 3}` |
| battle_execution | `pass` | `{"events": 8, "scenarios": 3}` |

## Battle Execution

```json
{
  "event_count": 8,
  "results": [
    {
      "card_name": "Ballista Squad",
      "controller_life": 40,
      "counter_cost_targets": [],
      "damage": 3,
      "discard_target": null,
      "discarded_count": 0,
      "exiled_top_library_count": 0,
      "life_paid": 0,
      "opponent_life": 7,
      "removed_counter_cost_count": 0,
      "removed_counter_cost_type": null,
      "scenario": "Ballista Squad activates damage ability",
      "tapped_cost_targets": [],
      "target": "E2E Legal Activated Damage Target",
      "target_destination": "graveyard",
      "target_result": "creature_destroyed"
    },
    {
      "card_name": "Cinder Elemental",
      "controller_life": 40,
      "counter_cost_targets": [],
      "damage": 3,
      "discard_target": null,
      "discarded_count": 0,
      "exiled_top_library_count": 0,
      "life_paid": 0,
      "opponent_life": 4,
      "removed_counter_cost_count": 0,
      "removed_counter_cost_type": null,
      "scenario": "Cinder Elemental activates damage ability",
      "tapped_cost_targets": [],
      "target": "Activated Opponent",
      "target_destination": null,
      "target_result": "player_damage"
    },
    {
      "card_name": "Pain Kami",
      "controller_life": 40,
      "counter_cost_targets": [],
      "damage": 3,
      "discard_target": null,
      "discarded_count": 0,
      "exiled_top_library_count": 0,
      "life_paid": 0,
      "opponent_life": 7,
      "removed_counter_cost_count": 0,
      "removed_counter_cost_type": null,
      "scenario": "Pain Kami activates damage ability",
      "tapped_cost_targets": [],
      "target": "E2E Legal Activated Damage Target",
      "target_destination": "graveyard",
      "target_result": "creature_destroyed"
    }
  ],
  "scenario_count": 3
}
```
