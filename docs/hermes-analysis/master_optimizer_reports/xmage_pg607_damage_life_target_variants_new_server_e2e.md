# Battle Package End-to-End Validation

- Generated UTC: `2026-07-07T09:52:04.272248+00:00`
- Package ID: `xmage_pg607_damage_life_target_variants_new_server_manifest`
- Status: `pass`
- Database target: `127.0.0.1:15432/halder`
- SQLite DB: `docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db`
- Snapshot: `docs/hermes-analysis/manaloom-knowledge/scripts/known_cards_canonical_snapshot.json`

## Stage Results

| Stage | Status | Evidence |
| --- | --- | --- |
| postgres_source_of_truth | `pass` | `{"validated_rows": 10}` |
| sqlite_hermes_cache | `pass` | `{"validated_rows": 10}` |
| canonical_snapshot_fallback | `pass` | `{"validated_cards": 10}` |
| runtime_get_card_effect | `pass` | `{"validated_cards": 10}` |
| battle_execution | `pass` | `{"events": 25, "scenarios": 10}` |

## Battle Execution

```json
{
  "event_count": 25,
  "results": [
    {
      "card_name": "Deadly Riposte",
      "controller_life": 12,
      "damage": 3,
      "life_gained": 2,
      "opponent_life": 20,
      "scenario": "Deadly Riposte deals damage and gains life",
      "target": "E2E Damage Gain Legal Target"
    },
    {
      "card_name": "Joust Through",
      "controller_life": 11,
      "damage": 3,
      "life_gained": 1,
      "opponent_life": 20,
      "scenario": "Joust Through deals damage and gains life",
      "target": "E2E Damage Gain Legal Target"
    },
    {
      "card_name": "Kiss of Death",
      "controller_life": 14,
      "damage": 4,
      "life_gained": 4,
      "opponent_life": 16,
      "scenario": "Kiss of Death deals damage and gains life",
      "target": "Opponent"
    },
    {
      "card_name": "Sorin's Vengeance",
      "controller_life": 20,
      "damage": 10,
      "life_gained": 10,
      "opponent_life": 10,
      "scenario": "Sorin's Vengeance deals damage and gains life",
      "target": "Opponent"
    },
    {
      "card_name": "Soul Shred",
      "controller_life": 13,
      "damage": 3,
      "life_gained": 3,
      "opponent_life": 20,
      "scenario": "Soul Shred deals damage and gains life",
      "target": "E2E Damage Gain Legal Target"
    },
    {
      "card_name": "Soul Spike",
      "controller_life": 14,
      "damage": 4,
      "life_gained": 4,
      "opponent_life": 20,
      "scenario": "Soul Spike deals damage and gains life",
      "target": "E2E Damage Gain Legal Target"
    },
    {
      "card_name": "Spinning Darkness",
      "controller_life": 13,
      "damage": 3,
      "life_gained": 3,
      "opponent_life": 20,
      "scenario": "Spinning Darkness deals damage and gains life",
      "target": "E2E Damage Gain Legal Target"
    },
    {
      "card_name": "Stolen Grain",
      "controller_life": 15,
      "damage": 5,
      "life_gained": 5,
      "opponent_life": 15,
      "scenario": "Stolen Grain deals damage and gains life",
      "target": "Opponent"
    },
    {
      "card_name": "Taste of Blood",
      "controller_life": 11,
      "damage": 1,
      "life_gained": 1,
      "opponent_life": 19,
      "scenario": "Taste of Blood deals damage and gains life",
      "target": "Opponent"
    },
    {
      "card_name": "Vampiric Touch",
      "controller_life": 12,
      "damage": 2,
      "life_gained": 2,
      "opponent_life": 18,
      "scenario": "Vampiric Touch deals damage and gains life",
      "target": "Opponent"
    }
  ],
  "scenario_count": 10
}
```
