# Battle Package End-to-End Validation

- Generated UTC: `2026-07-10T15:51:40.794371+00:00`
- Package ID: `pg708_dies_each_player_sacrifice_new_server_package_manifest`
- Status: `pass`
- Database target: `127.0.0.1:15432/halder`
- SQLite DB: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db`
- Snapshot: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/manaloom-knowledge/scripts/known_cards_canonical_snapshot.json`

## Stage Results

| Stage | Status | Evidence |
| --- | --- | --- |
| postgres_source_of_truth | `pass` | `{"validated_rows": 3}` |
| sqlite_hermes_cache | `pass` | `{"validated_rows": 3}` |
| canonical_snapshot_fallback | `pass` | `{"validated_cards": 3}` |
| runtime_get_card_effect | `pass` | `{"validated_cards": 3}` |
| battle_execution | `pass` | `{"events": 12, "scenarios": 3}` |

## Battle Execution

```json
{
  "event_count": 12,
  "results": [
    {
      "card_name": "Abyssal Gatekeeper",
      "sacrifice_card_types": [
        "creature"
      ],
      "sacrifice_count": 1,
      "sacrifice_requires_multicolored": false,
      "sacrificed": 2,
      "scenario": "Abyssal Gatekeeper each player sacrifices matching permanents",
      "source_died": true
    },
    {
      "card_name": "Akki Blizzard-Herder",
      "sacrifice_card_types": [
        "land"
      ],
      "sacrifice_count": 1,
      "sacrifice_requires_multicolored": false,
      "sacrificed": 2,
      "scenario": "Akki Blizzard-Herder each player sacrifices matching permanents",
      "source_died": true
    },
    {
      "card_name": "Hurloon Shaman",
      "sacrifice_card_types": [
        "land"
      ],
      "sacrifice_count": 1,
      "sacrifice_requires_multicolored": false,
      "sacrificed": 2,
      "scenario": "Hurloon Shaman each player sacrifices matching permanents",
      "source_died": true
    }
  ],
  "scenario_count": 3
}
```
