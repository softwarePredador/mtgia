# Battle Package End-to-End Validation

- Generated UTC: `2026-07-06T23:54:21.184283+00:00`
- Package ID: `pg581_each_player_sacrifice_new_server_package_manifest`
- Status: `pass`
- Database target: `127.0.0.1:15432/halder`
- SQLite DB: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db`
- Snapshot: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/manaloom-knowledge/scripts/known_cards_canonical_snapshot.json`

## Stage Results

| Stage | Status | Evidence |
| --- | --- | --- |
| postgres_source_of_truth | `pass` | `{"validated_rows": 7}` |
| sqlite_hermes_cache | `pass` | `{"validated_rows": 7}` |
| canonical_snapshot_fallback | `pass` | `{"validated_cards": 7}` |
| runtime_get_card_effect | `pass` | `{"validated_cards": 7}` |
| battle_execution | `pass` | `{"events": 32, "scenarios": 7}` |

## Battle Execution

```json
{
  "event_count": 32,
  "results": [
    {
      "card_name": "Barter in Blood",
      "sacrifice_card_types": [
        "creature"
      ],
      "sacrifice_count": 2,
      "sacrifice_requires_multicolored": false,
      "sacrificed": 4,
      "scenario": "Barter in Blood each player sacrifices matching permanents"
    },
    {
      "card_name": "Crack the Earth",
      "sacrifice_card_types": [
        "permanent"
      ],
      "sacrifice_count": 1,
      "sacrifice_requires_multicolored": false,
      "sacrificed": 2,
      "scenario": "Crack the Earth each player sacrifices matching permanents"
    },
    {
      "card_name": "Innocent Blood",
      "sacrifice_card_types": [
        "creature"
      ],
      "sacrifice_count": 1,
      "sacrifice_requires_multicolored": false,
      "sacrificed": 2,
      "scenario": "Innocent Blood each player sacrifices matching permanents"
    },
    {
      "card_name": "Renounce the Guilds",
      "sacrifice_card_types": [
        "permanent"
      ],
      "sacrifice_count": 1,
      "sacrifice_requires_multicolored": true,
      "sacrificed": 2,
      "scenario": "Renounce the Guilds each player sacrifices matching permanents"
    },
    {
      "card_name": "Simplify",
      "sacrifice_card_types": [
        "enchantment"
      ],
      "sacrifice_count": 1,
      "sacrifice_requires_multicolored": false,
      "sacrificed": 2,
      "scenario": "Simplify each player sacrifices matching permanents"
    },
    {
      "card_name": "Tergrid's Shadow",
      "sacrifice_card_types": [
        "creature"
      ],
      "sacrifice_count": 2,
      "sacrifice_requires_multicolored": false,
      "sacrificed": 4,
      "scenario": "Tergrid's Shadow each player sacrifices matching permanents"
    },
    {
      "card_name": "Tremble",
      "sacrifice_card_types": [
        "land"
      ],
      "sacrifice_count": 1,
      "sacrifice_requires_multicolored": false,
      "sacrificed": 2,
      "scenario": "Tremble each player sacrifices matching permanents"
    }
  ],
  "scenario_count": 7
}
```
