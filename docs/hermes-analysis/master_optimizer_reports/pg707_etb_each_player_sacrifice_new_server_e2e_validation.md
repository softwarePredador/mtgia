# Battle Package End-to-End Validation

- Generated UTC: `2026-07-10T15:36:09.003497+00:00`
- Package ID: `pg707_etb_each_player_sacrifice_new_server_package_manifest`
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
| battle_execution | `pass` | `{"events": 22, "scenarios": 4}` |

## Battle Execution

```json
{
  "event_count": 22,
  "results": [
    {
      "card_name": "Abyssal Gorestalker",
      "sacrifice_card_types": [
        "creature"
      ],
      "sacrifice_count": 2,
      "sacrifice_requires_multicolored": false,
      "sacrificed": 4,
      "scenario": "Abyssal Gorestalker each player sacrifices matching permanents"
    },
    {
      "card_name": "Fleshbag Marauder",
      "sacrifice_card_types": [
        "creature"
      ],
      "sacrifice_count": 1,
      "sacrifice_requires_multicolored": false,
      "sacrificed": 2,
      "scenario": "Fleshbag Marauder each player sacrifices matching permanents"
    },
    {
      "card_name": "Merciless Executioner",
      "sacrifice_card_types": [
        "creature"
      ],
      "sacrifice_count": 1,
      "sacrifice_requires_multicolored": false,
      "sacrificed": 2,
      "scenario": "Merciless Executioner each player sacrifices matching permanents"
    },
    {
      "card_name": "Slum Reaper",
      "sacrifice_card_types": [
        "creature"
      ],
      "sacrifice_count": 1,
      "sacrifice_requires_multicolored": false,
      "sacrificed": 2,
      "scenario": "Slum Reaper each player sacrifices matching permanents"
    }
  ],
  "scenario_count": 4
}
```
