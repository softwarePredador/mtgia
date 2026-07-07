# Battle Package End-to-End Validation

- Generated UTC: `2026-07-07T03:41:50.863328+00:00`
- Package ID: `pg590_creature_etb_library_pick_new_server_package_manifest`
- Status: `pass`
- Database target: `127.0.0.1:15432/halder`
- SQLite DB: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db`
- Snapshot: `docs/hermes-analysis/manaloom-knowledge/scripts/known_cards_canonical_snapshot.json`

## Stage Results

| Stage | Status | Evidence |
| --- | --- | --- |
| postgres_source_of_truth | `pass` | `{"validated_rows": 11}` |
| sqlite_hermes_cache | `pass` | `{"validated_rows": 11}` |
| canonical_snapshot_fallback | `pass` | `{"validated_cards": 11}` |
| runtime_get_card_effect | `pass` | `{"validated_cards": 11}` |
| battle_execution | `pass` | `{"events": 11, "scenarios": 11}` |

## Battle Execution

```json
{
  "event_count": 11,
  "results": [
    {
      "card_name": "Augur of Bolas",
      "moved_rest": [
        "E2E Nonmatching Creature",
        "E2E Secondary Match"
      ],
      "pick_target": "instant_or_sorcery",
      "picked": [
        "E2E Preferred Match"
      ],
      "rest_destination": "library_bottom",
      "scenario": "Augur of Bolas digs on ETB"
    },
    {
      "card_name": "Courageous Outrider",
      "moved_rest": [
        "E2E Nonmatching Artifact",
        "E2E Secondary Match",
        "E2E Filler 4"
      ],
      "pick_target": "human_card",
      "picked": [
        "E2E Preferred Match"
      ],
      "rest_destination": "library_bottom",
      "scenario": "Courageous Outrider digs on ETB"
    },
    {
      "card_name": "Eclipsed Boggart",
      "moved_rest": [
        "E2E Nonmatching Artifact",
        "E2E Secondary Match",
        "E2E Filler 4"
      ],
      "pick_target": "goblin_swamp_or_mountain",
      "picked": [
        "E2E Preferred Match"
      ],
      "rest_destination": "library_bottom",
      "scenario": "Eclipsed Boggart digs on ETB"
    },
    {
      "card_name": "Eclipsed Elf",
      "moved_rest": [
        "E2E Nonmatching Artifact",
        "E2E Secondary Match",
        "E2E Filler 4"
      ],
      "pick_target": "elf_swamp_or_forest",
      "picked": [
        "E2E Preferred Match"
      ],
      "rest_destination": "library_bottom",
      "scenario": "Eclipsed Elf digs on ETB"
    },
    {
      "card_name": "Eclipsed Flamekin",
      "moved_rest": [
        "E2E Nonmatching Artifact",
        "E2E Secondary Match",
        "E2E Filler 4"
      ],
      "pick_target": "elemental_island_or_mountain",
      "picked": [
        "E2E Preferred Match"
      ],
      "rest_destination": "library_bottom",
      "scenario": "Eclipsed Flamekin digs on ETB"
    },
    {
      "card_name": "Eclipsed Kithkin",
      "moved_rest": [
        "E2E Nonmatching Artifact",
        "E2E Secondary Match",
        "E2E Filler 4"
      ],
      "pick_target": "kithkin_forest_or_plains",
      "picked": [
        "E2E Preferred Match"
      ],
      "rest_destination": "library_bottom",
      "scenario": "Eclipsed Kithkin digs on ETB"
    },
    {
      "card_name": "Eclipsed Merrow",
      "moved_rest": [
        "E2E Nonmatching Artifact",
        "E2E Secondary Match",
        "E2E Filler 4"
      ],
      "pick_target": "merfolk_plains_or_island",
      "picked": [
        "E2E Preferred Match"
      ],
      "rest_destination": "library_bottom",
      "scenario": "Eclipsed Merrow digs on ETB"
    },
    {
      "card_name": "Sea Gate Oracle",
      "moved_rest": [
        "E2E Secondary Any"
      ],
      "pick_target": "any_card",
      "picked": [
        "E2E Preferred Any"
      ],
      "rest_destination": "library_bottom",
      "scenario": "Sea Gate Oracle digs on ETB"
    },
    {
      "card_name": "Skalla Wolf",
      "moved_rest": [
        "E2E Nonmatching Artifact",
        "E2E Secondary Match",
        "E2E Filler 4",
        "E2E Filler 5"
      ],
      "pick_target": "green_card",
      "picked": [
        "E2E Preferred Match"
      ],
      "rest_destination": "library_bottom",
      "scenario": "Skalla Wolf digs on ETB"
    },
    {
      "card_name": "Staunch Crewmate",
      "moved_rest": [
        "E2E Nonmatching Creature",
        "E2E Secondary Match",
        "E2E Filler 4"
      ],
      "pick_target": "artifact_or_pirate",
      "picked": [
        "E2E Preferred Match"
      ],
      "rest_destination": "library_bottom",
      "scenario": "Staunch Crewmate digs on ETB"
    },
    {
      "card_name": "Sumala Woodshaper",
      "moved_rest": [
        "E2E Nonmatching Artifact",
        "E2E Secondary Match",
        "E2E Filler 4"
      ],
      "pick_target": "creature_or_enchantment",
      "picked": [
        "E2E Preferred Match"
      ],
      "rest_destination": "library_bottom",
      "scenario": "Sumala Woodshaper digs on ETB"
    }
  ],
  "scenario_count": 11
}
```
