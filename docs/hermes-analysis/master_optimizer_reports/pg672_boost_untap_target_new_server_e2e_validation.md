# Battle Package End-to-End Validation

- Generated UTC: `2026-07-08T20:59:14.772515+00:00`
- Package ID: `pg672_boost_untap_target_new_server_package_manifest`
- Status: `pass`
- Database target: `127.0.0.1:15432/halder`
- SQLite DB: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db`
- Snapshot: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/manaloom-knowledge/scripts/known_cards_canonical_snapshot.json`

## Stage Results

| Stage | Status | Evidence |
| --- | --- | --- |
| postgres_source_of_truth | `pass` | `{"validated_rows": 10}` |
| sqlite_hermes_cache | `pass` | `{"validated_rows": 10}` |
| canonical_snapshot_fallback | `pass` | `{"validated_cards": 10}` |
| runtime_get_card_effect | `pass` | `{"validated_cards": 10}` |
| battle_execution | `pass` | `{"events": 20, "scenarios": 10}` |

## Battle Execution

```json
{
  "event_count": 20,
  "results": [
    {
      "card_name": "Fancy Footwork",
      "scenario": "Fancy Footwork boosts and untaps target creatures",
      "target_count": 2,
      "targets": [
        "E2E Legal Boost Untap Target 1",
        "E2E Legal Boost Untap Target 2"
      ],
      "targets_untapped_count": 2
    },
    {
      "card_name": "Gerrard's Command",
      "scenario": "Gerrard's Command boosts and untaps target creatures",
      "target_count": 1,
      "targets": [
        "E2E Legal Boost Untap Target 1"
      ],
      "targets_untapped_count": 1
    },
    {
      "card_name": "Hope and Glory",
      "scenario": "Hope and Glory boosts and untaps target creatures",
      "target_count": 2,
      "targets": [
        "E2E Legal Boost Untap Target 1",
        "E2E Legal Boost Untap Target 2"
      ],
      "targets_untapped_count": 2
    },
    {
      "card_name": "Inspirit",
      "scenario": "Inspirit boosts and untaps target creatures",
      "target_count": 1,
      "targets": [
        "E2E Legal Boost Untap Target 1"
      ],
      "targets_untapped_count": 1
    },
    {
      "card_name": "Join Forces",
      "scenario": "Join Forces boosts and untaps target creatures",
      "target_count": 2,
      "targets": [
        "E2E Legal Boost Untap Target 1",
        "E2E Legal Boost Untap Target 2"
      ],
      "targets_untapped_count": 2
    },
    {
      "card_name": "Ornamental Courage",
      "scenario": "Ornamental Courage boosts and untaps target creatures",
      "target_count": 1,
      "targets": [
        "E2E Legal Boost Untap Target 1"
      ],
      "targets_untapped_count": 1
    },
    {
      "card_name": "Refuse to Yield",
      "scenario": "Refuse to Yield boosts and untaps target creatures",
      "target_count": 1,
      "targets": [
        "E2E Legal Boost Untap Target 1"
      ],
      "targets_untapped_count": 1
    },
    {
      "card_name": "Savage Surge",
      "scenario": "Savage Surge boosts and untaps target creatures",
      "target_count": 1,
      "targets": [
        "E2E Legal Boost Untap Target 1"
      ],
      "targets_untapped_count": 1
    },
    {
      "card_name": "Synchronized Strike",
      "scenario": "Synchronized Strike boosts and untaps target creatures",
      "target_count": 2,
      "targets": [
        "E2E Legal Boost Untap Target 1",
        "E2E Legal Boost Untap Target 2"
      ],
      "targets_untapped_count": 2
    },
    {
      "card_name": "Veteran's Reflexes",
      "scenario": "Veteran's Reflexes boosts and untaps target creatures",
      "target_count": 1,
      "targets": [
        "E2E Legal Boost Untap Target 1"
      ],
      "targets_untapped_count": 1
    }
  ],
  "scenario_count": 10
}
```
