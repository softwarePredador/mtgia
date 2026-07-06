# Battle Package End-to-End Validation

- Generated UTC: `2026-07-06T05:25:21.435784+00:00`
- Package ID: `pg552_activated_tap_target_creature_new_server_package_manifest`
- Status: `pass`
- Database target: `143.198.230.247:5433/halder`
- SQLite DB: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db`
- Snapshot: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/manaloom-knowledge/scripts/known_cards_canonical_snapshot.json`

## Stage Results

| Stage | Status | Evidence |
| --- | --- | --- |
| postgres_source_of_truth | `pass` | `{"validated_rows": 13}` |
| sqlite_hermes_cache | `pass` | `{"validated_rows": 13}` |
| canonical_snapshot_fallback | `pass` | `{"validated_cards": 13}` |
| runtime_get_card_effect | `pass` | `{"validated_cards": 13}` |
| battle_execution | `pass` | `{"events": 26, "scenarios": 13}` |

## Battle Execution

```json
{
  "event_count": 26,
  "results": [
    {
      "card_name": "Akroan Jailer",
      "scenario": "Akroan Jailer activates tap target ability",
      "source_tapped": true,
      "target": "E2E Creature Target for Akroan Jailer",
      "target_tapped": true
    },
    {
      "card_name": "Akroan Mastiff",
      "scenario": "Akroan Mastiff activates tap target ability",
      "source_tapped": true,
      "target": "E2E Creature Target for Akroan Mastiff",
      "target_tapped": true
    },
    {
      "card_name": "Blinding Mage",
      "scenario": "Blinding Mage activates tap target ability",
      "source_tapped": true,
      "target": "E2E Creature Target for Blinding Mage",
      "target_tapped": true
    },
    {
      "card_name": "Checkpoint Officer",
      "scenario": "Checkpoint Officer activates tap target ability",
      "source_tapped": true,
      "target": "E2E Creature Target for Checkpoint Officer",
      "target_tapped": true
    },
    {
      "card_name": "Elite Arrester",
      "scenario": "Elite Arrester activates tap target ability",
      "source_tapped": true,
      "target": "E2E Creature Target for Elite Arrester",
      "target_tapped": true
    },
    {
      "card_name": "Fan Bearer",
      "scenario": "Fan Bearer activates tap target ability",
      "source_tapped": true,
      "target": "E2E Creature Target for Fan Bearer",
      "target_tapped": true
    },
    {
      "card_name": "Frostbridge Guard",
      "scenario": "Frostbridge Guard activates tap target ability",
      "source_tapped": true,
      "target": "E2E Creature Target for Frostbridge Guard",
      "target_tapped": true
    },
    {
      "card_name": "Gavony Trapper",
      "scenario": "Gavony Trapper activates tap target ability",
      "source_tapped": true,
      "target": "E2E Creature Target for Gavony Trapper",
      "target_tapped": true
    },
    {
      "card_name": "Goldmeadow Harrier",
      "scenario": "Goldmeadow Harrier activates tap target ability",
      "source_tapped": true,
      "target": "E2E Creature Target for Goldmeadow Harrier",
      "target_tapped": true
    },
    {
      "card_name": "Nebelgast Beguiler",
      "scenario": "Nebelgast Beguiler activates tap target ability",
      "source_tapped": true,
      "target": "E2E Creature Target for Nebelgast Beguiler",
      "target_tapped": true
    },
    {
      "card_name": "Rathi Trapper",
      "scenario": "Rathi Trapper activates tap target ability",
      "source_tapped": true,
      "target": "E2E Creature Target for Rathi Trapper",
      "target_tapped": true
    },
    {
      "card_name": "Trip Noose",
      "scenario": "Trip Noose activates tap target ability",
      "source_tapped": true,
      "target": "E2E Creature Target for Trip Noose",
      "target_tapped": true
    },
    {
      "card_name": "Tyrant's Machine",
      "scenario": "Tyrant's Machine activates tap target ability",
      "source_tapped": true,
      "target": "E2E Creature Target for Tyrant's Machine",
      "target_tapped": true
    }
  ],
  "scenario_count": 13
}
```
