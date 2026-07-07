# Battle Package End-to-End Validation

- Generated UTC: `2026-07-07T22:06:01.050756+00:00`
- Package ID: `pg643_creature_source_prevention_new_server_manifest`
- Status: `pass`
- Database target: `127.0.0.1:15432/halder`
- SQLite DB: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db`
- Snapshot: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/manaloom-knowledge/scripts/known_cards_canonical_snapshot.json`

## Stage Results

| Stage | Status | Evidence |
| --- | --- | --- |
| postgres_source_of_truth | `pass` | `{"validated_rows": 5}` |
| sqlite_hermes_cache | `pass` | `{"validated_rows": 5}` |
| canonical_snapshot_fallback | `pass` | `{"validated_cards": 5}` |
| runtime_get_card_effect | `pass` | `{"validated_cards": 5}` |
| battle_execution | `pass` | `{"events": 22, "scenarios": 5}` |

## Battle Execution

```json
{
  "event_count": 22,
  "results": [
    {
      "card_name": "Ethereal Haze",
      "matching_damage_prevented": true,
      "matching_source": "E2E Matching Damage Source",
      "nonmatching_source": "E2E Nonmatching Damage Source",
      "prevent_damage_kind": "all_damage",
      "scenario": "Ethereal Haze prevents matching damage source"
    },
    {
      "card_name": "Harmless Assault",
      "matching_combat_damage_prevented": true,
      "matching_source": "E2E Matching Damage Source",
      "nonmatching_result": "blocking_damage_allowed",
      "nonmatching_source": "E2E Nonmatching Damage Source",
      "prevent_damage_kind": "combat_damage",
      "scenario": "Harmless Assault prevents matching damage source"
    },
    {
      "card_name": "Hunter's Ambush",
      "matching_combat_damage_prevented": true,
      "matching_source": "E2E Matching Damage Source",
      "nonmatching_result": "nonmatching_combat_damage_allowed",
      "nonmatching_source": "E2E Nonmatching Damage Source",
      "prevent_damage_kind": "combat_damage",
      "scenario": "Hunter's Ambush prevents matching damage source"
    },
    {
      "card_name": "Thwart the Enemy",
      "matching_damage_prevented": true,
      "matching_source": "E2E Matching Damage Source",
      "nonmatching_source": "E2E Nonmatching Damage Source",
      "prevent_damage_kind": "all_damage",
      "scenario": "Thwart the Enemy prevents matching damage source"
    },
    {
      "card_name": "Vine Snare",
      "matching_combat_damage_prevented": true,
      "matching_source": "E2E Matching Damage Source",
      "nonmatching_result": "nonmatching_combat_damage_allowed",
      "nonmatching_source": "E2E Nonmatching Damage Source",
      "prevent_damage_kind": "combat_damage",
      "scenario": "Vine Snare prevents matching damage source"
    }
  ],
  "scenario_count": 5
}
```
