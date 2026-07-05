# Global Commander Candidate Package Strategy Matrix

- generated_at: `2026-07-05T21:02:19.492883+00:00`
- status: `package_strategy_blocks_battle`
- commander: `Kaalia of the Vast`
- deck_id: `619`
- profile_version: `kaalia_of_the_vast_reference_profile_v1_2026-07-05`
- battle_gate_allowed_now: `false`
- promotion_allowed: `false`
- blocker_count: `1`
- next_gate: `repair_commander_profile_blockers_before_battle`

## Target Evaluation

| Role | Base | Candidate | Delta | Target | Candidate Status |
| --- | ---: | ---: | ---: | --- | --- |
| `lands` | 34 | 35 | 1 | `35-37` | `in_range` |
| `mana_acceleration` | 24 | 15 | -9 | `10-14` | `above_target_review` |
| `haste_protection_silence` | 10 | 16 | 6 | `8-12` | `above_target_review` |
| `angels_demons_dragons_payoffs` | 4 | 16 | 12 | `22-30` | `below_target` |
| `spot_interaction` | 1 | 8 | 7 | `8-12` | `in_range` |
| `board_wipes_resets` | 2 | 4 | 2 | `2-4` | `in_range` |
| `card_draw_selection` | 13 | 11 | -2 | `7-11` | `in_range` |
| `tutors_access` | 20 | 16 | -4 | `4-8` | `above_target_review` |
| `reanimation_plan_b` | 3 | 3 | 0 | `3-6` | `in_range` |
| `dedicated_win_conditions` | 6 | 6 | 0 | `3-6` | `in_range` |

## Package Delta

| Action | Card | Profile Roles | Risk Flags |
| --- | --- | --- | --- |
| `add` | `Arena of Glory` | `haste_protection_silence, lands` | `-` |
| `add` | `Despark` | `spot_interaction` | `-` |
| `add` | `Anguished Unmaking` | `spot_interaction` | `-` |
| `add` | `Balefire Dragon` | `angels_demons_dragons_payoffs, board_wipes_resets, dedicated_win_conditions` | `-` |
| `add` | `Ancient Copper Dragon` | `angels_demons_dragons_payoffs, mana_acceleration` | `-` |
| `add` | `Angel of the Ruins` | `angels_demons_dragons_payoffs, tutors_access` | `-` |
| `add` | `Hoarding Broodlord` | `angels_demons_dragons_payoffs, tutors_access` | `-` |
| `add` | `Goldlust Triad` | `angels_demons_dragons_payoffs, mana_acceleration` | `-` |
| `add` | `Path to Exile` | `spot_interaction` | `-` |
| `add` | `Swords to Plowshares` | `spot_interaction` | `-` |
| `add` | `Feed the Swarm` | `spot_interaction` | `-` |
| `add` | `Damn` | `spot_interaction` | `-` |
| `add` | `Terminate` | `spot_interaction` | `-` |
| `add` | `Hellkite Charger` | `angels_demons_dragons_payoffs, haste_protection_silence` | `-` |
| `add` | `Avacyn, Angel of Hope` | `angels_demons_dragons_payoffs, haste_protection_silence` | `-` |
| `add` | `Cavern-Hoard Dragon` | `angels_demons_dragons_payoffs, haste_protection_silence, mana_acceleration` | `-` |
| `add` | `Goldspan Dragon` | `angels_demons_dragons_payoffs, haste_protection_silence, mana_acceleration` | `-` |
| `add` | `Scourge of the Throne` | `angels_demons_dragons_payoffs` | `-` |
| `add` | `Aurelia, the Law Above` | `angels_demons_dragons_payoffs, board_wipes_resets, card_draw_selection, haste_protection_silence` | `-` |
| `add` | `Starfield Shepherd` | `angels_demons_dragons_payoffs, tutors_access` | `-` |
| `add` | `Necromancy` | `reanimation_plan_b` | `-` |
| `cut` | `Archaeomancer's Map` | `mana_acceleration, tutors_access` | `mana_acceleration_cut, tutor_access_cut` |
| `cut` | `Fable of the Mirror-Breaker // Reflection of Kiki-Jiki` | `card_draw_selection, mana_acceleration` | `mana_acceleration_cut, card_flow_cut` |
| `cut` | `Smuggler's Share` | `card_draw_selection, mana_acceleration` | `mana_acceleration_cut, card_flow_cut` |
| `cut` | `Basalt Monolith` | `mana_acceleration` | `mana_acceleration_cut` |
| `cut` | `Monologue Tax` | `mana_acceleration` | `mana_acceleration_cut` |
| `cut` | `Grim Tutor` | `tutors_access` | `tutor_access_cut` |
| `cut` | `Necrodominance` | `card_draw_selection` | `card_flow_cut` |
| `cut` | `Oswald Fiddlebender` | `tutors_access` | `tutor_access_cut` |
| `cut` | `Steelshaper's Gift` | `tutors_access` | `tutor_access_cut` |
| `cut` | `Stoneforge Mystic` | `tutors_access` | `tutor_access_cut` |
| `cut` | `Lightning, Army of One` | `dedicated_win_conditions` | `-` |
| `cut` | `Burnt Offering` | `mana_acceleration` | `mana_acceleration_cut` |
| `cut` | `Culling the Weak` | `mana_acceleration` | `mana_acceleration_cut` |
| `cut` | `Desperate Ritual` | `mana_acceleration` | `mana_acceleration_cut` |
| `cut` | `Grim Monolith` | `mana_acceleration` | `mana_acceleration_cut` |
| `cut` | `Infernal Plunge` | `mana_acceleration` | `mana_acceleration_cut` |
| `cut` | `Pyretic Ritual` | `mana_acceleration` | `mana_acceleration_cut` |
| `cut` | `Strike It Rich` | `mana_acceleration, reanimation_plan_b` | `mana_acceleration_cut` |
| `cut` | `Imperial Seal` | `tutors_access` | `tutor_access_cut` |
| `cut` | `Wishclaw Talisman` | `tutors_access` | `tutor_access_cut` |
| `cut` | `Cabal Ritual` | `mana_acceleration` | `mana_acceleration_cut` |

## Blockers

- `profile_angels_demons_dragons_payoffs_below_target`

## Policy

- profile_gate: Commander-specific role targets and package risks are checked after generic core floors.
- battle_boundary: Only a strategy-ready package can open an equal battle probe; this matrix never promotes a deck.
- cut_boundary: Interaction upgrades cannot hide cuts that weaken the commander's attack window or source-lane plan.
