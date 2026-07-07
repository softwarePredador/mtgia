# PG644 Oracle Identity Mana Source Rule Link

- Generated UTC: `2026-07-07T22:26:25.567016+00:00`
- Package ID: `pg644_oracle_identity_mana_source_role_link_new_server`
- Status: `pass`
- Database target: `127.0.0.1:15432/halder`
- SQLite DB: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db`
- Snapshot: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/manaloom-knowledge/scripts/known_cards_canonical_snapshot.json`

## Stage Results

| Stage | Status | Evidence |
| --- | --- | --- |
| postgres_source_of_truth | `pass` | `{"validated_rows": 2}` |
| sqlite_hermes_cache | `pass` | `{"validated_rows": 2}` |
| canonical_snapshot_fallback | `pass` | `{"validated_cards": 2}` |
| runtime_get_card_effect | `pass` | `{"validated_cards": 2}` |
| battle_execution | `pass` | `{"events": 2, "scenarios": 2}` |

## Battle Execution

```json
{
  "event_count": 2,
  "results": [
    {
      "activation_limit_per_turn": 0,
      "available_mana": 1,
      "card_name": "Birds of Paradise // Birds of Paradise",
      "conditional_mana": 1,
      "life_after_refresh": 40,
      "life_paid": 0,
      "scenario": "Birds of Paradise // Birds of Paradise produces one mana",
      "sources": 1,
      "tapped": true
    },
    {
      "activation_limit_per_turn": 0,
      "available_mana": 2,
      "card_name": "Sol Ring // Sol Ring",
      "conditional_mana": 0,
      "life_after_refresh": 40,
      "life_paid": 0,
      "scenario": "Sol Ring // Sol Ring produces two colorless mana",
      "sources": 1,
      "tapped": true
    }
  ],
  "scenario_count": 2
}
```
