# Battle Package End-to-End Validation

- Generated UTC: `2026-07-09T06:29:14.086238+00:00`
- Package ID: `pg695_boost_keyword_untap_new_server_package_manifest`
- Status: `pass`
- Database target: `127.0.0.1:15432/halder`
- SQLite DB: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db`
- Snapshot: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/manaloom-knowledge/scripts/known_cards_canonical_snapshot.json`

## Stage Results

| Stage | Status | Evidence |
| --- | --- | --- |
| postgres_source_of_truth | `pass` | `{"validated_rows": 16}` |
| sqlite_hermes_cache | `pass` | `{"validated_rows": 16}` |
| canonical_snapshot_fallback | `pass` | `{"validated_cards": 16}` |
| runtime_get_card_effect | `pass` | `{"validated_cards": 16}` |
| battle_execution | `pass` | `{"events": 32, "scenarios": 16}` |

## Battle Execution

```json
{
  "event_count": 32,
  "results": [
    {
      "card_name": "Acrobatic Leap",
      "granted_keywords": [
        "flying"
      ],
      "scenario": "Acrobatic Leap boosts and untaps target creatures",
      "target_count": 1,
      "targets": [
        "E2E Legal Boost Untap Target 1"
      ],
      "targets_untapped_count": 1
    },
    {
      "card_name": "Aim High",
      "granted_keywords": [
        "reach"
      ],
      "scenario": "Aim High boosts and untaps target creatures",
      "target_count": 1,
      "targets": [
        "E2E Legal Boost Untap Target 1"
      ],
      "targets_untapped_count": 1
    },
    {
      "card_name": "Arachnoid Adaptation",
      "granted_keywords": [
        "reach"
      ],
      "scenario": "Arachnoid Adaptation boosts and untaps target creatures",
      "target_count": 1,
      "targets": [
        "E2E Legal Boost Untap Target 1"
      ],
      "targets_untapped_count": 1
    },
    {
      "card_name": "Bull's Strength",
      "granted_keywords": [
        "trample"
      ],
      "scenario": "Bull's Strength boosts and untaps target creatures",
      "target_count": 1,
      "targets": [
        "E2E Legal Boost Untap Target 1"
      ],
      "targets_untapped_count": 1
    },
    {
      "card_name": "Escape from Orthanc",
      "granted_keywords": [
        "flying"
      ],
      "scenario": "Escape from Orthanc boosts and untaps target creatures",
      "target_count": 1,
      "targets": [
        "E2E Legal Boost Untap Target 1"
      ],
      "targets_untapped_count": 1
    },
    {
      "card_name": "High Stride",
      "granted_keywords": [
        "reach"
      ],
      "scenario": "High Stride boosts and untaps target creatures",
      "target_count": 1,
      "targets": [
        "E2E Legal Boost Untap Target 1"
      ],
      "targets_untapped_count": 1
    },
    {
      "card_name": "Leaping Ambush",
      "granted_keywords": [
        "reach"
      ],
      "scenario": "Leaping Ambush boosts and untaps target creatures",
      "target_count": 1,
      "targets": [
        "E2E Legal Boost Untap Target 1"
      ],
      "targets_untapped_count": 1
    },
    {
      "card_name": "Magic Damper",
      "granted_keywords": [
        "hexproof"
      ],
      "scenario": "Magic Damper boosts and untaps target creatures",
      "target_count": 1,
      "targets": [
        "E2E Legal Boost Untap Target 1"
      ],
      "targets_untapped_count": 1
    },
    {
      "card_name": "Octopus Form",
      "granted_keywords": [
        "hexproof"
      ],
      "scenario": "Octopus Form boosts and untaps target creatures",
      "target_count": 1,
      "targets": [
        "E2E Legal Boost Untap Target 1"
      ],
      "targets_untapped_count": 1
    },
    {
      "card_name": "Pillar Launch",
      "granted_keywords": [
        "reach"
      ],
      "scenario": "Pillar Launch boosts and untaps target creatures",
      "target_count": 1,
      "targets": [
        "E2E Legal Boost Untap Target 1"
      ],
      "targets_untapped_count": 1
    },
    {
      "card_name": "Riverguard's Reflexes",
      "granted_keywords": [
        "first_strike"
      ],
      "scenario": "Riverguard's Reflexes boosts and untaps target creatures",
      "target_count": 1,
      "targets": [
        "E2E Legal Boost Untap Target 1"
      ],
      "targets_untapped_count": 1
    },
    {
      "card_name": "Spidery Grasp",
      "granted_keywords": [
        "reach"
      ],
      "scenario": "Spidery Grasp boosts and untaps target creatures",
      "target_count": 1,
      "targets": [
        "E2E Legal Boost Untap Target 1"
      ],
      "targets_untapped_count": 1
    },
    {
      "card_name": "Steady Aim",
      "granted_keywords": [
        "reach"
      ],
      "scenario": "Steady Aim boosts and untaps target creatures",
      "target_count": 1,
      "targets": [
        "E2E Legal Boost Untap Target 1"
      ],
      "targets_untapped_count": 1
    },
    {
      "card_name": "Vines of the Recluse",
      "granted_keywords": [
        "reach"
      ],
      "scenario": "Vines of the Recluse boosts and untaps target creatures",
      "target_count": 1,
      "targets": [
        "E2E Legal Boost Untap Target 1"
      ],
      "targets_untapped_count": 1
    },
    {
      "card_name": "Wings of the Cosmos",
      "granted_keywords": [
        "flying"
      ],
      "scenario": "Wings of the Cosmos boosts and untaps target creatures",
      "target_count": 1,
      "targets": [
        "E2E Legal Boost Untap Target 1"
      ],
      "targets_untapped_count": 1
    },
    {
      "card_name": "Witch's Web",
      "granted_keywords": [
        "reach"
      ],
      "scenario": "Witch's Web boosts and untaps target creatures",
      "target_count": 1,
      "targets": [
        "E2E Legal Boost Untap Target 1"
      ],
      "targets_untapped_count": 1
    }
  ],
  "scenario_count": 16
}
```
