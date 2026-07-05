# Battle Package End-to-End Validation

- Generated UTC: `2026-07-05T02:03:48.200983+00:00`
- Package ID: `pg470_xmage_creature_etb_dynamic_graveyard_damage_new_server_manifest`
- Status: `pass`
- Database target: `143.198.230.247:5433/halder`
- SQLite DB: `knowledge.db`
- Snapshot: `known_cards_canonical_snapshot.json`

## Stage Results

| Stage | Status | Evidence |
| --- | --- | --- |
| postgres_source_of_truth | `pass` | `{"validated_rows": 4}` |
| sqlite_hermes_cache | `pass` | `{"validated_rows": 4}` |
| canonical_snapshot_fallback | `pass` | `{"validated_cards": 4}` |
| runtime_get_card_effect | `pass` | `{"validated_cards": 4}` |
| battle_execution_no_override | `pass` | `{"events": 0, "scenarios": 0}` |

## Battle Execution

```json
{
  "event_count": 0,
  "results": [],
  "scenario_count": 0
}
```
