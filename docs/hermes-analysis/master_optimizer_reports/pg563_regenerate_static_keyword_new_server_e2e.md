# Battle Package End-to-End Validation

- Generated UTC: `2026-07-06T11:26:02.841568+00:00`
- Package ID: `pg563_regenerate_static_keyword_new_server_package_manifest`
- Status: `pass`
- Database target: `143.198.230.247:5433/halder`
- SQLite DB: `docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db`
- Snapshot: `docs/hermes-analysis/manaloom-knowledge/scripts/known_cards_canonical_snapshot.json`

## Stage Results

| Stage | Status | Evidence |
| --- | --- | --- |
| postgres_source_of_truth | `pass` | `{"validated_rows": 22}` |
| sqlite_hermes_cache | `pass` | `{"validated_rows": 22}` |
| canonical_snapshot_fallback | `pass` | `{"validated_cards": 22}` |
| runtime_get_card_effect | `pass` | `{"validated_cards": 22}` |
| battle_execution | `pass` | `{"events": 44, "scenarios": 22}` |

## Battle Execution

```json
{
  "event_count": 44,
  "results": [
    {
      "card_name": "Carnassid",
      "destination": "battlefield",
      "regeneration_shields_after": 0,
      "scenario": "Carnassid activates regenerate source ability",
      "source_tapped": true
    },
    {
      "card_name": "Carrion Wall",
      "destination": "battlefield",
      "regeneration_shields_after": 0,
      "scenario": "Carrion Wall activates regenerate source ability",
      "source_tapped": true
    },
    {
      "card_name": "Charging Troll",
      "destination": "battlefield",
      "regeneration_shields_after": 0,
      "scenario": "Charging Troll activates regenerate source ability",
      "source_tapped": true
    },
    {
      "card_name": "Drudge Reavers",
      "destination": "battlefield",
      "regeneration_shields_after": 0,
      "scenario": "Drudge Reavers activates regenerate source ability",
      "source_tapped": true
    },
    {
      "card_name": "Fog of Gnats",
      "destination": "battlefield",
      "regeneration_shields_after": 0,
      "scenario": "Fog of Gnats activates regenerate source ability",
      "source_tapped": true
    },
    {
      "card_name": "Ghost Ship",
      "destination": "battlefield",
      "regeneration_shields_after": 0,
      "scenario": "Ghost Ship activates regenerate source ability",
      "source_tapped": true
    },
    {
      "card_name": "Lim-D\u00fbl's High Guard",
      "destination": "battlefield",
      "regeneration_shields_after": 0,
      "scenario": "Lim-D\u00fbl's High Guard activates regenerate source ability",
      "source_tapped": true
    },
    {
      "card_name": "Living Airship",
      "destination": "battlefield",
      "regeneration_shields_after": 0,
      "scenario": "Living Airship activates regenerate source ability",
      "source_tapped": true
    },
    {
      "card_name": "Living Wall",
      "destination": "battlefield",
      "regeneration_shields_after": 0,
      "scenario": "Living Wall activates regenerate source ability",
      "source_tapped": true
    },
    {
      "card_name": "Malach of the Dawn",
      "destination": "battlefield",
      "regeneration_shields_after": 0,
      "scenario": "Malach of the Dawn activates regenerate source ability",
      "source_tapped": true
    },
    {
      "card_name": "Manor Skeleton",
      "destination": "battlefield",
      "regeneration_shields_after": 0,
      "scenario": "Manor Skeleton activates regenerate source ability",
      "source_tapped": true
    },
    {
      "card_name": "Ranger en-Vec",
      "destination": "battlefield",
      "regeneration_shields_after": 0,
      "scenario": "Ranger en-Vec activates regenerate source ability",
      "source_tapped": true
    },
    {
      "card_name": "Sanguine Guard",
      "destination": "battlefield",
      "regeneration_shields_after": 0,
      "scenario": "Sanguine Guard activates regenerate source ability",
      "source_tapped": true
    },
    {
      "card_name": "Screeching Harpy",
      "destination": "battlefield",
      "regeneration_shields_after": 0,
      "scenario": "Screeching Harpy activates regenerate source ability",
      "source_tapped": true
    },
    {
      "card_name": "Tattered Drake",
      "destination": "battlefield",
      "regeneration_shields_after": 0,
      "scenario": "Tattered Drake activates regenerate source ability",
      "source_tapped": true
    },
    {
      "card_name": "Trestle Troll",
      "destination": "battlefield",
      "regeneration_shields_after": 0,
      "scenario": "Trestle Troll activates regenerate source ability",
      "source_tapped": true
    },
    {
      "card_name": "Wall of Bone",
      "destination": "battlefield",
      "regeneration_shields_after": 0,
      "scenario": "Wall of Bone activates regenerate source ability",
      "source_tapped": true
    },
    {
      "card_name": "Wall of Brambles",
      "destination": "battlefield",
      "regeneration_shields_after": 0,
      "scenario": "Wall of Brambles activates regenerate source ability",
      "source_tapped": true
    },
    {
      "card_name": "Wall of Pine Needles",
      "destination": "battlefield",
      "regeneration_shields_after": 0,
      "scenario": "Wall of Pine Needles activates regenerate source ability",
      "source_tapped": true
    },
    {
      "card_name": "Will-o'-the-Wisp",
      "destination": "battlefield",
      "regeneration_shields_after": 0,
      "scenario": "Will-o'-the-Wisp activates regenerate source ability",
      "source_tapped": true
    },
    {
      "card_name": "Wolfir Avenger",
      "destination": "battlefield",
      "regeneration_shields_after": 0,
      "scenario": "Wolfir Avenger activates regenerate source ability",
      "source_tapped": true
    },
    {
      "card_name": "Yavimaya Gnats",
      "destination": "battlefield",
      "regeneration_shields_after": 0,
      "scenario": "Yavimaya Gnats activates regenerate source ability",
      "source_tapped": true
    }
  ],
  "scenario_count": 22
}
```
