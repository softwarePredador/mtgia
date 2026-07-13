# Battle Package End-to-End Validation

- Generated UTC: `2026-07-13T03:06:51.317250+00:00`
- Package ID: `pg859_becomes_blocked_draw_new_server_package_manifest`
- Status: `pass`
- Database target: `127.0.0.1:15432/halder`
- SQLite DB: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db`
- Snapshot: `docs/hermes-analysis/master_optimizer_reports/pg859_becomes_blocked_draw_new_server_canonical_snapshot.json`

## Stage Results

| Stage | Status | Evidence |
| --- | --- | --- |
| postgres_source_of_truth | `pass` | `{"validated_rows": 3}` |
| sqlite_hermes_cache | `pass` | `{"validated_rows": 3}` |
| canonical_snapshot_fallback | `pass` | `{"validated_cards": 3}` |
| runtime_get_card_effect | `pass` | `{"validated_cards": 3}` |
| battle_execution | `pass` | `{"events": 6, "scenarios": 3}` |

## Battle Execution

```json
{
  "event_count": 6,
  "results": [
    {
      "blocker_count": 1,
      "card_name": "Chambered Nautilus",
      "cards_drawn": 1,
      "hand_after": 1,
      "library_after": 0,
      "scenario": "Chambered Nautilus draws when blocked"
    },
    {
      "blocker_count": 1,
      "card_name": "Drelnoch",
      "cards_drawn": 2,
      "hand_after": 2,
      "library_after": 0,
      "scenario": "Drelnoch draws when blocked"
    },
    {
      "blocker_count": 1,
      "card_name": "Saprazzan Heir",
      "cards_drawn": 3,
      "hand_after": 3,
      "library_after": 0,
      "scenario": "Saprazzan Heir draws when blocked"
    }
  ],
  "scenario_count": 3
}
```
