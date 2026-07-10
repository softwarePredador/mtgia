# Battle Package End-to-End Validation

- Generated UTC: `2026-07-10T21:33:01.477270+00:00`
- Package ID: `pg722_regenerate_costs_new_server_package_manifest`
- Status: `pass`
- Database target: `127.0.0.1:15432/halder`
- SQLite DB: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db`
- Snapshot: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/manaloom-knowledge/scripts/known_cards_canonical_snapshot.json`

## Stage Results

| Stage | Status | Evidence |
| --- | --- | --- |
| postgres_source_of_truth | `pass` | `{"validated_rows": 6}` |
| sqlite_hermes_cache | `pass` | `{"validated_rows": 6}` |
| canonical_snapshot_fallback | `pass` | `{"validated_cards": 6}` |
| runtime_get_card_effect | `pass` | `{"validated_cards": 6}` |
| battle_execution | `pass` | `{"events": 12, "scenarios": 6}` |

## Battle Execution

```json
{
  "event_count": 12,
  "results": [
    {
      "card_name": "Centaur Veteran",
      "destination": "battlefield",
      "discarded_count": 1,
      "life_paid": 0,
      "regeneration_shields_after": 0,
      "scenario": "Centaur Veteran activates regenerate source ability",
      "source_tapped": true
    },
    {
      "card_name": "Deepwood Ghoul",
      "destination": "battlefield",
      "discarded_count": 0,
      "life_paid": 2,
      "regeneration_shields_after": 0,
      "scenario": "Deepwood Ghoul activates regenerate source ability",
      "source_tapped": true
    },
    {
      "card_name": "Marrow Bats",
      "destination": "battlefield",
      "discarded_count": 0,
      "life_paid": 4,
      "regeneration_shields_after": 0,
      "scenario": "Marrow Bats activates regenerate source ability",
      "source_tapped": true
    },
    {
      "card_name": "Mischievous Poltergeist",
      "destination": "battlefield",
      "discarded_count": 0,
      "life_paid": 1,
      "regeneration_shields_after": 0,
      "scenario": "Mischievous Poltergeist activates regenerate source ability",
      "source_tapped": true
    },
    {
      "card_name": "Sentry of the Underworld",
      "destination": "battlefield",
      "discarded_count": 0,
      "life_paid": 3,
      "regeneration_shields_after": 0,
      "scenario": "Sentry of the Underworld activates regenerate source ability",
      "source_tapped": true
    },
    {
      "card_name": "Tunneler Wurm",
      "destination": "battlefield",
      "discarded_count": 1,
      "life_paid": 0,
      "regeneration_shields_after": 0,
      "scenario": "Tunneler Wurm activates regenerate source ability",
      "source_tapped": true
    }
  ],
  "scenario_count": 6
}
```
