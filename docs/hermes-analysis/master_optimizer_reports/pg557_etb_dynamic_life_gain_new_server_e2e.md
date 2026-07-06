# Battle Package End-to-End Validation

- Generated UTC: `2026-07-06T07:20:07.539844+00:00`
- Package ID: `pg557_etb_dynamic_life_gain_new_server_package_manifest`
- Status: `pass`
- Database target: `143.198.230.247:5433/halder`
- SQLite DB: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db`
- Snapshot: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/manaloom-knowledge/scripts/known_cards_canonical_snapshot.json`

## Stage Results

| Stage | Status | Evidence |
| --- | --- | --- |
| postgres_source_of_truth | `pass` | `{"validated_rows": 12}` |
| sqlite_hermes_cache | `pass` | `{"validated_rows": 12}` |
| canonical_snapshot_fallback | `pass` | `{"validated_cards": 12}` |
| runtime_get_card_effect | `pass` | `{"validated_cards": 12}` |
| battle_execution | `pass` | `{"events": 12, "scenarios": 12}` |

## Battle Execution

```json
{
  "event_count": 12,
  "results": [
    {
      "card_name": "Ancestor's Chosen",
      "dynamic_life_gain_count": 3,
      "life_after": 23,
      "life_gain_amount_source": "graveyard_card_count",
      "life_gained": 3,
      "scenario": "Ancestor's Chosen resolves ETB dynamic life gain"
    },
    {
      "card_name": "Angel of Renewal",
      "dynamic_life_gain_count": 3,
      "life_after": 23,
      "life_gain_amount_source": "battlefield_permanent_count",
      "life_gained": 3,
      "scenario": "Angel of Renewal resolves ETB dynamic life gain"
    },
    {
      "card_name": "Archway Angel",
      "dynamic_life_gain_count": 3,
      "life_after": 26,
      "life_gain_amount_source": "battlefield_permanent_count",
      "life_gained": 6,
      "scenario": "Archway Angel resolves ETB dynamic life gain"
    },
    {
      "card_name": "Aven Gagglemaster",
      "dynamic_life_gain_count": 3,
      "life_after": 26,
      "life_gain_amount_source": "battlefield_permanent_count",
      "life_gained": 6,
      "scenario": "Aven Gagglemaster resolves ETB dynamic life gain"
    },
    {
      "card_name": "Dwarven Priest",
      "dynamic_life_gain_count": 3,
      "life_after": 23,
      "life_gain_amount_source": "battlefield_permanent_count",
      "life_gained": 3,
      "scenario": "Dwarven Priest resolves ETB dynamic life gain"
    },
    {
      "card_name": "Flourishing Hunter",
      "dynamic_life_gain_count": 5,
      "life_after": 25,
      "life_gain_amount_source": "greatest_toughness_among_other_controlled_creatures",
      "life_gained": 5,
      "scenario": "Flourishing Hunter resolves ETB dynamic life gain"
    },
    {
      "card_name": "Goldnight Redeemer",
      "dynamic_life_gain_count": 3,
      "life_after": 26,
      "life_gain_amount_source": "battlefield_permanent_count",
      "life_gained": 6,
      "scenario": "Goldnight Redeemer resolves ETB dynamic life gain"
    },
    {
      "card_name": "Kraul Foragers",
      "dynamic_life_gain_count": 2,
      "life_after": 22,
      "life_gain_amount_source": "graveyard_card_count",
      "life_gained": 2,
      "scenario": "Kraul Foragers resolves ETB dynamic life gain"
    },
    {
      "card_name": "Luminollusk",
      "dynamic_life_gain_count": 3,
      "life_after": 23,
      "life_gain_amount_source": "colors_among_permanents_you_control",
      "life_gained": 3,
      "scenario": "Luminollusk resolves ETB dynamic life gain"
    },
    {
      "card_name": "Nylea's Disciple",
      "dynamic_life_gain_count": 3,
      "life_after": 23,
      "life_gain_amount_source": "controlled_permanents_mana_symbol_count",
      "life_gained": 3,
      "scenario": "Nylea's Disciple resolves ETB dynamic life gain"
    },
    {
      "card_name": "Setessan Petitioner",
      "dynamic_life_gain_count": 3,
      "life_after": 23,
      "life_gain_amount_source": "controlled_permanents_mana_symbol_count",
      "life_gained": 3,
      "scenario": "Setessan Petitioner resolves ETB dynamic life gain"
    },
    {
      "card_name": "Shepherd of Heroes",
      "dynamic_life_gain_count": 3,
      "life_after": 26,
      "life_gain_amount_source": "party_count",
      "life_gained": 6,
      "scenario": "Shepherd of Heroes resolves ETB dynamic life gain"
    }
  ],
  "scenario_count": 12
}
```
