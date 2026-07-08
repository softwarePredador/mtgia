# Battle Package End-to-End Validation

- Generated UTC: `2026-07-08T17:04:01.797815+00:00`
- Package ID: `pg664_counter_oracle_auxiliary_x_modal_new_server_package_manifest`
- Status: `pass`
- Database target: `127.0.0.1:15432/halder`
- SQLite DB: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db`
- Snapshot: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/manaloom-knowledge/scripts/known_cards_canonical_snapshot.json`

## Stage Results

| Stage | Status | Evidence |
| --- | --- | --- |
| postgres_source_of_truth | `pass` | `{"validated_rows": 6}` |
| sqlite_hermes_cache | `pass` | `{"validated_rows": 6}` |
| canonical_snapshot_fallback | `pass` | `{"validated_cards": 6}` |
| runtime_get_card_effect | `pass` | `{"validated_cards": 6}` |
| battle_execution | `pass` | `{"events": 6, "scenarios": 6}` |

## Battle Execution

```json
{
  "event_count": 6,
  "results": [
    {
      "card_name": "Broken Concentration",
      "cards_drawn": 0,
      "countered": true,
      "nonmatching_target": "E2E Illegal Counter Target",
      "scenario": "Broken Concentration counters a legal stack object",
      "target": "E2E Legal Counter Target",
      "target_stack_effect": "finisher"
    },
    {
      "card_name": "Change the Equation",
      "cards_drawn": 0,
      "countered": true,
      "nonmatching_target": "E2E Illegal Counter Target",
      "scenario": "Change the Equation counters a legal stack object",
      "target": "E2E Legal Counter Target",
      "target_stack_effect": "finisher"
    },
    {
      "card_name": "Fervent Denial",
      "cards_drawn": 0,
      "countered": true,
      "nonmatching_target": "E2E Illegal Counter Target",
      "scenario": "Fervent Denial counters a legal stack object",
      "target": "E2E Legal Counter Target",
      "target_stack_effect": "finisher"
    },
    {
      "card_name": "Neutralize",
      "cards_drawn": 0,
      "countered": true,
      "nonmatching_target": "E2E Illegal Counter Target",
      "scenario": "Neutralize counters a legal stack object",
      "target": "E2E Legal Counter Target",
      "target_stack_effect": "finisher"
    },
    {
      "card_name": "Overwhelming Denial",
      "cards_drawn": 0,
      "countered": true,
      "nonmatching_target": "E2E Illegal Counter Target",
      "scenario": "Overwhelming Denial counters a legal stack object",
      "target": "E2E Legal Counter Target",
      "target_stack_effect": "finisher"
    },
    {
      "card_name": "Spell Blast",
      "cards_drawn": 0,
      "countered": true,
      "nonmatching_target": "E2E Illegal Counter Target",
      "scenario": "Spell Blast counters a legal stack object",
      "target": "E2E Legal Counter Target",
      "target_stack_effect": "finisher"
    }
  ],
  "scenario_count": 6
}
```
