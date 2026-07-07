# Battle Package End-to-End Validation

- Generated UTC: `2026-07-07T10:09:42.832205+00:00`
- Package ID: `xmage_pg608_destroy_gain_life_target_variants_new_server_manifest`
- Status: `pass`
- Database target: `127.0.0.1:15432/halder`
- SQLite DB: `docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db`
- Snapshot: `docs/hermes-analysis/master_optimizer_reports/xmage_pg608_destroy_gain_life_target_variants_new_server_known_cards_canonical_snapshot.json`

## Stage Results

| Stage | Status | Evidence |
| --- | --- | --- |
| postgres_source_of_truth | `pass` | `{"validated_rows": 10}` |
| sqlite_hermes_cache | `pass` | `{"validated_rows": 10}` |
| canonical_snapshot_fallback | `pass` | `{"validated_cards": 10}` |
| runtime_get_card_effect | `pass` | `{"validated_cards": 10}` |
| battle_execution | `pass` | `{"events": 30, "scenarios": 10}` |

## Battle Execution

```json
{
  "event_count": 30,
  "results": [
    {
      "battlefield_names": [
        "E2E Illegal Removal Target"
      ],
      "card_name": "Aerial Predation",
      "controller_life_after": 12,
      "controller_life_before": 10,
      "controller_life_gained": 2,
      "destination": "graveyard",
      "moved_names": [
        "E2E Legal Removal Target"
      ],
      "nonmatching_target": "E2E Illegal Removal Target",
      "scenario": "Aerial Predation removes one legal target",
      "target": "E2E Legal Removal Target"
    },
    {
      "battlefield_names": [
        "E2E Illegal Removal Target"
      ],
      "card_name": "Dark Offering",
      "controller_life_after": 13,
      "controller_life_before": 10,
      "controller_life_gained": 3,
      "destination": "graveyard",
      "moved_names": [
        "E2E Legal Removal Target"
      ],
      "nonmatching_target": "E2E Illegal Removal Target",
      "scenario": "Dark Offering removes one legal target",
      "target": "E2E Legal Removal Target"
    },
    {
      "battlefield_names": [
        "E2E Illegal Removal Target"
      ],
      "card_name": "Eriette's Lullaby",
      "controller_life_after": 12,
      "controller_life_before": 10,
      "controller_life_gained": 2,
      "destination": "graveyard",
      "moved_names": [
        "E2E Legal Removal Target"
      ],
      "nonmatching_target": "E2E Illegal Removal Target",
      "scenario": "Eriette's Lullaby removes one legal target",
      "target": "E2E Legal Removal Target"
    },
    {
      "battlefield_names": [
        "E2E Illegal Removal Target"
      ],
      "card_name": "Lucky Offering",
      "controller_life_after": 13,
      "controller_life_before": 10,
      "controller_life_gained": 3,
      "destination": "graveyard",
      "moved_names": [
        "E2E Legal Removal Target"
      ],
      "nonmatching_target": "E2E Illegal Removal Target",
      "scenario": "Lucky Offering removes one legal target",
      "target": "E2E Legal Removal Target"
    },
    {
      "battlefield_names": [
        "E2E Illegal Removal Target"
      ],
      "card_name": "Noxious Grasp",
      "controller_life_after": 11,
      "controller_life_before": 10,
      "controller_life_gained": 1,
      "destination": "graveyard",
      "moved_names": [
        "E2E Legal Removal Target"
      ],
      "nonmatching_target": "E2E Illegal Removal Target",
      "scenario": "Noxious Grasp removes one legal target",
      "target": "E2E Legal Removal Target"
    },
    {
      "battlefield_names": [
        "E2E Illegal Removal Target"
      ],
      "card_name": "Poison Arrow",
      "controller_life_after": 13,
      "controller_life_before": 10,
      "controller_life_gained": 3,
      "destination": "graveyard",
      "moved_names": [
        "E2E Legal Removal Target"
      ],
      "nonmatching_target": "E2E Illegal Removal Target",
      "scenario": "Poison Arrow removes one legal target",
      "target": "E2E Legal Removal Target"
    },
    {
      "battlefield_names": [
        "E2E Illegal Removal Target"
      ],
      "card_name": "Radiant Strike",
      "controller_life_after": 13,
      "controller_life_before": 10,
      "controller_life_gained": 3,
      "destination": "graveyard",
      "moved_names": [
        "E2E Legal Removal Target"
      ],
      "nonmatching_target": "E2E Illegal Removal Target",
      "scenario": "Radiant Strike removes one legal target",
      "target": "E2E Legal Removal Target"
    },
    {
      "battlefield_names": [
        "E2E Illegal Removal Target"
      ],
      "card_name": "Silverstrike",
      "controller_life_after": 13,
      "controller_life_before": 10,
      "controller_life_gained": 3,
      "destination": "graveyard",
      "moved_names": [
        "E2E Legal Removal Target"
      ],
      "nonmatching_target": "E2E Illegal Removal Target",
      "scenario": "Silverstrike removes one legal target",
      "target": "E2E Legal Removal Target"
    },
    {
      "battlefield_names": [
        "E2E Illegal Removal Target"
      ],
      "card_name": "Surge of Righteousness",
      "controller_life_after": 12,
      "controller_life_before": 10,
      "controller_life_gained": 2,
      "destination": "graveyard",
      "moved_names": [
        "E2E Legal Removal Target"
      ],
      "nonmatching_target": "E2E Illegal Removal Target",
      "scenario": "Surge of Righteousness removes one legal target",
      "target": "E2E Legal Removal Target"
    },
    {
      "battlefield_names": [
        "E2E Illegal Removal Target"
      ],
      "card_name": "Triumphant Surge",
      "controller_life_after": 13,
      "controller_life_before": 10,
      "controller_life_gained": 3,
      "destination": "graveyard",
      "moved_names": [
        "E2E Legal Removal Target"
      ],
      "nonmatching_target": "E2E Illegal Removal Target",
      "scenario": "Triumphant Surge removes one legal target",
      "target": "E2E Legal Removal Target"
    }
  ],
  "scenario_count": 10
}
```
