# Battle Package End-to-End Validation

- Generated UTC: `2026-07-09T00:05:11.850510+00:00`
- Package ID: `pg678_counter_replacement_exile_new_server_manifest`
- Status: `pass`
- Database target: `127.0.0.1:15432/halder`
- SQLite DB: `docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db`
- Snapshot: `docs/hermes-analysis/manaloom-knowledge/scripts/known_cards_canonical_snapshot.json`

## Stage Results

| Stage | Status | Evidence |
| --- | --- | --- |
| postgres_source_of_truth | `pass` | `{"validated_rows": 8}` |
| sqlite_hermes_cache | `pass` | `{"validated_rows": 8}` |
| canonical_snapshot_fallback | `pass` | `{"validated_cards": 8}` |
| runtime_get_card_effect | `pass` | `{"validated_cards": 8}` |
| battle_execution | `pass` | `{"events": 16, "scenarios": 8}` |

## Battle Execution

```json
{
  "event_count": 16,
  "results": [
    {
      "card_name": "Assert Authority",
      "cards_drawn": 0,
      "countered": true,
      "countered_spell_to_exile": true,
      "nonmatching_target": "E2E Illegal Counter Target",
      "scenario": "Assert Authority counters a legal stack object",
      "target": "E2E Legal Counter Target",
      "target_stack_effect": "finisher"
    },
    {
      "card_name": "Deny Existence",
      "cards_drawn": 0,
      "countered": true,
      "countered_spell_to_exile": true,
      "nonmatching_target": "E2E Illegal Counter Target",
      "scenario": "Deny Existence counters a legal stack object",
      "target": "E2E Legal Counter Target",
      "target_stack_effect": "finisher"
    },
    {
      "card_name": "Deny the Divine",
      "cards_drawn": 0,
      "countered": true,
      "countered_spell_to_exile": true,
      "nonmatching_target": "E2E Illegal Counter Target",
      "scenario": "Deny the Divine counters a legal stack object",
      "target": "E2E Legal Counter Target",
      "target_stack_effect": "finisher"
    },
    {
      "card_name": "Dissipate",
      "cards_drawn": 0,
      "countered": true,
      "countered_spell_to_exile": true,
      "nonmatching_target": "E2E Illegal Counter Target",
      "scenario": "Dissipate counters a legal stack object",
      "target": "E2E Legal Counter Target",
      "target_stack_effect": "finisher"
    },
    {
      "card_name": "Faerie Trickery",
      "cards_drawn": 0,
      "countered": true,
      "countered_spell_to_exile": true,
      "nonmatching_target": "E2E Illegal Counter Target",
      "scenario": "Faerie Trickery counters a legal stack object",
      "target": "E2E Legal Counter Target",
      "target_stack_effect": "finisher"
    },
    {
      "card_name": "Horribly Awry",
      "cards_drawn": 0,
      "countered": true,
      "countered_spell_to_exile": true,
      "nonmatching_target": "E2E Illegal Counter Target",
      "scenario": "Horribly Awry counters a legal stack object",
      "target": "E2E Legal Counter Target",
      "target_stack_effect": "finisher"
    },
    {
      "card_name": "Liquify",
      "cards_drawn": 0,
      "countered": true,
      "countered_spell_to_exile": true,
      "nonmatching_target": "E2E Illegal Counter Target",
      "scenario": "Liquify counters a legal stack object",
      "target": "E2E Legal Counter Target",
      "target_stack_effect": "finisher"
    },
    {
      "card_name": "Void Shatter",
      "cards_drawn": 0,
      "countered": true,
      "countered_spell_to_exile": true,
      "nonmatching_target": "E2E Illegal Counter Target",
      "scenario": "Void Shatter counters a legal stack object",
      "target": "E2E Legal Counter Target",
      "target_stack_effect": "finisher"
    }
  ],
  "scenario_count": 8
}
```
