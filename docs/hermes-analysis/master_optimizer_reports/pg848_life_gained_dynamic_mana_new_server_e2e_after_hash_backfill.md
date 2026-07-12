# Battle Package End-to-End Validation

- Generated UTC: `2026-07-12T22:27:04.655466+00:00`
- Package ID: `pg848_life_gained_dynamic_mana_new_server_package_manifest`
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
| battle_execution | `pass` | `{"events": 1, "scenarios": 1}` |

## Battle Execution

```json
{
  "event_count": 1,
  "results": [
    {
      "activation_limit_per_turn": 0,
      "available_mana": 3,
      "card_name": "Accomplished Alchemist",
      "conditional_life_loss_by_color": {},
      "conditional_mana": 3,
      "discarded_count": 0,
      "etb_returned_lands_to_hand_count": 0,
      "hand_size": 0,
      "life_after_refresh": 40,
      "life_paid": 0,
      "mana_activation_life_gain": 0,
      "scenario": "Accomplished Alchemist refreshes modeled mana source",
      "sources": 1,
      "support_tapped_count": 0,
      "tapped": true
    }
  ],
  "scenario_count": 1
}
```
