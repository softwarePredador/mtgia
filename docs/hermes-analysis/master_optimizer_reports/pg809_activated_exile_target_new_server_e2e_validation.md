# Battle Package End-to-End Validation

- Generated UTC: `2026-07-12T06:17:39.462544+00:00`
- Package ID: `pg809_activated_exile_target_new_server_manifest`
- Status: `pass`
- Database target: `127.0.0.1:15432/halder`
- SQLite DB: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db`
- Snapshot: `docs/hermes-analysis/master_optimizer_reports/pg809_activated_exile_target_new_server_canonical_fallback.json`

## Stage Results

| Stage | Status | Evidence |
| --- | --- | --- |
| postgres_source_of_truth | `pass` | `{"validated_rows": 9}` |
| sqlite_hermes_cache | `pass` | `{"validated_rows": 9}` |
| canonical_snapshot_fallback | `pass` | `{"validated_cards": 9}` |
| runtime_get_card_effect | `pass` | `{"validated_cards": 9}` |
| battle_execution | `pass` | `{"events": 18, "scenarios": 9}` |

## Battle Execution

```json
{
  "event_count": 18,
  "results": [
    {
      "card_name": "Brittle Effigy",
      "destination": "exile",
      "discarded_count": 0,
      "sacrificed_source": false,
      "sacrificed_targets": [],
      "scenario": "Brittle Effigy activates destroy ability",
      "source_tapped": true,
      "tapped_cost_targets": [],
      "target": "E2E Legal Activated Destroy Target",
      "target_sacrificed": false
    },
    {
      "card_name": "Catapult Master",
      "destination": "exile",
      "discarded_count": 0,
      "sacrificed_source": false,
      "sacrificed_targets": [],
      "scenario": "Catapult Master activates destroy ability",
      "source_tapped": false,
      "tapped_cost_targets": [
        "E2E Activated Destroy Tap Cost Target 1",
        "E2E Activated Destroy Tap Cost Target 2",
        "E2E Activated Destroy Tap Cost Target 3",
        "E2E Activated Destroy Tap Cost Target 4",
        "E2E Activated Destroy Tap Cost Target 5"
      ],
      "target": "E2E Legal Activated Destroy Target",
      "target_sacrificed": false
    },
    {
      "card_name": "Devout Chaplain",
      "destination": "exile",
      "discarded_count": 0,
      "sacrificed_source": false,
      "sacrificed_targets": [],
      "scenario": "Devout Chaplain activates destroy ability",
      "source_tapped": true,
      "tapped_cost_targets": [
        "E2E Activated Destroy Tap Cost Target 1",
        "E2E Activated Destroy Tap Cost Target 2"
      ],
      "target": "E2E Legal Activated Destroy Target",
      "target_sacrificed": false
    },
    {
      "card_name": "Lawbringer",
      "destination": "exile",
      "discarded_count": 0,
      "sacrificed_source": true,
      "sacrificed_targets": [],
      "scenario": "Lawbringer activates destroy ability",
      "source_tapped": true,
      "tapped_cost_targets": [],
      "target": "E2E Legal Activated Destroy Target",
      "target_sacrificed": false
    },
    {
      "card_name": "Lieutenant Kirtar",
      "destination": "exile",
      "discarded_count": 0,
      "sacrificed_source": true,
      "sacrificed_targets": [],
      "scenario": "Lieutenant Kirtar activates destroy ability",
      "source_tapped": false,
      "tapped_cost_targets": [],
      "target": "E2E Legal Activated Destroy Target",
      "target_sacrificed": false
    },
    {
      "card_name": "Lightbringer",
      "destination": "exile",
      "discarded_count": 0,
      "sacrificed_source": true,
      "sacrificed_targets": [],
      "scenario": "Lightbringer activates destroy ability",
      "source_tapped": true,
      "tapped_cost_targets": [],
      "target": "E2E Legal Activated Destroy Target",
      "target_sacrificed": false
    },
    {
      "card_name": "Silverchase Fox",
      "destination": "exile",
      "discarded_count": 0,
      "sacrificed_source": true,
      "sacrificed_targets": [],
      "scenario": "Silverchase Fox activates destroy ability",
      "source_tapped": false,
      "tapped_cost_targets": [],
      "target": "E2E Legal Activated Destroy Target",
      "target_sacrificed": false
    },
    {
      "card_name": "Soul Snare",
      "destination": "exile",
      "discarded_count": 0,
      "sacrificed_source": true,
      "sacrificed_targets": [],
      "scenario": "Soul Snare activates destroy ability",
      "source_tapped": false,
      "tapped_cost_targets": [],
      "target": "E2E Legal Activated Destroy Target",
      "target_sacrificed": false
    },
    {
      "card_name": "Undead Slayer",
      "destination": "exile",
      "discarded_count": 0,
      "sacrificed_source": false,
      "sacrificed_targets": [],
      "scenario": "Undead Slayer activates destroy ability",
      "source_tapped": true,
      "tapped_cost_targets": [],
      "target": "E2E Legal Activated Destroy Target",
      "target_sacrificed": false
    }
  ],
  "scenario_count": 9
}
```
