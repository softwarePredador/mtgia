# Battle Package End-to-End Validation

- Generated UTC: `2026-07-12T23:40:45.700981+00:00`
- Package ID: `pg851_activated_target_player_mill_new_server_manifest`
- Status: `pass`
- Database target: `127.0.0.1:15432/halder`
- SQLite DB: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db`
- Snapshot: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/manaloom-knowledge/scripts/known_cards_canonical_snapshot.json`

## Stage Results

| Stage | Status | Evidence |
| --- | --- | --- |
| postgres_source_of_truth | `pass` | `{"validated_rows": 8}` |
| sqlite_hermes_cache | `pass` | `{"validated_rows": 8}` |
| canonical_snapshot_fallback | `pass` | `{"validated_cards": 8}` |
| runtime_get_card_effect | `pass` | `{"validated_cards": 8}` |
| battle_execution | `pass` | `{"events": 16, "scenarios": 8}` |

## Battle Execution

```json
{
  "event_count": 16,
  "results": [
    {
      "card_name": "Ambassador Laquatus",
      "cards_milled": 3,
      "scenario": "Ambassador Laquatus activates target-player mill ability",
      "tapped_cost_targets": [],
      "tapped_source": false
    },
    {
      "card_name": "Cathartic Adept",
      "cards_milled": 1,
      "scenario": "Cathartic Adept activates target-player mill ability",
      "tapped_cost_targets": [],
      "tapped_source": true
    },
    {
      "card_name": "Drowner of Secrets",
      "cards_milled": 1,
      "scenario": "Drowner of Secrets activates target-player mill ability",
      "tapped_cost_targets": [
        "E2E Activated Target Mill Tap Cost Target"
      ],
      "tapped_source": false
    },
    {
      "card_name": "Hair-Strung Koto",
      "cards_milled": 1,
      "scenario": "Hair-Strung Koto activates target-player mill ability",
      "tapped_cost_targets": [
        "E2E Activated Target Mill Tap Cost Target"
      ],
      "tapped_source": false
    },
    {
      "card_name": "Merfolk Mesmerist",
      "cards_milled": 2,
      "scenario": "Merfolk Mesmerist activates target-player mill ability",
      "tapped_cost_targets": [],
      "tapped_source": true
    },
    {
      "card_name": "Millstone",
      "cards_milled": 2,
      "scenario": "Millstone activates target-player mill ability",
      "tapped_cost_targets": [],
      "tapped_source": true
    },
    {
      "card_name": "Tower of Murmurs",
      "cards_milled": 8,
      "scenario": "Tower of Murmurs activates target-player mill ability",
      "tapped_cost_targets": [],
      "tapped_source": true
    },
    {
      "card_name": "Vedalken Entrancer",
      "cards_milled": 2,
      "scenario": "Vedalken Entrancer activates target-player mill ability",
      "tapped_cost_targets": [],
      "tapped_source": true
    }
  ],
  "scenario_count": 8
}
```
