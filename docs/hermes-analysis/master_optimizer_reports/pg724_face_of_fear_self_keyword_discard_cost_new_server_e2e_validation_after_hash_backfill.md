# Battle Package End-to-End Validation

- Generated UTC: `2026-07-10T22:19:33.182358+00:00`
- Package ID: `pg724_face_of_fear_self_keyword_discard_cost_new_server_package_manifest`
- Status: `pass`
- Database target: `127.0.0.1:15432/halder`
- SQLite DB: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db`
- Snapshot: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/manaloom-knowledge/scripts/known_cards_canonical_snapshot.json`

## Stage Results

| Stage | Status | Evidence |
| --- | --- | --- |
| postgres_source_of_truth | `pass` | `{"validated_rows": 1}` |
| sqlite_hermes_cache | `pass` | `{"validated_rows": 1}` |
| canonical_snapshot_fallback | `pass` | `{"validated_cards": 1}` |
| runtime_get_card_effect | `pass` | `{"validated_cards": 1}` |
| battle_execution | `pass` | `{"events": 2, "scenarios": 1}` |

## Battle Execution

```json
{
  "event_count": 2,
  "results": [
    {
      "card_name": "Face of Fear",
      "discarded_count": 1,
      "granted_keywords": [
        "fear"
      ],
      "life_paid": 0,
      "scenario": "Face of Fear activates self keyword ability",
      "source_keywords": [
        "fear"
      ],
      "source_tapped": false
    }
  ],
  "scenario_count": 1
}
```
