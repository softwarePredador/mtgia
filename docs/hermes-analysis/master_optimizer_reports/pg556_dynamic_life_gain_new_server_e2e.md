# Battle Package End-to-End Validation

- Generated UTC: `2026-07-06T06:56:15.978237+00:00`
- Package ID: `pg556_dynamic_life_gain_new_server_package_manifest`
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
| battle_execution | `pass` | `{"events": 24, "scenarios": 12}` |

## Battle Execution

```json
{
  "event_count": 24,
  "results": [
    {
      "card_name": "Blessed Reversal",
      "dynamic_life_gain_count": 3,
      "life_after": 29,
      "life_gain_amount_source": "battlefield_permanent_count",
      "life_gained": 9,
      "scenario": "Blessed Reversal resolves dynamic life gain"
    },
    {
      "card_name": "Bountiful Harvest",
      "dynamic_life_gain_count": 3,
      "life_after": 23,
      "life_gain_amount_source": "battlefield_permanent_count",
      "life_gained": 3,
      "scenario": "Bountiful Harvest resolves dynamic life gain"
    },
    {
      "card_name": "Festival of Trokin",
      "dynamic_life_gain_count": 3,
      "life_after": 26,
      "life_gain_amount_source": "battlefield_permanent_count",
      "life_gained": 6,
      "scenario": "Festival of Trokin resolves dynamic life gain"
    },
    {
      "card_name": "Fruition",
      "dynamic_life_gain_count": 3,
      "life_after": 23,
      "life_gain_amount_source": "battlefield_permanent_count",
      "life_gained": 3,
      "scenario": "Fruition resolves dynamic life gain"
    },
    {
      "card_name": "Gerrard's Wisdom",
      "dynamic_life_gain_count": 3,
      "life_after": 26,
      "life_gain_amount_source": "controller_hand_count",
      "life_gained": 6,
      "scenario": "Gerrard's Wisdom resolves dynamic life gain"
    },
    {
      "card_name": "Invigorating Falls",
      "dynamic_life_gain_count": 3,
      "life_after": 23,
      "life_gain_amount_source": "graveyard_card_count",
      "life_gained": 3,
      "scenario": "Invigorating Falls resolves dynamic life gain"
    },
    {
      "card_name": "Joyous Respite",
      "dynamic_life_gain_count": 3,
      "life_after": 23,
      "life_gain_amount_source": "battlefield_permanent_count",
      "life_gained": 3,
      "scenario": "Joyous Respite resolves dynamic life gain"
    },
    {
      "card_name": "Landbind Ritual",
      "dynamic_life_gain_count": 3,
      "life_after": 26,
      "life_gain_amount_source": "battlefield_permanent_count",
      "life_gained": 6,
      "scenario": "Landbind Ritual resolves dynamic life gain"
    },
    {
      "card_name": "Peach Garden Oath",
      "dynamic_life_gain_count": 3,
      "life_after": 26,
      "life_gain_amount_source": "battlefield_permanent_count",
      "life_gained": 6,
      "scenario": "Peach Garden Oath resolves dynamic life gain"
    },
    {
      "card_name": "Presence of the Wise",
      "dynamic_life_gain_count": 3,
      "life_after": 26,
      "life_gain_amount_source": "controller_hand_count",
      "life_gained": 6,
      "scenario": "Presence of the Wise resolves dynamic life gain"
    },
    {
      "card_name": "Toil to Renown",
      "dynamic_life_gain_count": 3,
      "life_after": 23,
      "life_gain_amount_source": "battlefield_permanent_count",
      "life_gained": 3,
      "scenario": "Toil to Renown resolves dynamic life gain"
    },
    {
      "card_name": "Wandering Stream",
      "dynamic_life_gain_count": 4,
      "life_after": 28,
      "life_gain_amount_source": "domain_basic_land_types",
      "life_gained": 8,
      "scenario": "Wandering Stream resolves dynamic life gain"
    }
  ],
  "scenario_count": 12
}
```
