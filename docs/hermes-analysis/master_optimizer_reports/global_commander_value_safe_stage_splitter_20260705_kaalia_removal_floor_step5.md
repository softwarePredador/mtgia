# Global Commander Value-Safe Stage Splitter

- generated_at: `2026-07-05T20:25:23.309862+00:00`
- status: `commander_value_safe_stage_split_ready_for_stage_candidate_copy`
- commander: `Kaalia of the Vast`
- deck_id: `619`
- selected_add_count: `21`
- value_safe_cut_count: `18`
- paired_swap_count: `18`
- unpaired_add_count: `3`
- stage_count: `3`
- package_size_limit: `8`
- stage_candidate_copy_allowed_now: `true`
- full_package_candidate_copy_allowed_now: `false`
- battle_gate_allowed_now: `false`
- promotion_allowed: `false`
- next_gate: `materialize_value_safe_stage_1_candidate_copy`

## Blockers

- `full_package_unpaired_adds:required_21_paired_18`

## Stages

### Stage 1

- status: `stage_ready_for_candidate_copy`
- pair_count: `8`
- candidate_copy_allowed_now: `true`
- next_gate: `materialize_value_safe_stage_1_candidate_copy`

| Step | Add | Cut | Add Axis | Cut Role |
| ---: | --- | --- | --- | --- |
| 1 | `Arena of Glory` | `Archaeomancer's Map` | `commander_attack_window` | `tutors_access` |
| 2 | `Despark` | `Fable of the Mirror-Breaker // Reflection of Kiki-Jiki` | `spot_interaction` | `mana_acceleration` |
| 3 | `Anguished Unmaking` | `Smuggler's Share` | `spot_interaction` | `mana_acceleration` |
| 4 | `Balefire Dragon` | `Basalt Monolith` | `angels_demons_dragons_payoffs` | `mana_acceleration` |
| 5 | `Ancient Copper Dragon` | `Monologue Tax` | `angels_demons_dragons_payoffs` | `mana_acceleration` |
| 6 | `Angel of the Ruins` | `Grim Tutor` | `angels_demons_dragons_payoffs` | `tutors_access` |
| 7 | `Hoarding Broodlord` | `Necrodominance` | `angels_demons_dragons_payoffs` | `card_draw_selection` |
| 8 | `Goldlust Triad` | `Oswald Fiddlebender` | `angels_demons_dragons_payoffs` | `tutors_access` |

### Stage 2

- status: `stage_ready_for_candidate_copy`
- pair_count: `8`
- candidate_copy_allowed_now: `true`
- next_gate: `materialize_value_safe_stage_2_candidate_copy`

| Step | Add | Cut | Add Axis | Cut Role |
| ---: | --- | --- | --- | --- |
| 9 | `Hellkite Charger` | `Steelshaper's Gift` | `angels_demons_dragons_payoffs` | `tutors_access` |
| 10 | `Avacyn, Angel of Hope` | `Stoneforge Mystic` | `angels_demons_dragons_payoffs` | `tutors_access` |
| 11 | `Cavern-Hoard Dragon` | `Burnt Offering` | `angels_demons_dragons_payoffs` | `mana_acceleration` |
| 12 | `Goldspan Dragon` | `Culling the Weak` | `angels_demons_dragons_payoffs` | `mana_acceleration` |
| 13 | `Scourge of the Throne` | `Desperate Ritual` | `angels_demons_dragons_payoffs` | `mana_acceleration` |
| 14 | `Aurelia, the Law Above` | `Grim Monolith` | `angels_demons_dragons_payoffs` | `mana_acceleration` |
| 15 | `Starfield Shepherd` | `Infernal Plunge` | `angels_demons_dragons_payoffs` | `mana_acceleration` |
| 16 | `Dragon Mage` | `Trouble in Pairs` | `angels_demons_dragons_payoffs` | `card_draw_selection` |

### Stage 3

- status: `stage_ready_for_candidate_copy`
- pair_count: `2`
- candidate_copy_allowed_now: `true`
- next_gate: `materialize_value_safe_stage_3_candidate_copy`

| Step | Add | Cut | Add Axis | Cut Role |
| ---: | --- | --- | --- | --- |
| 17 | `Bonehoard Dracosaur` | `Imperial Seal` | `angels_demons_dragons_payoffs` | `tutors_access` |
| 18 | `Drakuseth, Maw of Flames` | `Wishclaw Talisman` | `angels_demons_dragons_payoffs` | `tutors_access` |

## Unpaired Adds

- `The Balrog of Moria`
- `Wrathful Red Dragon`
- `Akroma, Angel of Wrath`

## Policy

- stage_boundary: A ready stage authorizes only an isolated candidate-copy stage, not full package mutation.
- full_package_boundary: The full package remains blocked until every add has a value-safe cut.
- battle_boundary: No battle or promotion opens until a stage copy passes strategy matrix and replay gates.
