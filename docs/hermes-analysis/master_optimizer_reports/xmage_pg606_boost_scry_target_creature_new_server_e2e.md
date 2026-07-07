# Battle Package End-to-End Validation

- Generated UTC: `2026-07-07T09:28:08.637431+00:00`
- Package ID: `xmage_pg606_boost_scry_target_creature_new_server_manifest`
- Status: `pass`
- Database target: `127.0.0.1:15432/halder`
- SQLite DB: `docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db`
- Snapshot: `docs/hermes-analysis/manaloom-knowledge/scripts/known_cards_canonical_snapshot.json`

## Stage Results

| Stage | Status | Evidence |
| --- | --- | --- |
| postgres_source_of_truth | `pass` | `{"validated_rows": 9}` |
| sqlite_hermes_cache | `pass` | `{"validated_rows": 9}` |
| canonical_snapshot_fallback | `pass` | `{"validated_cards": 9}` |
| runtime_get_card_effect | `pass` | `{"validated_cards": 9}` |
| battle_execution | `pass` | `{"events": 55, "scenarios": 9}` |

## Battle Execution

```json
{
  "event_count": 55,
  "results": [
    {
      "card_name": "Battlewise Valor",
      "scenario": "Battlewise Valor boosts target creature and scries 1",
      "scry_count": 1,
      "target": "E2E Target Creature",
      "target_power": 4,
      "target_toughness": 4,
      "top_after": [
        "E2E Low Priority Land"
      ]
    },
    {
      "card_name": "Chain to Memory",
      "scenario": "Chain to Memory boosts target creature and scries 2",
      "scry_count": 2,
      "target": "E2E Target Creature",
      "target_power": -2,
      "target_toughness": 2,
      "top_after": [
        "E2E High Priority Spell",
        "E2E Low Priority Land"
      ]
    },
    {
      "card_name": "Cruel Finality",
      "scenario": "Cruel Finality boosts target creature and scries 1",
      "scry_count": 1,
      "target": "E2E Target Creature",
      "target_power": 0,
      "target_toughness": 0,
      "top_after": [
        "E2E Low Priority Land"
      ]
    },
    {
      "card_name": "Ferocious Charge",
      "scenario": "Ferocious Charge boosts target creature and scries 2",
      "scry_count": 2,
      "target": "E2E Target Creature",
      "target_power": 6,
      "target_toughness": 6,
      "top_after": [
        "E2E High Priority Spell",
        "E2E Low Priority Land"
      ]
    },
    {
      "card_name": "Inordinate Rage",
      "scenario": "Inordinate Rage boosts target creature and scries 1",
      "scry_count": 1,
      "target": "E2E Target Creature",
      "target_power": 5,
      "target_toughness": 4,
      "top_after": [
        "E2E Low Priority Land"
      ]
    },
    {
      "card_name": "Lose Hope",
      "scenario": "Lose Hope boosts target creature and scries 2",
      "scry_count": 2,
      "target": "E2E Target Creature",
      "target_power": 1,
      "target_toughness": 1,
      "top_after": [
        "E2E High Priority Spell",
        "E2E Low Priority Land"
      ]
    },
    {
      "card_name": "Lost in a Labyrinth",
      "scenario": "Lost in a Labyrinth boosts target creature and scries 1",
      "scry_count": 1,
      "target": "E2E Target Creature",
      "target_power": -1,
      "target_toughness": 2,
      "top_after": [
        "E2E Low Priority Land"
      ]
    },
    {
      "card_name": "Stand Firm",
      "scenario": "Stand Firm boosts target creature and scries 2",
      "scry_count": 2,
      "target": "E2E Target Creature",
      "target_power": 3,
      "target_toughness": 3,
      "top_after": [
        "E2E High Priority Spell",
        "E2E Low Priority Land"
      ]
    },
    {
      "card_name": "Titan's Strength",
      "scenario": "Titan's Strength boosts target creature and scries 1",
      "scry_count": 1,
      "target": "E2E Target Creature",
      "target_power": 5,
      "target_toughness": 3,
      "top_after": [
        "E2E Low Priority Land"
      ]
    }
  ],
  "scenario_count": 9
}
```
