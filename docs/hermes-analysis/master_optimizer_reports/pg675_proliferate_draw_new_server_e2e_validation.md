# Battle Package End-to-End Validation

- Generated UTC: `2026-07-08T22:38:48.769401+00:00`
- Package ID: `pg675_proliferate_draw_new_server_manifest`
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
| battle_execution | `pass` | `{"events": 20, "scenarios": 4}` |

## Battle Execution

```json
{
  "event_count": 20,
  "results": [
    {
      "card_name": "Contentious Plan",
      "controller_plus_one_counters": 2,
      "draw_count": 1,
      "opponent_charge_counters": 3,
      "opponent_poison_counters": 2,
      "scenario": "Contentious Plan proliferates and draws 1"
    },
    {
      "card_name": "Steady Progress",
      "controller_plus_one_counters": 2,
      "draw_count": 1,
      "opponent_charge_counters": 3,
      "opponent_poison_counters": 2,
      "scenario": "Steady Progress proliferates and draws 1"
    },
    {
      "card_name": "Tezzeret's Gambit",
      "controller_plus_one_counters": 2,
      "draw_count": 2,
      "opponent_charge_counters": 3,
      "opponent_poison_counters": 2,
      "scenario": "Tezzeret's Gambit proliferates and draws 2"
    },
    {
      "card_name": "Vivisurgeon's Insight",
      "controller_plus_one_counters": 2,
      "draw_count": 3,
      "opponent_charge_counters": 3,
      "opponent_poison_counters": 2,
      "scenario": "Vivisurgeon's Insight proliferates and draws 3"
    }
  ],
  "scenario_count": 4
}
```
