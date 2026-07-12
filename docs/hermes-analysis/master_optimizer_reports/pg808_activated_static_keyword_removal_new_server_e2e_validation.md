# Battle Package End-to-End Validation

- Generated UTC: `2026-07-12T05:38:30.721848+00:00`
- Package ID: `pg808_activated_static_keyword_removal_new_server_manifest`
- Status: `pass`
- Database target: `127.0.0.1:15432/halder`
- SQLite DB: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db`
- Snapshot: `docs/hermes-analysis/master_optimizer_reports/pg808_activated_static_keyword_removal_new_server_canonical_fallback.json`

## Stage Results

| Stage | Status | Evidence |
| --- | --- | --- |
| postgres_source_of_truth | `pass` | `{"validated_rows": 11}` |
| sqlite_hermes_cache | `pass` | `{"validated_rows": 11}` |
| canonical_snapshot_fallback | `pass` | `{"validated_cards": 11}` |
| runtime_get_card_effect | `pass` | `{"validated_cards": 11}` |
| battle_execution | `pass` | `{"events": 33, "scenarios": 11}` |

## Battle Execution

```json
{
  "event_count": 33,
  "results": [
    {
      "card_name": "Cathar Commando",
      "destination": "graveyard",
      "discarded_count": 0,
      "sacrificed_source": true,
      "sacrificed_targets": [],
      "scenario": "Cathar Commando activates destroy ability",
      "source_tapped": false,
      "tapped_cost_targets": [],
      "target": "E2E Legal Activated Destroy Target",
      "target_sacrificed": false
    },
    {
      "card_name": "Daraja Griffin",
      "destination": "graveyard",
      "discarded_count": 0,
      "sacrificed_source": true,
      "sacrificed_targets": [],
      "scenario": "Daraja Griffin activates destroy ability",
      "source_tapped": false,
      "tapped_cost_targets": [],
      "target": "E2E Legal Activated Destroy Target",
      "target_sacrificed": false
    },
    {
      "card_name": "Goblin Firebomb",
      "destination": "graveyard",
      "discarded_count": 0,
      "sacrificed_source": true,
      "sacrificed_targets": [],
      "scenario": "Goblin Firebomb activates destroy ability",
      "source_tapped": true,
      "tapped_cost_targets": [],
      "target": "E2E Legal Activated Destroy Target",
      "target_sacrificed": false
    },
    {
      "card_name": "Pit Trap",
      "destination": "graveyard",
      "discarded_count": 0,
      "sacrificed_source": true,
      "sacrificed_targets": [],
      "scenario": "Pit Trap activates destroy ability",
      "source_tapped": true,
      "tapped_cost_targets": [],
      "target": "E2E Legal Activated Destroy Target",
      "target_sacrificed": false
    },
    {
      "card_name": "Shattered Acolyte",
      "destination": "graveyard",
      "discarded_count": 0,
      "sacrificed_source": true,
      "sacrificed_targets": [],
      "scenario": "Shattered Acolyte activates destroy ability",
      "source_tapped": false,
      "tapped_cost_targets": [],
      "target": "E2E Legal Activated Destroy Target",
      "target_sacrificed": false
    },
    {
      "card_name": "Tolarian Sentinel",
      "destination": "hand",
      "discarded_count": 1,
      "sacrificed_source": false,
      "sacrificed_targets": [],
      "scenario": "Tolarian Sentinel activates return-to-hand ability",
      "source_tapped": true,
      "tapped_cost_targets": [],
      "target": "E2E Legal Activated Bounce Target",
      "target_controller": "Activated Controller",
      "target_in_hand": true,
      "target_sacrificed": false
    },
    {
      "card_name": "Tradewind Rider",
      "destination": "hand",
      "discarded_count": 0,
      "sacrificed_source": false,
      "sacrificed_targets": [],
      "scenario": "Tradewind Rider activates return-to-hand ability",
      "source_tapped": true,
      "tapped_cost_targets": [
        "E2E Activated Bounce Tap Cost Target 1",
        "E2E Activated Bounce Tap Cost Target 2"
      ],
      "target": "E2E Legal Activated Bounce Target",
      "target_controller": "Activated Opponent",
      "target_in_hand": true,
      "target_sacrificed": false
    },
    {
      "card_name": "Uktabi Faerie",
      "destination": "graveyard",
      "discarded_count": 0,
      "sacrificed_source": true,
      "sacrificed_targets": [],
      "scenario": "Uktabi Faerie activates destroy ability",
      "source_tapped": false,
      "tapped_cost_targets": [],
      "target": "E2E Legal Activated Destroy Target",
      "target_sacrificed": false
    },
    {
      "card_name": "Undergrowth Leopard",
      "destination": "graveyard",
      "discarded_count": 0,
      "sacrificed_source": true,
      "sacrificed_targets": [],
      "scenario": "Undergrowth Leopard activates destroy ability",
      "source_tapped": false,
      "tapped_cost_targets": [],
      "target": "E2E Legal Activated Destroy Target",
      "target_sacrificed": false
    },
    {
      "card_name": "Visara the Dreadful",
      "destination": "graveyard",
      "discarded_count": 0,
      "sacrificed_source": false,
      "sacrificed_targets": [],
      "scenario": "Visara the Dreadful activates destroy ability",
      "source_tapped": true,
      "tapped_cost_targets": [],
      "target": "E2E Legal Activated Destroy Target",
      "target_sacrificed": false
    },
    {
      "card_name": "Voracious Varmint",
      "destination": "graveyard",
      "discarded_count": 0,
      "sacrificed_source": true,
      "sacrificed_targets": [],
      "scenario": "Voracious Varmint activates destroy ability",
      "source_tapped": false,
      "tapped_cost_targets": [],
      "target": "E2E Legal Activated Destroy Target",
      "target_sacrificed": false
    }
  ],
  "scenario_count": 11
}
```
