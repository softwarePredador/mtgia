# Battle Package End-to-End Validation

- Generated UTC: `2026-07-12T06:31:47.272777+00:00`
- Package ID: `pg810_bounce_draw_aux_new_server_manifest`
- Status: `pass`
- Database target: `127.0.0.1:15432/halder`
- SQLite DB: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db`
- Snapshot: `docs/hermes-analysis/master_optimizer_reports/pg810b_trusted_rule_oracle_hash_backfill_new_server_canonical_fallback.json`

## Stage Results

| Stage | Status | Evidence |
| --- | --- | --- |
| postgres_source_of_truth | `pass` | `{"validated_rows": 2}` |
| sqlite_hermes_cache | `pass` | `{"validated_rows": 2}` |
| canonical_snapshot_fallback | `pass` | `{"validated_cards": 2}` |
| runtime_get_card_effect | `pass` | `{"validated_cards": 2}` |
| battle_execution | `pass` | `{"events": 12, "scenarios": 2}` |

## Battle Execution

```json
{
  "event_count": 12,
  "results": [
    {
      "card_name": "Eject",
      "cards_drawn": 1,
      "destination": "hand",
      "hand": [
        "E2E Draw Card 1"
      ],
      "moved_names": [
        "E2E Legal Removal Target"
      ],
      "nonmatching_target": "E2E Illegal Removal Target",
      "scenario": "Eject removes one legal target and draws 1",
      "target": "E2E Legal Removal Target"
    },
    {
      "card_name": "Escape Detection",
      "cards_drawn": 1,
      "destination": "hand",
      "hand": [
        "E2E Draw Card 1"
      ],
      "moved_names": [
        "E2E Legal Removal Target"
      ],
      "nonmatching_target": "E2E Illegal Removal Target",
      "scenario": "Escape Detection removes one legal target and draws 1",
      "target": "E2E Legal Removal Target"
    }
  ],
  "scenario_count": 2
}
```
