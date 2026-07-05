# Global Commander Candidate Package Chain Audit

- generated_at: `2026-07-05T21:02:09.243906+00:00`
- status: `pass`
- commander: `Kaalia of the Vast`
- deck_id: `619`
- swap_count: `21`
- materializer_chain_pass: `true`
- core_floor_repaired: `true`
- strategy_ready: `true`
- battle_gate_allowed_now: `false`
- promotion_allowed: `false`
- next_gate: `run_commander_specific_strategy_matrix_for_package_before_battle`

## Package Swaps

| Step | Add | Cut | Source Clean |
| ---: | --- | --- | --- |
| 1 | `Arena of Glory` | `Archaeomancer's Map` | `true` |
| 2 | `Despark` | `Fable of the Mirror-Breaker // Reflection of Kiki-Jiki` | `true` |
| 3 | `Anguished Unmaking` | `Smuggler's Share` | `true` |
| 4 | `Balefire Dragon` | `Basalt Monolith` | `true` |
| 5 | `Ancient Copper Dragon` | `Monologue Tax` | `true` |
| 6 | `Angel of the Ruins` | `Grim Tutor` | `true` |
| 7 | `Hoarding Broodlord` | `Necrodominance` | `true` |
| 8 | `Goldlust Triad` | `Oswald Fiddlebender` | `true` |
| 9 | `Path to Exile` | `Steelshaper's Gift` | `true` |
| 10 | `Swords to Plowshares` | `Stoneforge Mystic` | `true` |
| 11 | `Feed the Swarm` | `Lightning, Army of One` | `true` |
| 12 | `Damn` | `Burnt Offering` | `true` |
| 13 | `Terminate` | `Culling the Weak` | `true` |
| 14 | `Hellkite Charger` | `Desperate Ritual` | `true` |
| 15 | `Avacyn, Angel of Hope` | `Grim Monolith` | `true` |
| 16 | `Cavern-Hoard Dragon` | `Infernal Plunge` | `true` |
| 17 | `Goldspan Dragon` | `Pyretic Ritual` | `true` |
| 18 | `Scourge of the Throne` | `Strike It Rich` | `true` |
| 19 | `Aurelia, the Law Above` | `Imperial Seal` | `true` |
| 20 | `Starfield Shepherd` | `Wishclaw Talisman` | `true` |
| 21 | `Necromancy` | `Cabal Ritual` | `true` |

## Final Role Counts

- final_core_status: `core_review_ready`
- final_role_counts: `{"board_wipe": 4, "draw": 11, "engine": 39, "land": 35, "protection": 10, "ramp": 15, "recursion": 3, "removal": 8, "tutor": 13, "wincon": 6}`
- final_role_statuses: `{"board_wipe": "in_range", "draw": "in_range", "engine": "above_range_review", "land": "in_range", "protection": "in_range", "ramp": "in_range", "recursion": "in_range", "removal": "in_range", "tutor": "above_range_review", "wincon": "in_range"}`

## Blockers

- `commander_specific_strategy_matrix_not_run_for_package`
- `package_battle_probe_not_run`

## Policy

- package_scope: This is an isolated copied-DB package candidate, not a real deck change.
- battle_boundary: Core floor repair and global readiness do not authorize battle until a commander-specific package strategy matrix exists.
- promotion_boundary: Promotion remains closed until strategy matrix, equal battle gate, and replay trace pass.
