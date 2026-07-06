# Battle Package End-to-End Validation

- Generated UTC: `2026-07-06T07:50:24.228341+00:00`
- Package ID: `pg558_creature_enters_life_gain_new_server_package_manifest`
- Status: `pass`
- Database target: `143.198.230.247:5433/halder`
- SQLite DB: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db`
- Snapshot: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/manaloom-knowledge/scripts/known_cards_canonical_snapshot.json`

## Stage Results

| Stage | Status | Evidence |
| --- | --- | --- |
| postgres_source_of_truth | `pass` | `{"validated_rows": 9}` |
| sqlite_hermes_cache | `pass` | `{"validated_rows": 9}` |
| canonical_snapshot_fallback | `pass` | `{"validated_cards": 9}` |
| runtime_get_card_effect | `pass` | `{"validated_cards": 9}` |
| battle_execution | `pass` | `{"events": 9, "scenarios": 9}` |

## Battle Execution

```json
{
  "event_count": 9,
  "results": [
    {
      "card_name": "Ajani's Welcome",
      "entering_controller": "Life Trigger Controller",
      "life_after": 21,
      "life_gained": 1,
      "scenario": "Ajani's Welcome gains life when creature enters",
      "trigger": "creature_you_control_enters"
    },
    {
      "card_name": "Bogwater Lumaret",
      "entering_controller": "Life Trigger Controller",
      "life_after": 21,
      "life_gained": 1,
      "scenario": "Bogwater Lumaret gains life when creature enters",
      "trigger": "creature_you_control_enters"
    },
    {
      "card_name": "Essence Warden",
      "entering_controller": "Opponent",
      "life_after": 21,
      "life_gained": 1,
      "scenario": "Essence Warden gains life when creature enters",
      "trigger": "creature_enters"
    },
    {
      "card_name": "Healer of the Pride",
      "entering_controller": "Life Trigger Controller",
      "life_after": 22,
      "life_gained": 2,
      "scenario": "Healer of the Pride gains life when creature enters",
      "trigger": "creature_you_control_enters"
    },
    {
      "card_name": "Hinterland Sanctifier",
      "entering_controller": "Life Trigger Controller",
      "life_after": 21,
      "life_gained": 1,
      "scenario": "Hinterland Sanctifier gains life when creature enters",
      "trigger": "creature_you_control_enters"
    },
    {
      "card_name": "Impassioned Orator",
      "entering_controller": "Life Trigger Controller",
      "life_after": 21,
      "life_gained": 1,
      "scenario": "Impassioned Orator gains life when creature enters",
      "trigger": "creature_you_control_enters"
    },
    {
      "card_name": "Kor Celebrant",
      "entering_controller": "Life Trigger Controller",
      "life_after": 21,
      "life_gained": 1,
      "scenario": "Kor Celebrant gains life when creature enters",
      "trigger": "creature_you_control_enters"
    },
    {
      "card_name": "Soul Warden",
      "entering_controller": "Opponent",
      "life_after": 21,
      "life_gained": 1,
      "scenario": "Soul Warden gains life when creature enters",
      "trigger": "creature_enters"
    },
    {
      "card_name": "Soul's Attendant",
      "entering_controller": "Opponent",
      "life_after": 21,
      "life_gained": 1,
      "scenario": "Soul's Attendant gains life when creature enters",
      "trigger": "creature_enters"
    }
  ],
  "scenario_count": 9
}
```
