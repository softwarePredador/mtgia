# Battle Package End-to-End Validation

- Generated UTC: `2026-07-06T06:15:12.450194+00:00`
- Package ID: `pg554_self_keyword_extra_costs_new_server_package_manifest`
- Status: `pass`
- Database target: `143.198.230.247:5433/halder`
- SQLite DB: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db`
- Snapshot: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/manaloom-knowledge/scripts/known_cards_canonical_snapshot.json`

## Stage Results

| Stage | Status | Evidence |
| --- | --- | --- |
| postgres_source_of_truth | `pass` | `{"validated_rows": 5}` |
| sqlite_hermes_cache | `pass` | `{"validated_rows": 5}` |
| canonical_snapshot_fallback | `pass` | `{"validated_cards": 5}` |
| runtime_get_card_effect | `pass` | `{"validated_cards": 5}` |
| battle_execution | `pass` | `{"events": 10, "scenarios": 5}` |

## Battle Execution

```json
{
  "event_count": 10,
  "results": [
    {
      "card_name": "Fledgling Imp",
      "discarded_count": 1,
      "granted_keywords": [
        "flying"
      ],
      "life_paid": 0,
      "scenario": "Fledgling Imp activates self keyword ability",
      "source_keywords": [
        "flying"
      ],
      "source_tapped": false
    },
    {
      "card_name": "Insatiable Souleater",
      "discarded_count": 0,
      "granted_keywords": [
        "trample"
      ],
      "life_paid": 0,
      "scenario": "Insatiable Souleater activates self keyword ability",
      "source_keywords": [
        "trample"
      ],
      "source_tapped": false
    },
    {
      "card_name": "Olivia's Dragoon",
      "discarded_count": 1,
      "granted_keywords": [
        "flying"
      ],
      "life_paid": 0,
      "scenario": "Olivia's Dragoon activates self keyword ability",
      "source_keywords": [
        "flying"
      ],
      "source_tapped": false
    },
    {
      "card_name": "Patrol Hound",
      "discarded_count": 1,
      "granted_keywords": [
        "first_strike"
      ],
      "life_paid": 0,
      "scenario": "Patrol Hound activates self keyword ability",
      "source_keywords": [
        "first_strike"
      ],
      "source_tapped": false
    },
    {
      "card_name": "Shadowcloak Vampire",
      "discarded_count": 0,
      "granted_keywords": [
        "flying"
      ],
      "life_paid": 2,
      "scenario": "Shadowcloak Vampire activates self keyword ability",
      "source_keywords": [
        "flying"
      ],
      "source_tapped": false
    }
  ],
  "scenario_count": 5
}
```
