# Battle Package End-to-End Validation

- Generated UTC: `2026-07-07T02:20:46.287030+00:00`
- Package ID: `pg586_static_controlled_trample_new_server_package_manifest`
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
      "card_name": "Aggressive Mammoth",
      "keyword": "trample",
      "matching_target": "E2E Controlled Keyword Target for Aggressive Mammoth",
      "refreshed_count": 1,
      "scenario": "Aggressive Mammoth static controlled keyword applies",
      "source_cards": [
        "Aggressive Mammoth"
      ]
    },
    {
      "card_name": "Bloodcrusher of Khorne",
      "keyword": "trample",
      "matching_target": "E2E Controlled Keyword Target for Bloodcrusher of Khorne",
      "refreshed_count": 1,
      "scenario": "Bloodcrusher of Khorne static controlled keyword applies",
      "source_cards": [
        "Bloodcrusher of Khorne"
      ]
    },
    {
      "card_name": "Groundshaker Sliver",
      "keyword": "trample",
      "matching_target": "E2E Controlled Keyword Target for Groundshaker Sliver",
      "refreshed_count": 1,
      "scenario": "Groundshaker Sliver static controlled keyword applies",
      "source_cards": [
        "Groundshaker Sliver"
      ]
    },
    {
      "card_name": "Khenra Charioteer",
      "keyword": "trample",
      "matching_target": "E2E Controlled Keyword Target for Khenra Charioteer",
      "refreshed_count": 1,
      "scenario": "Khenra Charioteer static controlled keyword applies",
      "source_cards": [
        "Khenra Charioteer"
      ]
    },
    {
      "card_name": "Nylea's Forerunner",
      "keyword": "trample",
      "matching_target": "E2E Controlled Keyword Target for Nylea's Forerunner",
      "refreshed_count": 1,
      "scenario": "Nylea's Forerunner static controlled keyword applies",
      "source_cards": [
        "Nylea's Forerunner"
      ]
    },
    {
      "card_name": "Primal Rage",
      "keyword": "trample",
      "matching_target": "E2E Controlled Keyword Target for Primal Rage",
      "refreshed_count": 1,
      "scenario": "Primal Rage static controlled keyword applies",
      "source_cards": [
        "Primal Rage"
      ]
    },
    {
      "card_name": "Roughshod Mentor",
      "keyword": "trample",
      "matching_target": "E2E Controlled Keyword Target for Roughshod Mentor",
      "refreshed_count": 1,
      "scenario": "Roughshod Mentor static controlled keyword applies",
      "source_cards": [
        "Roughshod Mentor"
      ]
    },
    {
      "card_name": "Thicket Crasher",
      "keyword": "trample",
      "matching_target": "E2E Controlled Keyword Target for Thicket Crasher",
      "refreshed_count": 1,
      "scenario": "Thicket Crasher static controlled keyword applies",
      "source_cards": [
        "Thicket Crasher"
      ]
    }
  ],
  "scenario_count": 8
}
```
