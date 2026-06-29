# PGC063 Pain Mana Source Cost Runtime Validation

- Generated UTC: `2026-06-29T10:08:56.768754+00:00`
- Package ID: `pgc063_pain_mana_source_cost_runtime`
- Status: `pass`
- Database target: `143.198.230.247:5433/halder`
- SQLite DB: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db`
- Snapshot: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/manaloom-knowledge/scripts/known_cards_canonical_snapshot.json`

## Stage Results

| Stage | Status | Evidence |
| --- | --- | --- |
| postgres_source_of_truth | `pass` | `{"validated_rows": 4}` |
| sqlite_hermes_cache | `pass` | `{"validated_rows": 4}` |
| canonical_snapshot_fallback | `pass` | `{"validated_cards": 4}` |
| runtime_get_card_effect | `pass` | `{"validated_cards": 4}` |
| battle_execution_no_override | `pass` | `{"events": 9, "scenarios": 5}` |

## Battle Execution

```json
{
  "event_count": 9,
  "results": [
    {
      "available_mana_after_refresh": 1,
      "available_mana_after_spend": 0,
      "card_name": "City of Brass",
      "cost": "{W}",
      "life_after_spend": 39,
      "life_cost_events": 1,
      "scenario": "city_white_mana_deals_one_damage_on_spend"
    },
    {
      "available_mana_after_refresh": 1,
      "available_mana_after_spend": 0,
      "card_name": "Elves of Deep Shadow",
      "cost": "{B}",
      "life_after_spend": 39,
      "life_cost_events": 1,
      "scenario": "elves_black_mana_deals_one_damage_on_spend"
    },
    {
      "available_mana_after_refresh": 1,
      "available_mana_after_spend": 0,
      "card_name": "Mana Confluence",
      "cost": "{R}",
      "life_after_spend": 39,
      "life_cost_events": 1,
      "scenario": "mana_confluence_red_mana_pays_one_life_on_spend"
    },
    {
      "available_mana_after_refresh": 1,
      "available_mana_after_spend": 0,
      "card_name": "Tarnished Citadel",
      "cost": "{1}",
      "life_after_spend": 40,
      "life_cost_events": 0,
      "scenario": "tarnished_colorless_mana_has_no_life_loss"
    },
    {
      "available_mana_after_refresh": 1,
      "available_mana_after_spend": 0,
      "card_name": "Tarnished Citadel",
      "cost": "{G}",
      "life_after_spend": 37,
      "life_cost_events": 1,
      "scenario": "tarnished_colored_mana_deals_three_damage_on_spend"
    }
  ],
  "scenario_count": 5
}
```
