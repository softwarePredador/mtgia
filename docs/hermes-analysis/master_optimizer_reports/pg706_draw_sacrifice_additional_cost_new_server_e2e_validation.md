# Battle Package End-to-End Validation

- Generated UTC: `2026-07-10T15:16:06.634692+00:00`
- Package ID: `pg706_draw_sacrifice_additional_cost_new_server_package_manifest`
- Status: `pass`
- Database target: `127.0.0.1:15432/halder`
- SQLite DB: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db`
- Snapshot: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/manaloom-knowledge/scripts/known_cards_canonical_snapshot.json`

## Stage Results

| Stage | Status | Evidence |
| --- | --- | --- |
| postgres_source_of_truth | `pass` | `{"validated_rows": 2}` |
| sqlite_hermes_cache | `pass` | `{"validated_rows": 2}` |
| canonical_snapshot_fallback | `pass` | `{"validated_cards": 2}` |
| runtime_get_card_effect | `pass` | `{"validated_cards": 2}` |
| battle_execution | `pass` | `{"events": 9, "scenarios": 2}` |

## Battle Execution

```json
{
  "event_count": 9,
  "results": [
    {
      "additional_cost": "sacrifice_two_creatures",
      "card_name": "Bankrupt in Blood",
      "cards_drawn": 3,
      "sacrificed": [
        "E2E Sacrifice Cost Creature 1",
        "E2E Sacrifice Cost Creature 2"
      ],
      "scenario": "Bankrupt in Blood draws cards"
    },
    {
      "additional_cost": "sacrifice_creature_or_land",
      "card_name": "Merciless Resolve",
      "cards_drawn": 2,
      "sacrificed": [
        "E2E Sacrifice Cost Creature"
      ],
      "scenario": "Merciless Resolve draws cards"
    }
  ],
  "scenario_count": 2
}
```
