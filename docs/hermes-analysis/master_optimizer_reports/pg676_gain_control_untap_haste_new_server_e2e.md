# Battle Package End-to-End Validation

- Generated UTC: `2026-07-08T23:14:34.618417+00:00`
- Package ID: `pg676_gain_control_untap_haste_new_server_manifest`
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
| battle_execution | `pass` | `{"events": 21, "scenarios": 7}` |

## Battle Execution

```json
{
  "event_count": 21,
  "results": [
    {
      "card_name": "Act of Treason",
      "control_returned": true,
      "new_controller": "Temporary Control Controller",
      "original_controller": "Temporary Control Opponent",
      "scenario": "Act of Treason gains temporary control",
      "target": "E2E Legal Temporary Control Target"
    },
    {
      "card_name": "Blind with Anger",
      "control_returned": true,
      "new_controller": "Temporary Control Controller",
      "original_controller": "Temporary Control Opponent",
      "scenario": "Blind with Anger gains temporary control",
      "target": "E2E Legal Temporary Control Target"
    },
    {
      "card_name": "Claim the Firstborn",
      "control_returned": true,
      "new_controller": "Temporary Control Controller",
      "original_controller": "Temporary Control Opponent",
      "scenario": "Claim the Firstborn gains temporary control",
      "target": "E2E Legal Temporary Control Target"
    },
    {
      "card_name": "Hijack",
      "control_returned": true,
      "new_controller": "Temporary Control Controller",
      "original_controller": "Temporary Control Opponent",
      "scenario": "Hijack gains temporary control",
      "target": "E2E Legal Temporary Control Target"
    },
    {
      "card_name": "Metallic Mastery",
      "control_returned": true,
      "new_controller": "Temporary Control Controller",
      "original_controller": "Temporary Control Opponent",
      "scenario": "Metallic Mastery gains temporary control",
      "target": "E2E Legal Temporary Control Target"
    },
    {
      "card_name": "Threaten",
      "control_returned": true,
      "new_controller": "Temporary Control Controller",
      "original_controller": "Temporary Control Opponent",
      "scenario": "Threaten gains temporary control",
      "target": "E2E Legal Temporary Control Target"
    },
    {
      "card_name": "Wrangle",
      "control_returned": true,
      "new_controller": "Temporary Control Controller",
      "original_controller": "Temporary Control Opponent",
      "scenario": "Wrangle gains temporary control",
      "target": "E2E Legal Temporary Control Target"
    }
  ],
  "scenario_count": 7
}
```
