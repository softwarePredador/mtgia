# Battle Package End-to-End Validation

- Generated UTC: `2026-07-07T20:58:08.310640+00:00`
- Package ID: `pg639_modal_damage_destroy_new_server_package_manifest`
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
| battle_execution | `pass` | `{"events": 20, "scenarios": 5}` |

## Battle Execution

```json
{
  "event_count": 20,
  "results": [
    {
      "card_name": "Fiery Intervention",
      "damage_target_survived": "E2E Legal Modal Damage Target",
      "destination": "graveyard",
      "removed_target": "E2E Legal Modal Destroy Target",
      "scenario": "Fiery Intervention chooses destroy mode over damage mode",
      "selected_mode": "destroy_target"
    },
    {
      "card_name": "Molten Blast",
      "damage_target_survived": "E2E Legal Modal Damage Target",
      "destination": "graveyard",
      "removed_target": "E2E Legal Modal Destroy Target",
      "scenario": "Molten Blast chooses destroy mode over damage mode",
      "selected_mode": "destroy_target"
    },
    {
      "card_name": "Ready to Rumble",
      "damage_target_survived": "E2E Legal Modal Damage Target",
      "destination": "graveyard",
      "removed_target": "E2E Legal Modal Destroy Target",
      "scenario": "Ready to Rumble chooses destroy mode over damage mode",
      "selected_mode": "destroy_target"
    },
    {
      "card_name": "Rip Apart",
      "damage_target_survived": "E2E Legal Modal Damage Target",
      "destination": "graveyard",
      "removed_target": "E2E Legal Modal Destroy Target",
      "scenario": "Rip Apart chooses destroy mode over damage mode",
      "selected_mode": "destroy_target"
    },
    {
      "card_name": "Start from Scratch",
      "damage_target_survived": "E2E Legal Modal Damage Target",
      "destination": "graveyard",
      "removed_target": "E2E Legal Modal Destroy Target",
      "scenario": "Start from Scratch chooses destroy mode over damage mode",
      "selected_mode": "destroy_target"
    }
  ],
  "scenario_count": 5
}
```
