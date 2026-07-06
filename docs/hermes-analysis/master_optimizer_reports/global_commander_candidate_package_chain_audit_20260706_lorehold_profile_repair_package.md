# Global Commander Candidate Package Chain Audit

- generated_at: `2026-07-06T07:19:04.846832+00:00`
- status: `pass`
- commander: `Lorehold, the Historian`
- deck_id: `612`
- swap_count: `5`
- materializer_chain_pass: `true`
- core_floor_repaired: `true`
- strategy_ready: `true`
- battle_gate_allowed_now: `false`
- promotion_allowed: `false`
- next_gate: `run_commander_specific_strategy_matrix_for_package_before_battle`

## Package Swaps

| Step | Add | Cut | Source Clean |
| ---: | --- | --- | --- |
| 1 | `Bant Panorama` | `Storm-Kiln Artist` | `true` |
| 2 | `Brokers Hideout` | `Jeska's Will` | `true` |
| 3 | `Pyromancer's Goggles` | `Artist's Talent` | `true` |
| 4 | `Call Forth the Tempest` | `Starfall Invocation` | `true` |
| 5 | `Birgi, God of Storytelling // Harnfel, Horn of Bounty` | `Brass's Bounty` | `true` |

## Final Role Counts

- final_core_status: `core_review_ready`
- final_role_counts: `{"board_wipe": 8, "draw": 9, "engine": 41, "land": 36, "protection": 10, "ramp": 19, "recursion": 8, "removal": 9, "tutor": 2, "wincon": 12}`
- final_role_statuses: `{"board_wipe": "above_range_review", "draw": "in_range", "engine": "above_range_review", "land": "in_range", "protection": "in_range", "ramp": "above_range_review", "recursion": "in_range", "removal": "in_range", "tutor": "in_range", "wincon": "in_range"}`

## Blockers

- `commander_specific_strategy_matrix_not_run_for_package`
- `package_battle_probe_not_run`

## Policy

- package_scope: This is an isolated copied-DB package candidate, not a real deck change.
- battle_boundary: Core floor repair and global readiness do not authorize battle until a commander-specific package strategy matrix exists.
- promotion_boundary: Promotion remains closed until strategy matrix, equal battle gate, and replay trace pass.
