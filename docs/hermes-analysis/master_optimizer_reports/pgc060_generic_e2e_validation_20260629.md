# PGC060 Generic End-to-End Runtime Validation

- Generated UTC: `2026-06-29T09:39:16.753041+00:00`
- Package ID: `pgc060_runtime_annotation_executor`
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
| battle_execution_no_override | `pass` | `{"events": 9, "scenarios": 2}` |

## Battle Execution

```json
{
  "event_count": 9,
  "results": [
    {
      "attack_assignment_by_opponent": {
        "Opponent A": 2,
        "Opponent B": 2,
        "Opponent C": 2
      },
      "card_name": "Furygale Flocking",
      "multi_defender_attack_groups": {
        "Opponent A": 2,
        "Opponent B": 2,
        "Opponent C": 2
      },
      "scenario": "furygale_per_opponent_tokens_attack_each_opponent",
      "tokens_created": 6
    },
    {
      "card_name": "Tempt with Bunnies",
      "choice_model": "opponents_decline",
      "controller_hand_size_after": 1,
      "controller_token_count_after": 1,
      "opponents_declined": 2,
      "scenario": "tempt_with_bunnies_default_decline"
    }
  ],
  "scenario_count": 2
}
```
