# Battle Package End-to-End Validation

- Generated UTC: `2026-07-05T21:34:57.496634+00:00`
- Package ID: `pg531_static_global_pt_new_server_package_manifest`
- Status: `pass`
- Database target: `143.198.230.247:5433/halder`
- SQLite DB: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db`
- Snapshot: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/manaloom-knowledge/scripts/known_cards_canonical_snapshot.json`

## Stage Results

| Stage | Status | Evidence |
| --- | --- | --- |
| postgres_source_of_truth | `pass` | `{"validated_rows": 18}` |
| sqlite_hermes_cache | `pass` | `{"validated_rows": 18}` |
| canonical_snapshot_fallback | `pass` | `{"validated_cards": 18}` |
| runtime_get_card_effect | `pass` | `{"validated_cards": 18}` |
| battle_execution | `pass` | `{"events": 19, "scenarios": 18}` |

## Battle Execution

```json
{
  "event_count": 19,
  "results": [
    {
      "card_name": "Anaba Spirit Crafter",
      "moved_to_graveyard": false,
      "refreshed_count": 1,
      "scenario": "Anaba Spirit Crafter static global P/T applies",
      "source_cards": [
        "Anaba Spirit Crafter"
      ],
      "target": "E2E Target for Anaba Spirit Crafter",
      "target_power": 3,
      "target_toughness": 2
    },
    {
      "card_name": "Bad Moon",
      "moved_to_graveyard": false,
      "refreshed_count": 1,
      "scenario": "Bad Moon static global P/T applies",
      "source_cards": [
        "Bad Moon"
      ],
      "target": "E2E Target for Bad Moon",
      "target_power": 3,
      "target_toughness": 3
    },
    {
      "card_name": "Blade Sliver",
      "moved_to_graveyard": false,
      "refreshed_count": 1,
      "scenario": "Blade Sliver static global P/T applies",
      "source_cards": [
        "Blade Sliver"
      ],
      "target": "E2E Target for Blade Sliver",
      "target_power": 3,
      "target_toughness": 2
    },
    {
      "card_name": "Bonesplitter Sliver",
      "moved_to_graveyard": false,
      "refreshed_count": 1,
      "scenario": "Bonesplitter Sliver static global P/T applies",
      "source_cards": [
        "Bonesplitter Sliver"
      ],
      "target": "E2E Target for Bonesplitter Sliver",
      "target_power": 4,
      "target_toughness": 2
    },
    {
      "card_name": "Dampening Pulse",
      "moved_to_graveyard": false,
      "refreshed_count": 1,
      "scenario": "Dampening Pulse static global P/T applies",
      "source_cards": [
        "Dampening Pulse"
      ],
      "target": "E2E Target for Dampening Pulse",
      "target_power": 1,
      "target_toughness": 2
    },
    {
      "card_name": "Dread of Night",
      "moved_to_graveyard": false,
      "refreshed_count": 1,
      "scenario": "Dread of Night static global P/T applies",
      "source_cards": [
        "Dread of Night"
      ],
      "target": "E2E Target for Dread of Night",
      "target_power": 1,
      "target_toughness": 1
    },
    {
      "card_name": "Earth Surge",
      "moved_to_graveyard": false,
      "refreshed_count": 1,
      "scenario": "Earth Surge static global P/T applies",
      "source_cards": [
        "Earth Surge"
      ],
      "target": "E2E Target for Earth Surge",
      "target_power": 4,
      "target_toughness": 4
    },
    {
      "card_name": "Illness in the Ranks",
      "moved_to_graveyard": false,
      "refreshed_count": 1,
      "scenario": "Illness in the Ranks static global P/T applies",
      "source_cards": [
        "Illness in the Ranks"
      ],
      "target": "E2E Target for Illness in the Ranks",
      "target_power": 1,
      "target_toughness": 1
    },
    {
      "card_name": "Kaervek, the Spiteful",
      "moved_to_graveyard": false,
      "refreshed_count": 1,
      "scenario": "Kaervek, the Spiteful static global P/T applies",
      "source_cards": [
        "Kaervek, the Spiteful"
      ],
      "target": "E2E Target for Kaervek, the Spiteful",
      "target_power": 1,
      "target_toughness": 1
    },
    {
      "card_name": "Might Sliver",
      "moved_to_graveyard": false,
      "refreshed_count": 1,
      "scenario": "Might Sliver static global P/T applies",
      "source_cards": [
        "Might Sliver"
      ],
      "target": "E2E Target for Might Sliver",
      "target_power": 4,
      "target_toughness": 4
    },
    {
      "card_name": "Muscle Sliver",
      "moved_to_graveyard": false,
      "refreshed_count": 1,
      "scenario": "Muscle Sliver static global P/T applies",
      "source_cards": [
        "Muscle Sliver"
      ],
      "target": "E2E Target for Muscle Sliver",
      "target_power": 3,
      "target_toughness": 3
    },
    {
      "card_name": "Night of Souls' Betrayal",
      "moved_to_graveyard": false,
      "refreshed_count": 1,
      "scenario": "Night of Souls' Betrayal static global P/T applies",
      "source_cards": [
        "Night of Souls' Betrayal"
      ],
      "target": "E2E Target for Night of Souls' Betrayal",
      "target_power": 1,
      "target_toughness": 1
    },
    {
      "card_name": "Plated Sliver",
      "moved_to_graveyard": false,
      "refreshed_count": 1,
      "scenario": "Plated Sliver static global P/T applies",
      "source_cards": [
        "Plated Sliver"
      ],
      "target": "E2E Target for Plated Sliver",
      "target_power": 2,
      "target_toughness": 3
    },
    {
      "card_name": "Sinew Sliver",
      "moved_to_graveyard": false,
      "refreshed_count": 1,
      "scenario": "Sinew Sliver static global P/T applies",
      "source_cards": [
        "Sinew Sliver"
      ],
      "target": "E2E Target for Sinew Sliver",
      "target_power": 3,
      "target_toughness": 3
    },
    {
      "card_name": "Stronghold Taskmaster",
      "moved_to_graveyard": false,
      "refreshed_count": 1,
      "scenario": "Stronghold Taskmaster static global P/T applies",
      "source_cards": [
        "Stronghold Taskmaster"
      ],
      "target": "E2E Target for Stronghold Taskmaster",
      "target_power": 1,
      "target_toughness": 1
    },
    {
      "card_name": "Urborg Shambler",
      "moved_to_graveyard": false,
      "refreshed_count": 1,
      "scenario": "Urborg Shambler static global P/T applies",
      "source_cards": [
        "Urborg Shambler"
      ],
      "target": "E2E Target for Urborg Shambler",
      "target_power": 1,
      "target_toughness": 1
    },
    {
      "card_name": "Virulent Plague",
      "moved_to_graveyard": true,
      "refreshed_count": 1,
      "scenario": "Virulent Plague static global P/T applies",
      "source_cards": [
        "Virulent Plague"
      ],
      "target": "E2E Target for Virulent Plague",
      "target_power": 0,
      "target_toughness": 0
    },
    {
      "card_name": "Watcher Sliver",
      "moved_to_graveyard": false,
      "refreshed_count": 1,
      "scenario": "Watcher Sliver static global P/T applies",
      "source_cards": [
        "Watcher Sliver"
      ],
      "target": "E2E Target for Watcher Sliver",
      "target_power": 2,
      "target_toughness": 4
    }
  ],
  "scenario_count": 18
}
```
