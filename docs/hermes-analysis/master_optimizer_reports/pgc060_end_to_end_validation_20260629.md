# PGC060 End-to-End Runtime Validation

- Generated UTC: `2026-06-29T09:14:34.059714+00:00`
- Status: `pass`
- Database target: `143.198.230.247:5433/halder`
- SQLite DB: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db`
- Snapshot: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/manaloom-knowledge/scripts/known_cards_canonical_snapshot.json`

## Stage Results

| Stage | Status | Evidence |
| --- | --- | --- |
| postgres_source_of_truth | `pass` | `{"validated_rows": 3}` |
| sqlite_hermes_cache | `pass` | `{"validated_rows": 3}` |
| canonical_snapshot_fallback | `pass` | `{"validated_cards": 2}` |
| runtime_get_card_effect | `pass` | `{"validated_cards": 2}` |
| battle_execution_no_override | `pass` | `{"events": 9, "furygale_tokens": 6, "tempt_choice_model": "opponents_decline"}` |

## Runtime Execution

```json
{
  "event_count": 9,
  "furygale": {
    "attack_assignment_by_opponent": [
      {
        "defender": "Opponent A",
        "tokens": 2
      },
      {
        "defender": "Opponent B",
        "tokens": 2
      },
      {
        "defender": "Opponent C",
        "tokens": 2
      }
    ],
    "multi_defender_attack_groups": {
      "Opponent A": 2,
      "Opponent B": 2,
      "Opponent C": 2
    },
    "tokens_created": 6
  },
  "tempt_with_bunnies": {
    "choice_model": "opponents_decline",
    "controller_base_cards_drawn": 1,
    "controller_base_tokens_created": 1,
    "controller_bonus_cards_drawn": 0,
    "controller_bonus_tokens_created": 0,
    "controller_hand_size_after": 1,
    "controller_rabbit_count_after": 1,
    "opponent_hand_sizes_after": {
      "Decliner A": 0,
      "Decliner B": 0
    },
    "opponent_rabbit_counts_after": {
      "Decliner A": 0,
      "Decliner B": 0
    },
    "opponents_accepted": 0,
    "opponents_declined": 2
  }
}
```
