# Battle Package End-to-End Validation

- Generated UTC: `2026-07-06T00:40:36.671072+00:00`
- Package ID: `pg539_activated_damage_discard_new_server_package_manifest`
- Status: `pass`
- Database target: `143.198.230.247:5433/halder`
- SQLite DB: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db`
- Snapshot: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/manaloom-knowledge/scripts/known_cards_canonical_snapshot.json`

## Stage Results

| Stage | Status | Evidence |
| --- | --- | --- |
| postgres_source_of_truth | `pass` | `{"validated_rows": 5}` |
| sqlite_hermes_cache | `pass` | `{"validated_rows": 5}` |
| canonical_snapshot_fallback | `pass` | `{"validated_cards": 5}` |
| runtime_get_card_effect | `pass` | `{"validated_cards": 5}` |
| battle_execution | `pass` | `{"events": 10, "scenarios": 5}` |

## Battle Execution

```json
{
  "event_count": 10,
  "results": [
    {
      "card_name": "Mage il-Vec",
      "damage": 1,
      "discard_target": "any_card",
      "discarded_count": 1,
      "opponent_life": 6,
      "scenario": "Mage il-Vec activates damage ability"
    },
    {
      "card_name": "Molten Vortex",
      "damage": 2,
      "discard_target": "land_card",
      "discarded_count": 1,
      "opponent_life": 5,
      "scenario": "Molten Vortex activates damage ability"
    },
    {
      "card_name": "Ogre Shaman",
      "damage": 2,
      "discard_target": "any_card",
      "discarded_count": 1,
      "opponent_life": 5,
      "scenario": "Ogre Shaman activates damage ability"
    },
    {
      "card_name": "Seismic Assault",
      "damage": 2,
      "discard_target": "land_card",
      "discarded_count": 1,
      "opponent_life": 5,
      "scenario": "Seismic Assault activates damage ability"
    },
    {
      "card_name": "Stormbind",
      "damage": 2,
      "discard_target": "any_card",
      "discarded_count": 1,
      "opponent_life": 5,
      "scenario": "Stormbind activates damage ability"
    }
  ],
  "scenario_count": 5
}
```
