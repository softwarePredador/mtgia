# Battle Package End-to-End Validation

- Generated UTC: `2026-07-06T10:53:57.530535+00:00`
- Package ID: `pg561_regenerate_source_new_server_package_manifest`
- Status: `pass`
- Database target: `143.198.230.247:5433/halder`
- SQLite DB: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db`
- Snapshot: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/manaloom-knowledge/scripts/known_cards_canonical_snapshot.json`

## Stage Results

| Stage | Status | Evidence |
| --- | --- | --- |
| postgres_source_of_truth | `pass` | `{"validated_rows": 24}` |
| sqlite_hermes_cache | `pass` | `{"validated_rows": 24}` |
| canonical_snapshot_fallback | `pass` | `{"validated_cards": 24}` |
| runtime_get_card_effect | `pass` | `{"validated_cards": 24}` |
| battle_execution | `pass` | `{"events": 48, "scenarios": 24}` |

## Battle Execution

```json
{
  "event_count": 48,
  "results": [
    {
      "card_name": "Ancient Silverback",
      "destination": "battlefield",
      "regeneration_shields_after": 0,
      "scenario": "Ancient Silverback activates regenerate source ability",
      "source_tapped": true
    },
    {
      "card_name": "Asphodel Wanderer",
      "destination": "battlefield",
      "regeneration_shields_after": 0,
      "scenario": "Asphodel Wanderer activates regenerate source ability",
      "source_tapped": true
    },
    {
      "card_name": "Clay Statue",
      "destination": "battlefield",
      "regeneration_shields_after": 0,
      "scenario": "Clay Statue activates regenerate source ability",
      "source_tapped": true
    },
    {
      "card_name": "Cudgel Troll",
      "destination": "battlefield",
      "regeneration_shields_after": 0,
      "scenario": "Cudgel Troll activates regenerate source ability",
      "source_tapped": true
    },
    {
      "card_name": "Diabolic Machine",
      "destination": "battlefield",
      "regeneration_shields_after": 0,
      "scenario": "Diabolic Machine activates regenerate source ability",
      "source_tapped": true
    },
    {
      "card_name": "Drowned",
      "destination": "battlefield",
      "regeneration_shields_after": 0,
      "scenario": "Drowned activates regenerate source ability",
      "source_tapped": true
    },
    {
      "card_name": "Drudge Skeletons",
      "destination": "battlefield",
      "regeneration_shields_after": 0,
      "scenario": "Drudge Skeletons activates regenerate source ability",
      "source_tapped": true
    },
    {
      "card_name": "Dutiful Thrull",
      "destination": "battlefield",
      "regeneration_shields_after": 0,
      "scenario": "Dutiful Thrull activates regenerate source ability",
      "source_tapped": true
    },
    {
      "card_name": "Gorilla Chieftain",
      "destination": "battlefield",
      "regeneration_shields_after": 0,
      "scenario": "Gorilla Chieftain activates regenerate source ability",
      "source_tapped": true
    },
    {
      "card_name": "Horned Troll",
      "destination": "battlefield",
      "regeneration_shields_after": 0,
      "scenario": "Horned Troll activates regenerate source ability",
      "source_tapped": true
    },
    {
      "card_name": "Metathran Zombie",
      "destination": "battlefield",
      "regeneration_shields_after": 0,
      "scenario": "Metathran Zombie activates regenerate source ability",
      "source_tapped": true
    },
    {
      "card_name": "Odious Trow",
      "destination": "battlefield",
      "regeneration_shields_after": 0,
      "scenario": "Odious Trow activates regenerate source ability",
      "source_tapped": true
    },
    {
      "card_name": "Pewter Golem",
      "destination": "battlefield",
      "regeneration_shields_after": 0,
      "scenario": "Pewter Golem activates regenerate source ability",
      "source_tapped": true
    },
    {
      "card_name": "Phyrexian Monitor",
      "destination": "battlefield",
      "regeneration_shields_after": 0,
      "scenario": "Phyrexian Monitor activates regenerate source ability",
      "source_tapped": true
    },
    {
      "card_name": "Restless Dead",
      "destination": "battlefield",
      "regeneration_shields_after": 0,
      "scenario": "Restless Dead activates regenerate source ability",
      "source_tapped": true
    },
    {
      "card_name": "Revered Dead",
      "destination": "battlefield",
      "regeneration_shields_after": 0,
      "scenario": "Revered Dead activates regenerate source ability",
      "source_tapped": true
    },
    {
      "card_name": "Selesnya Sentry",
      "destination": "battlefield",
      "regeneration_shields_after": 0,
      "scenario": "Selesnya Sentry activates regenerate source ability",
      "source_tapped": true
    },
    {
      "card_name": "Skeletal Wurm",
      "destination": "battlefield",
      "regeneration_shields_after": 0,
      "scenario": "Skeletal Wurm activates regenerate source ability",
      "source_tapped": true
    },
    {
      "card_name": "Tangle Hulk",
      "destination": "battlefield",
      "regeneration_shields_after": 0,
      "scenario": "Tangle Hulk activates regenerate source ability",
      "source_tapped": true
    },
    {
      "card_name": "Tel-Jilad Exile",
      "destination": "battlefield",
      "regeneration_shields_after": 0,
      "scenario": "Tel-Jilad Exile activates regenerate source ability",
      "source_tapped": true
    },
    {
      "card_name": "Unworthy Dead",
      "destination": "battlefield",
      "regeneration_shields_after": 0,
      "scenario": "Unworthy Dead activates regenerate source ability",
      "source_tapped": true
    },
    {
      "card_name": "Uthden Troll",
      "destination": "battlefield",
      "regeneration_shields_after": 0,
      "scenario": "Uthden Troll activates regenerate source ability",
      "source_tapped": true
    },
    {
      "card_name": "Votary of the Conclave",
      "destination": "battlefield",
      "regeneration_shields_after": 0,
      "scenario": "Votary of the Conclave activates regenerate source ability",
      "source_tapped": true
    },
    {
      "card_name": "Walking Dead",
      "destination": "battlefield",
      "regeneration_shields_after": 0,
      "scenario": "Walking Dead activates regenerate source ability",
      "source_tapped": true
    }
  ],
  "scenario_count": 24
}
```
