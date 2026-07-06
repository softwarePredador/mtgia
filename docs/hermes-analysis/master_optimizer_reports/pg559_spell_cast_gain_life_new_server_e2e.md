# Battle Package End-to-End Validation

- Generated UTC: `2026-07-06T10:07:52.080160+00:00`
- Package ID: `pg559_spell_cast_gain_life_new_server_package_manifest`
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
| battle_execution | `pass` | `{"events": 4, "scenarios": 4}` |

## Battle Execution

```json
{
  "event_count": 4,
  "results": [
    {
      "card_name": "Contemplation",
      "life_after": 21,
      "life_gained": 1,
      "scenario": "Contemplation gains life when matching spell is cast",
      "trigger": "spell_cast",
      "trigger_spell": "E2E Matching Spell for Contemplation"
    },
    {
      "card_name": "Dawnhart Geist",
      "life_after": 22,
      "life_gained": 2,
      "scenario": "Dawnhart Geist gains life when matching spell is cast",
      "trigger": "spell_cast",
      "trigger_spell": "E2E Matching Spell for Dawnhart Geist"
    },
    {
      "card_name": "God-Pharaoh's Faithful",
      "life_after": 21,
      "life_gained": 1,
      "scenario": "God-Pharaoh's Faithful gains life when matching spell is cast",
      "trigger": "spell_cast",
      "trigger_spell": "E2E Matching Spell for God-Pharaoh's Faithful"
    },
    {
      "card_name": "Student of Ojutai",
      "life_after": 22,
      "life_gained": 2,
      "scenario": "Student of Ojutai gains life when matching spell is cast",
      "trigger": "noncreature_spell_cast",
      "trigger_spell": "E2E Matching Spell for Student of Ojutai"
    }
  ],
  "scenario_count": 4
}
```
