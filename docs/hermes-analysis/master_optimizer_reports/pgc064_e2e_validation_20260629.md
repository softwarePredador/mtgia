# PGC064 Copy Spell Choose New Targets Runtime Validation

- Generated UTC: `2026-06-29T10:31:16.555153+00:00`
- Package ID: `pgc064_copy_spell_choose_new_targets_runtime`
- Status: `pass`
- Database target: `143.198.230.247:5433/halder`
- SQLite DB: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db`
- Snapshot: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/manaloom-knowledge/scripts/known_cards_canonical_snapshot.json`

## Stage Results

| Stage | Status | Evidence |
| --- | --- | --- |
| postgres_source_of_truth | `pass` | `{"validated_rows": 3}` |
| sqlite_hermes_cache | `pass` | `{"validated_rows": 3}` |
| canonical_snapshot_fallback | `pass` | `{"validated_cards": 3}` |
| runtime_get_card_effect | `pass` | `{"validated_cards": 3}` |
| battle_execution_no_override | `pass` | `{"events": 11, "scenarios": 3}` |

## Battle Execution

```json
{
  "event_count": 11,
  "results": [
    {
      "card_name": "Reverberate",
      "copied_spell": "Targeted Removal",
      "copy_path": "response",
      "copy_spell_target": "Better Target",
      "copy_target_selection_status": "runtime_executor_v1",
      "scenario": "reverberate_response_retargets_copied_removal",
      "target_reassignment_performed": true
    },
    {
      "card_name": "Reiterate",
      "copied_spell": "Targeted Removal",
      "copy_path": "response",
      "copy_spell_target": "Better Target",
      "copy_target_selection_status": "runtime_executor_v1",
      "scenario": "reiterate_response_retargets_copied_removal_buyback_residual",
      "target_reassignment_performed": true
    },
    {
      "card_name": "Dualcaster Mage",
      "copied_spell": "Targeted Removal",
      "copy_path": "etb",
      "copy_spell_target": "Better Target",
      "copy_target_selection_status": "runtime_executor_v1",
      "scenario": "dualcaster_etb_retargets_copied_removal",
      "target_reassignment_performed": true
    }
  ],
  "scenario_count": 3
}
```
