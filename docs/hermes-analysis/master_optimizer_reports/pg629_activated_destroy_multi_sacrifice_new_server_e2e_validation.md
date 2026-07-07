# Battle Package End-to-End Validation

- Generated UTC: `2026-07-07T18:11:33.277404+00:00`
- Package ID: `pg629_activated_destroy_multi_sacrifice_new_server_package_manifest`
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
| battle_execution | `pass` | `{"events": 12, "scenarios": 4}` |

## Battle Execution

```json
{
  "event_count": 12,
  "results": [
    {
      "card_name": "Earthblighter",
      "destination": "graveyard",
      "discarded_count": 0,
      "sacrificed_source": false,
      "sacrificed_targets": [
        "E2E Activated Destroy Sacrifice Target"
      ],
      "scenario": "Earthblighter activates destroy ability",
      "source_tapped": true,
      "target": "E2E Legal Activated Destroy Target",
      "target_sacrificed": true
    },
    {
      "card_name": "Keldon Arsonist",
      "destination": "graveyard",
      "discarded_count": 0,
      "sacrificed_source": false,
      "sacrificed_targets": [
        "E2E Activated Destroy Sacrifice Target 1",
        "E2E Activated Destroy Sacrifice Target 2"
      ],
      "scenario": "Keldon Arsonist activates destroy ability",
      "source_tapped": false,
      "target": "E2E Legal Activated Destroy Target",
      "target_sacrificed": true
    },
    {
      "card_name": "Krark-Clan Engineers",
      "destination": "graveyard",
      "discarded_count": 0,
      "sacrificed_source": false,
      "sacrificed_targets": [
        "E2E Activated Destroy Sacrifice Target 1",
        "E2E Activated Destroy Sacrifice Target 2"
      ],
      "scenario": "Krark-Clan Engineers activates destroy ability",
      "source_tapped": false,
      "target": "E2E Legal Activated Destroy Target",
      "target_sacrificed": true
    },
    {
      "card_name": "Sandstone Deadfall",
      "destination": "graveyard",
      "discarded_count": 0,
      "sacrificed_source": true,
      "sacrificed_targets": [
        "E2E Activated Destroy Sacrifice Target 1",
        "E2E Activated Destroy Sacrifice Target 2"
      ],
      "scenario": "Sandstone Deadfall activates destroy ability",
      "source_tapped": true,
      "target": "E2E Legal Activated Destroy Target",
      "target_sacrificed": true
    }
  ],
  "scenario_count": 4
}
```
