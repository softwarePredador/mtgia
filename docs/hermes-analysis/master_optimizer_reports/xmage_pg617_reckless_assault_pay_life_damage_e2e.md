# Battle Package End-to-End Validation

- Generated UTC: `2026-07-07T13:18:36.986102+00:00`
- Package ID: `xmage_pg617_reckless_assault_pay_life_damage_manifest`
- Status: `pass`
- Database target: `127.0.0.1:15432/halder`
- SQLite DB: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db`
- Snapshot: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/manaloom-knowledge/scripts/known_cards_canonical_snapshot.json`

## Stage Results

| Stage | Status | Evidence |
| --- | --- | --- |
| postgres_source_of_truth | `pass` | `{"validated_rows": 1}` |
| sqlite_hermes_cache | `pass` | `{"validated_rows": 1}` |
| canonical_snapshot_fallback | `pass` | `{"validated_cards": 1}` |
| runtime_get_card_effect | `pass` | `{"validated_cards": 1}` |
| battle_execution | `pass` | `{"events": 2, "scenarios": 1}` |

## Battle Execution

```json
{
  "event_count": 2,
  "results": [
    {
      "card_name": "Reckless Assault",
      "controller_life": 38,
      "damage": 1,
      "discard_target": null,
      "discarded_count": 0,
      "life_paid": 2,
      "opponent_life": 6,
      "scenario": "Reckless Assault activates damage ability"
    }
  ],
  "scenario_count": 1
}
```
