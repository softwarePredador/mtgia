# Battle Package End-to-End Validation

- Generated UTC: `2026-07-12T23:07:09.733970+00:00`
- Package ID: `pg850_graveyard_self_exile_activate_as_sorcery_token_new_server_package_manifest`
- Status: `pass`
- Database target: `127.0.0.1:15432/halder`
- SQLite DB: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db`
- Snapshot: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/manaloom-knowledge/scripts/known_cards_canonical_snapshot.json`

## Stage Results

| Stage | Status | Evidence |
| --- | --- | --- |
| postgres_source_of_truth | `pass` | `{"validated_rows": 7}` |
| sqlite_hermes_cache | `pass` | `{"validated_rows": 7}` |
| canonical_snapshot_fallback | `pass` | `{"validated_cards": 7}` |
| runtime_get_card_effect | `pass` | `{"validated_cards": 7}` |
| battle_execution | `pass` | `{"events": 7, "scenarios": 7}` |

## Battle Execution

```json
{
  "event_count": 7,
  "results": [
    {
      "card_name": "Dauntless Cathar",
      "discard_target": null,
      "discarded_count": 0,
      "exiled_source_from_graveyard": true,
      "scenario": "Dauntless Cathar activates token ability",
      "token_name": "Spirit Token",
      "tokens_created": 1
    },
    {
      "card_name": "Fairgrounds Patrol",
      "discard_target": null,
      "discarded_count": 0,
      "exiled_source_from_graveyard": true,
      "scenario": "Fairgrounds Patrol activates token ability",
      "token_name": "Thopter Token",
      "tokens_created": 1
    },
    {
      "card_name": "Ghoulcaller's Accomplice",
      "discard_target": null,
      "discarded_count": 0,
      "exiled_source_from_graveyard": true,
      "scenario": "Ghoulcaller's Accomplice activates token ability",
      "token_name": "Zombie Token",
      "tokens_created": 1
    },
    {
      "card_name": "Goldmeadow Nomad",
      "discard_target": null,
      "discarded_count": 0,
      "exiled_source_from_graveyard": true,
      "scenario": "Goldmeadow Nomad activates token ability",
      "token_name": "Kithkin Token",
      "tokens_created": 1
    },
    {
      "card_name": "Mother Bear",
      "discard_target": null,
      "discarded_count": 0,
      "exiled_source_from_graveyard": true,
      "scenario": "Mother Bear activates token ability",
      "token_name": "Bear Token",
      "tokens_created": 2
    },
    {
      "card_name": "Stoic Grove-Guide",
      "discard_target": null,
      "discarded_count": 0,
      "exiled_source_from_graveyard": true,
      "scenario": "Stoic Grove-Guide activates token ability",
      "token_name": "Elf Token",
      "tokens_created": 1
    },
    {
      "card_name": "Suspicious Shambler",
      "discard_target": null,
      "discarded_count": 0,
      "exiled_source_from_graveyard": true,
      "scenario": "Suspicious Shambler activates token ability",
      "token_name": "Zombie Token",
      "tokens_created": 2
    }
  ],
  "scenario_count": 7
}
```
