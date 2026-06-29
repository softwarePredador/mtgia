# PGC065 Modal Target Change Runtime Validation

- Generated UTC: `2026-06-29T10:48:38.650213+00:00`
- Package ID: `pgc065_modal_target_change_runtime`
- Status: `pass`
- Database target: `143.198.230.247:5433/halder`
- SQLite DB: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db`
- Snapshot: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/manaloom-knowledge/scripts/known_cards_canonical_snapshot.json`

## Stage Results

| Stage | Status | Evidence |
| --- | --- | --- |
| postgres_source_of_truth | `pass` | `{"validated_rows": 2}` |
| sqlite_hermes_cache | `pass` | `{"validated_rows": 2}` |
| canonical_snapshot_fallback | `pass` | `{"validated_cards": 2}` |
| runtime_get_card_effect | `pass` | `{"validated_cards": 2}` |
| battle_execution_no_override | `pass` | `{"events": 4, "scenarios": 2}` |

## Battle Execution

```json
{
  "event_count": 4,
  "results": [
    {
      "card_name": "Return the Favor",
      "new_target": "Opponent Threat",
      "old_target": "Protected Creature",
      "scenario": "return_the_favor_changes_single_target_stack_removal",
      "target_change_applied": true,
      "target_change_pipeline": "single_target_stack_object_redirect_runtime_v1"
    },
    {
      "card_name": "Untimely Malfunction",
      "new_target": "Opponent Threat",
      "old_target": "Protected Creature",
      "scenario": "untimely_malfunction_redirects_single_target_stack_removal",
      "target_change_applied": true,
      "target_change_pipeline": "single_target_stack_object_redirect_runtime_v1"
    }
  ],
  "scenario_count": 2
}
```
