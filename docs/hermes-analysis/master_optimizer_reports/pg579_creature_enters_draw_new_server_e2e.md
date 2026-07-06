# Battle Package End-to-End Validation

- Generated UTC: `2026-07-06T23:19:33.276864+00:00`
- Package ID: `pg579_creature_enters_draw_new_server_package_manifest`
- Status: `pass`
- Database target: `127.0.0.1:15432/halder`
- SQLite DB: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db`
- Snapshot: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/manaloom-knowledge/scripts/known_cards_canonical_snapshot.json`

## Stage Results

| Stage | Status | Evidence |
| --- | --- | --- |
| postgres_source_of_truth | `pass` | `{"validated_rows": 5}` |
| sqlite_hermes_cache | `pass` | `{"validated_rows": 5}` |
| canonical_snapshot_fallback | `pass` | `{"validated_cards": 5}` |
| runtime_get_card_effect | `pass` | `{"validated_cards": 5}` |
| battle_execution | `pass` | `{"events": 5, "scenarios": 5}` |

## Battle Execution

```json
{
  "event_count": 5,
  "results": [
    {
      "card_name": "Elemental Bond",
      "cards_drawn": 1,
      "entering_controller": "Draw Trigger Controller",
      "hand_after": 1,
      "scenario": "Elemental Bond draws when creature enters",
      "trigger": "creature_you_control_enters"
    },
    {
      "card_name": "Garruk's Packleader",
      "cards_drawn": 1,
      "entering_controller": "Draw Trigger Controller",
      "hand_after": 1,
      "scenario": "Garruk's Packleader draws when creature enters",
      "trigger": "creature_you_control_enters"
    },
    {
      "card_name": "Mary Jane Watson",
      "cards_drawn": 1,
      "entering_controller": "Draw Trigger Controller",
      "hand_after": 1,
      "scenario": "Mary Jane Watson draws when creature enters",
      "trigger": "creature_you_control_enters"
    },
    {
      "card_name": "Wirewood Savage",
      "cards_drawn": 1,
      "entering_controller": "Opponent",
      "hand_after": 1,
      "scenario": "Wirewood Savage draws when creature enters",
      "trigger": "creature_enters"
    },
    {
      "card_name": "Woodland Liege",
      "cards_drawn": 1,
      "entering_controller": "Draw Trigger Controller",
      "hand_after": 1,
      "scenario": "Woodland Liege draws when creature enters",
      "trigger": "creature_you_control_enters"
    }
  ],
  "scenario_count": 5
}
```
