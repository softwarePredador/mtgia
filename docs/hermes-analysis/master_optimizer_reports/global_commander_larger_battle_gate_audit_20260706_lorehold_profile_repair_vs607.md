# Global Commander Larger Battle Gate Audit

- generated_at: `2026-07-06T11:52:04.205713+00:00`
- status: `larger_battle_gate_blocks_promotion`
- commander: `Lorehold, the Historian`
- candidate_key: `candidate_profile_repair_package`
- protected_baseline_key: `deck_607`
- immediate_base_key: `deck_612`
- games_per_opponent: `3`
- opponent_count: `8`
- forced_access_mode: `none`
- promotion_allowed: `false`
- next_gate: `repair_package_or_convert_to_global_learning_no_promotion`

## Result

- protected baseline: `7W/17L/0S`, WR `29.17`
- immediate base: `2W/22L/0S`, WR `8.33`
- candidate: `4W/20L/0S`, WR `16.67`
- candidate_vs_protected_win_delta: `-3`
- candidate_vs_immediate_base_win_delta: `2`

## Added Cards

| Card | Status | Exercise | Accessed Games | Drawn Games | Events |
| --- | --- | ---: | ---: | ---: | --- |
| `Bant Panorama` | `larger_gate_added_card_exercised` | 5 | 7 | 2 | `{'land_played': 5}` |
| `Brokers Hideout` | `larger_gate_added_card_exercised` | 5 | 5 | 3 | `{'land_played': 5}` |
| `Pyromancer's Goggles` | `larger_gate_added_card_exercised` | 4 | 4 | 3 | `{'cost_paid': 2, 'spell_cast': 2}` |
| `Call Forth the Tempest` | `larger_gate_added_card_accessed_without_exercise` | 0 | 2 | 0 | `{}` |
| `Birgi, God of Storytelling // Harnfel, Horn of Bounty` | `larger_gate_added_card_exercised` | 13 | 3 | 2 | `{'cost_paid': 3, 'spell_cast': 3, 'trigger_resolved': 7}` |

## Blockers

- `candidate_did_not_beat_protected_baseline`
- `larger_gate_unexercised_added_cards:Call Forth the Tempest`

## Global Learning

- A package can repair a weaker base shell and still fail protected-baseline replacement.
- Natural replay access is necessary but not sufficient; the larger gate must also beat the protected baseline.
- Added cards without larger-gate exercise remain learning evidence, not promotion evidence.
