# Battle Package End-to-End Validation

- Generated UTC: `2026-07-12T03:19:33.453513+00:00`
- Package ID: `pg803_attachment_graveyard_shared_type_new_server_package_manifest`
- Status: `pass`
- Database target: `127.0.0.1:15432/halder`
- SQLite DB: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db`
- Snapshot: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/manaloom-knowledge/scripts/known_cards_canonical_snapshot.json`

## Stage Results

| Stage | Status | Evidence |
| --- | --- | --- |
| postgres_source_of_truth | `pass` | `{"validated_rows": 5}` |
| sqlite_hermes_cache | `pass` | `{"validated_rows": 5}` |
| canonical_snapshot_fallback | `pass` | `{"validated_cards": 5}` |
| runtime_get_card_effect | `pass` | `{"validated_cards": 5}` |
| battle_execution | `pass` | `{"events": 7, "scenarios": 5}` |

## Battle Execution

```json
{
  "event_count": 7,
  "results": [
    {
      "attached_event": {
        "power_boost": 4,
        "target_player": "Aura Controller",
        "toughness_boost": 4
      },
      "card_name": "Alpha Status",
      "moved_to_graveyard": false,
      "scenario": "Alpha Status aura static P/T attaches",
      "target": "E2E Aura Target for Alpha Status",
      "target_owner": "controller",
      "target_power": 6,
      "target_toughness": 6
    },
    {
      "attached_event": {
        "power_boost": -3,
        "target_player": "Aura Target Opponent",
        "toughness_boost": -3
      },
      "card_name": "Death's Approach",
      "moved_to_graveyard": true,
      "scenario": "Death's Approach aura static P/T attaches",
      "target": "E2E Aura Target for Death's Approach",
      "target_owner": "opponent",
      "target_power": -1,
      "target_toughness": -1
    },
    {
      "attached_event": {
        "power_boost": 3,
        "target_player": "Aura Controller",
        "toughness_boost": 3
      },
      "card_name": "Exoskeletal Armor",
      "moved_to_graveyard": false,
      "scenario": "Exoskeletal Armor aura static P/T attaches",
      "target": "E2E Aura Target for Exoskeletal Armor",
      "target_owner": "controller",
      "target_power": 5,
      "target_toughness": 5
    },
    {
      "attached_event": {
        "grants": [],
        "power_boost": 1,
        "toughness_boost": 1
      },
      "card_name": "Stoneforge Masterwork",
      "scenario": "Stoneforge Masterwork equipment static P/T attaches",
      "target": "E2E Equipment Target for Stoneforge Masterwork",
      "target_power": 3,
      "target_toughness": 3,
      "validated_keywords": []
    },
    {
      "attached_event": {
        "power_boost": 3,
        "target_player": "Aura Controller",
        "toughness_boost": 3
      },
      "card_name": "Wreath of Geists",
      "moved_to_graveyard": false,
      "scenario": "Wreath of Geists aura static P/T attaches",
      "target": "E2E Aura Target for Wreath of Geists",
      "target_owner": "controller",
      "target_power": 5,
      "target_toughness": 5
    }
  ],
  "scenario_count": 5
}
```
