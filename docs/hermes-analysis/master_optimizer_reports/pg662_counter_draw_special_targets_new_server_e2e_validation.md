# Battle Package End-to-End Validation

- Generated UTC: `2026-07-08T14:59:04.074034+00:00`
- Package ID: `pg662_counter_draw_special_targets_new_server_package_manifest`
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
| battle_execution | `pass` | `{"events": 7, "scenarios": 7}` |

## Battle Execution

```json
{
  "event_count": 7,
  "results": [
    {
      "card_name": "Confound",
      "cards_drawn": 1,
      "countered": true,
      "nonmatching_target": "E2E Illegal Counter Target",
      "scenario": "Confound counters a legal stack object",
      "target": "E2E Legal Counter Target",
      "target_stack_effect": "finisher"
    },
    {
      "card_name": "Hindering Light",
      "cards_drawn": 1,
      "countered": true,
      "nonmatching_target": "E2E Illegal Counter Target",
      "scenario": "Hindering Light counters a legal stack object",
      "target": "E2E Legal Counter Target",
      "target_stack_effect": "finisher"
    },
    {
      "card_name": "Intervene",
      "cards_drawn": 0,
      "countered": true,
      "nonmatching_target": "E2E Illegal Counter Target",
      "scenario": "Intervene counters a legal stack object",
      "target": "E2E Legal Counter Target",
      "target_stack_effect": "finisher"
    },
    {
      "card_name": "Keep Safe",
      "cards_drawn": 1,
      "countered": true,
      "nonmatching_target": "E2E Illegal Counter Target",
      "scenario": "Keep Safe counters a legal stack object",
      "target": "E2E Legal Counter Target",
      "target_stack_effect": "finisher"
    },
    {
      "card_name": "Laquatus's Disdain",
      "cards_drawn": 1,
      "countered": true,
      "nonmatching_target": "E2E Illegal Counter Target",
      "scenario": "Laquatus's Disdain counters a legal stack object",
      "target": "E2E Legal Counter Target",
      "target_stack_effect": "finisher"
    },
    {
      "card_name": "Rebuff the Wicked",
      "cards_drawn": 0,
      "countered": true,
      "nonmatching_target": "E2E Illegal Counter Target",
      "scenario": "Rebuff the Wicked counters a legal stack object",
      "target": "E2E Legal Counter Target",
      "target_stack_effect": "finisher"
    },
    {
      "card_name": "Turn Aside",
      "cards_drawn": 0,
      "countered": true,
      "nonmatching_target": "E2E Illegal Counter Target",
      "scenario": "Turn Aside counters a legal stack object",
      "target": "E2E Legal Counter Target",
      "target_stack_effect": "finisher"
    }
  ],
  "scenario_count": 7
}
```
