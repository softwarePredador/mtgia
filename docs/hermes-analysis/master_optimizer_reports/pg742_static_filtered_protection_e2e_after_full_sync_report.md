# Battle Package End-to-End Validation

- Generated UTC: `2026-07-11T05:31:27.546621+00:00`
- Package ID: `pg742_static_filtered_protection_package_manifest`
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
| battle_execution | `pass` | `{"events": 0, "scenarios": 4}` |

## Battle Execution

```json
{
  "event_count": 0,
  "results": [
    {
      "card_name": "Enemy of the Guildpact",
      "matching_source": "E2E Matching Protection Source",
      "nonmatching_source": "E2E Nonmatching Protection Source",
      "protection_filter": "multicolored",
      "protection_from_subtypes": null,
      "scenario": "Enemy of the Guildpact static filtered protection blocks matching source",
      "static_effect": "self_protection_from_filtered"
    },
    {
      "card_name": "Guardian of the Guildpact",
      "matching_source": "E2E Matching Protection Source",
      "nonmatching_source": "E2E Nonmatching Protection Source",
      "protection_filter": "monocolored",
      "protection_from_subtypes": null,
      "scenario": "Guardian of the Guildpact static filtered protection blocks matching source",
      "static_effect": "self_protection_from_filtered"
    },
    {
      "card_name": "Mistmeadow Skulk",
      "matching_source": "E2E Matching Protection Source",
      "nonmatching_source": "E2E Nonmatching Protection Source",
      "protection_filter": "mana_value_gte",
      "protection_from_subtypes": null,
      "scenario": "Mistmeadow Skulk static filtered protection blocks matching source",
      "static_effect": "self_protection_from_filtered"
    },
    {
      "card_name": "Warren-Scourge Elf",
      "matching_source": "E2E Matching Protection Source",
      "nonmatching_source": "E2E Nonmatching Protection Source",
      "protection_filter": null,
      "protection_from_subtypes": [
        "goblin"
      ],
      "scenario": "Warren-Scourge Elf static subtype protection blocks matching source",
      "static_effect": "self_protection_from_subtypes"
    }
  ],
  "scenario_count": 4
}
```
