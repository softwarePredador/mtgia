# Battle Package End-to-End Validation

- Generated UTC: `2026-07-08T20:34:11.449884+00:00`
- Package ID: `pg671_tap_target_spell_new_server_package_manifest`
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
| battle_execution | `pass` | `{"events": 12, "scenarios": 6}` |

## Battle Execution

```json
{
  "event_count": 12,
  "results": [
    {
      "card_name": "Downpour",
      "scenario": "Downpour taps target permanents",
      "target_tapped_count": 3,
      "targets_tapped": [
        "E2E Legal Tap Spell Target 1",
        "E2E Legal Tap Spell Target 2",
        "E2E Legal Tap Spell Target 3"
      ]
    },
    {
      "card_name": "Early Frost",
      "scenario": "Early Frost taps target permanents",
      "target_tapped_count": 3,
      "targets_tapped": [
        "E2E Legal Tap Spell Target 1",
        "E2E Legal Tap Spell Target 2",
        "E2E Legal Tap Spell Target 3"
      ]
    },
    {
      "card_name": "Gridlock",
      "scenario": "Gridlock taps target permanents",
      "target_tapped_count": 2,
      "targets_tapped": [
        "E2E Legal Tap Spell Target 1",
        "E2E Legal Tap Spell Target 2"
      ]
    },
    {
      "card_name": "Lead Astray",
      "scenario": "Lead Astray taps target permanents",
      "target_tapped_count": 2,
      "targets_tapped": [
        "E2E Legal Tap Spell Target 1",
        "E2E Legal Tap Spell Target 2"
      ]
    },
    {
      "card_name": "Terashi's Cry",
      "scenario": "Terashi's Cry taps target permanents",
      "target_tapped_count": 3,
      "targets_tapped": [
        "E2E Legal Tap Spell Target 1",
        "E2E Legal Tap Spell Target 2",
        "E2E Legal Tap Spell Target 3"
      ]
    },
    {
      "card_name": "Word of Binding",
      "scenario": "Word of Binding taps target permanents",
      "target_tapped_count": 2,
      "targets_tapped": [
        "E2E Legal Tap Spell Target 1",
        "E2E Legal Tap Spell Target 2"
      ]
    }
  ],
  "scenario_count": 6
}
```
