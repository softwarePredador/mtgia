# Global Commander Larger Battle Gate Audit

- generated_at: `2026-07-06T12:39:04.739484+00:00`
- status: `larger_battle_gate_blocks_promotion`
- commander: `Lorehold, the Historian`
- candidate_key: `candidate_land_floor_profile_repair`
- protected_baseline_key: `deck_607`
- immediate_base_key: `deck_612`
- games_per_opponent: `3`
- opponent_count: `8`
- forced_access_mode: `none`
- promotion_allowed: `false`
- next_gate: `repair_package_or_convert_to_global_learning_no_promotion`

## Result

- protected baseline: `14W/9L/1S`, WR `58.33`
- immediate base: `7W/17L/0S`, WR `29.17`
- candidate: `8W/16L/0S`, WR `33.33`
- candidate_vs_protected_win_delta: `-6`
- candidate_vs_immediate_base_win_delta: `1`

## Added Cards

| Card | Status | Exercise | Accessed Games | Drawn Games | Events |
| --- | --- | ---: | ---: | ---: | --- |
| `Ash Barrens` | `larger_gate_added_card_exercised` | 4 | 6 | 3 | `{'land_played': 4}` |
| `Bant Panorama` | `larger_gate_added_card_exercised` | 2 | 3 | 1 | `{'land_played': 2}` |
| `Battlefield Forge` | `larger_gate_added_card_exercised` | 4 | 5 | 4 | `{'land_played': 4}` |
| `Brokers Hideout` | `larger_gate_added_card_exercised` | 5 | 6 | 1 | `{'land_played': 5}` |
| `Cabaretti Courtyard` | `larger_gate_added_card_exercised` | 3 | 5 | 3 | `{'land_played': 3}` |
| `Demolition Field` | `larger_gate_added_card_exercised` | 3 | 5 | 2 | `{'land_played': 3}` |
| `Escape Tunnel` | `larger_gate_added_card_exercised` | 6 | 8 | 3 | `{'land_played': 6}` |
| `Evolving Wilds` | `larger_gate_added_card_exercised` | 6 | 7 | 4 | `{'land_played': 6}` |
| `Sunbaked Canyon` | `larger_gate_added_card_exercised` | 9 | 7 | 3 | `{'land_played': 7, 'utility_land_activated': 2}` |

## Blockers

- `candidate_did_not_beat_protected_baseline`

## Global Learning

- A package can repair a weaker base shell and still fail protected-baseline replacement.
- Natural replay access is necessary but not sufficient; the larger gate must also beat the protected baseline.
- Added cards without larger-gate exercise remain learning evidence, not promotion evidence.
