# Global Commander Candidate Package Strategy Matrix

- generated_at: `2026-07-06T06:37:18.517328+00:00`
- status: `package_strategy_blocks_battle`
- commander: `Lorehold, the Historian`
- deck_id: `612`
- profile_version: `None`
- battle_gate_allowed_now: `false`
- promotion_allowed: `false`
- blocker_count: `1`
- next_gate: `repair_commander_profile_blockers_before_battle`

## Target Evaluation

| Role | Base | Candidate | Delta | Target | Candidate Status |
| --- | ---: | ---: | ---: | --- | --- |

## Package Delta

| Action | Card | Profile Roles | Risk Flags |
| --- | --- | --- | --- |
| `add` | `Ash Barrens` | `lands, tutors_access` | `-` |
| `add` | `Sunbaked Canyon` | `card_draw_selection, lands` | `-` |
| `add` | `Battlefield Forge` | `lands` | `-` |
| `add` | `Cabaretti Courtyard` | `lands, tutors_access` | `-` |
| `add` | `Demolition Field` | `lands, spot_interaction, tutors_access` | `-` |
| `add` | `Escape Tunnel` | `lands, tutors_access` | `-` |
| `add` | `Evolving Wilds` | `lands, tutors_access` | `-` |
| `cut` | `Longshot, Rebel Bowman` | `board_wipes_resets, dedicated_win_conditions, mana_acceleration` | `mana_acceleration_cut` |
| `cut` | `Agate Instigator` | `board_wipes_resets, dedicated_win_conditions` | `-` |
| `cut` | `Warleader's Call` | `board_wipes_resets, dedicated_win_conditions` | `-` |
| `cut` | `Pyromancer's Goggles` | `mana_acceleration` | `mana_acceleration_cut` |
| `cut` | `Call Forth the Tempest` | `board_wipes_resets` | `-` |
| `cut` | `Ancient Gold Dragon` | `angels_demons_dragons_payoffs, dedicated_win_conditions` | `angel_demon_dragon_payoff_cut` |
| `cut` | `Birgi, God of Storytelling // Harnfel, Horn of Bounty` | `mana_acceleration` | `mana_acceleration_cut` |

## Blockers

- `commander_profile_not_available`

## Policy

- profile_gate: Commander-specific role targets and package risks are checked after generic core floors.
- battle_boundary: Only a strategy-ready package can open an equal battle probe; this matrix never promotes a deck.
- cut_boundary: Interaction upgrades cannot hide cuts that weaken the commander's attack window or source-lane plan.
