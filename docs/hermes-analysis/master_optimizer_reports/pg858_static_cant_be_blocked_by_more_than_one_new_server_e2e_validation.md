# Battle Package End-to-End Validation

- Generated UTC: `2026-07-13T02:42:32.380604+00:00`
- Package ID: `pg858_static_cant_be_blocked_by_more_than_one_new_server_package_manifest`
- Status: `pass`
- Database target: `127.0.0.1:15432/halder`
- SQLite DB: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db`
- Snapshot: `docs/hermes-analysis/master_optimizer_reports/pg858_static_cant_be_blocked_by_more_than_one_new_server_canonical_snapshot.json`

## Stage Results

| Stage | Status | Evidence |
| --- | --- | --- |
| postgres_source_of_truth | `pass` | `{"validated_rows": 6}` |
| sqlite_hermes_cache | `pass` | `{"validated_rows": 6}` |
| canonical_snapshot_fallback | `pass` | `{"validated_cards": 6}` |
| runtime_get_card_effect | `pass` | `{"validated_cards": 6}` |
| battle_execution | `pass` | `{"events": 6, "scenarios": 6}` |

## Battle Execution

```json
{
  "event_count": 6,
  "results": [
    {
      "blockers": [
        "E2E Large Blocker"
      ],
      "card_name": "Bristling Boar",
      "max_blockers": 1,
      "scenario": "Bristling Boar can be blocked by no more than one creature"
    },
    {
      "blockers": [
        "E2E Large Blocker"
      ],
      "card_name": "Charging Rhino",
      "max_blockers": 1,
      "scenario": "Charging Rhino can be blocked by no more than one creature"
    },
    {
      "blockers": [
        "E2E Large Blocker"
      ],
      "card_name": "Huang Zhong, Shu General",
      "max_blockers": 1,
      "scenario": "Huang Zhong, Shu General can be blocked by no more than one creature"
    },
    {
      "blockers": [
        "E2E Large Blocker"
      ],
      "card_name": "Ironhoof Ox",
      "max_blockers": 1,
      "scenario": "Ironhoof Ox can be blocked by no more than one creature"
    },
    {
      "blockers": [
        "E2E Large Blocker"
      ],
      "card_name": "Norwood Riders",
      "max_blockers": 1,
      "scenario": "Norwood Riders can be blocked by no more than one creature"
    },
    {
      "blockers": [
        "E2E Large Blocker"
      ],
      "card_name": "Stalking Tiger",
      "max_blockers": 1,
      "scenario": "Stalking Tiger can be blocked by no more than one creature"
    }
  ],
  "scenario_count": 6
}
```
