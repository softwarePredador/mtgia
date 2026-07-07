# Battle Package End-to-End Validation

- Generated UTC: `2026-07-07T17:28:03.943907+00:00`
- Package ID: `pg627_activated_destroy_discard_cost_new_server_package_manifest`
- Status: `pass`
- Database target: `127.0.0.1:15432/halder`
- SQLite DB: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db`
- Snapshot: `docs/hermes-analysis/manaloom-knowledge/scripts/known_cards_canonical_snapshot.json`

## Stage Results

| Stage | Status | Evidence |
| --- | --- | --- |
| postgres_source_of_truth | `pass` | `{"validated_rows": 4}` |
| sqlite_hermes_cache | `pass` | `{"validated_rows": 4}` |
| canonical_snapshot_fallback | `pass` | `{"validated_cards": 4}` |
| runtime_get_card_effect | `pass` | `{"validated_cards": 4}` |
| battle_execution | `pass` | `{"events": 12, "scenarios": 4}` |

## Battle Execution

```json
{
  "event_count": 12,
  "results": [
    {
      "card_name": "Blaster Mage",
      "destination": "graveyard",
      "discarded_count": 1,
      "sacrificed_source": false,
      "scenario": "Blaster Mage activates destroy ability",
      "source_tapped": true,
      "target": "E2E Legal Activated Destroy Target",
      "target_sacrificed": false
    },
    {
      "card_name": "Devout Witness",
      "destination": "graveyard",
      "discarded_count": 1,
      "sacrificed_source": false,
      "scenario": "Devout Witness activates destroy ability",
      "source_tapped": true,
      "target": "E2E Legal Activated Destroy Target",
      "target_sacrificed": false
    },
    {
      "card_name": "Notorious Assassin",
      "destination": "graveyard",
      "discarded_count": 1,
      "sacrificed_source": false,
      "scenario": "Notorious Assassin activates destroy ability",
      "source_tapped": true,
      "target": "E2E Legal Activated Destroy Target",
      "target_sacrificed": false
    },
    {
      "card_name": "Seismic Mage",
      "destination": "graveyard",
      "discarded_count": 1,
      "sacrificed_source": false,
      "scenario": "Seismic Mage activates destroy ability",
      "source_tapped": true,
      "target": "E2E Legal Activated Destroy Target",
      "target_sacrificed": false
    }
  ],
  "scenario_count": 4
}
```
