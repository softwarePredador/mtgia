# Lorehold Mana Sequence Policy Synthesis

- generated_at: `2026-07-05T02:58:53Z`
- deck_id: `607`
- status: `mana_sequence_no_direct_auto_upgrade_current_607`
- postgres_writes: `false`
- source_db_mutated: `false`

## Summary

- lands: `34`
- ramp: `15`
- early foundation pieces: `8`
- true early mana pieces: `6`
- red sources: `24`
- white sources: `25`
- colorless-only lands: `5`
- tapped land pressure count: `4`
- mana foundation status: `mana_foundation_pass_with_watch_items`
- candidate decision counts: `{"already_in_607_mana_package": 13, "already_in_607_protected_mana_foundation": 13, "already_in_607_protected_turn_cycle_miracle_mana": 2, "blocked_commander_banned_or_not_accessible": 2, "blocked_prior_exact_reject": 2, "blocked_prior_gate_rejected": 1, "candidate_fast_mana_requires_fixing_and_use_gate": 1, "candidate_hypothesis_requires_named_cut_and_equal_gate": 1, "candidate_land_requires_named_land_cut_and_equal_gate": 2, "candidate_land_upgrade_requires_current_land_cut": 4, "candidate_requires_same_lane_cut_and_gate": 1, "candidate_requires_same_lane_cut_and_sequence_gate": 2, "candidate_spell_ramp_requires_spell_slot_gate": 2, "policy_blocked_no_premium_mox": 4}`

## Mana Sequence Policy

- commander_turn_target: `cast Lorehold on or before turn 5 while preserving RW access`
- post_commander_target: `keep mana available across opponents' turns for first-draw miracle windows`
- protected: do not cut turn-cycle miracle mana as if it were a generic three-mana rock
- protected: do not cut colored/fetchable sources for colorless burst without equal-gate proof
- protected: do not treat rituals or treasures as opening fixing
- protected: do not promote a land by prestige unless a current land cut is named

## Current Mana Package

| Card | Lane | Policy | CMC | Colors | Roles |
| --- | --- | --- | ---: | --- | --- |
| Arid Mesa | `colored_land_fixing` | `current_fixing_floor` | 0 | R, W | fetch_or_basic_access, life_cost |
| Battlefield Forge | `colored_land_fixing` | `current_fixing_floor` | 0 | C, R, W | - |
| Bloodstained Mire | `colored_land_fixing` | `current_fixing_floor` | 0 | R, W | fetch_or_basic_access, life_cost |
| Command Tower | `colored_land_fixing` | `current_fixing_floor` | 0 | R, W | - |
| Eiganjo, Seat of the Empire | `colored_land_fixing` | `current_fixing_floor` | 0 | W | - |
| Elegant Parlor | `colored_land_fixing` | `current_fixing_floor` | 0 | R, W | topdeck_or_graveyard_selection |
| Exotic Orchard | `colored_land_fixing` | `current_fixing_floor` | 0 | R, W | - |
| Flooded Strand | `colored_land_fixing` | `current_fixing_floor` | 0 | R, W | fetch_or_basic_access, life_cost |
| Glittering Massif | `colored_land_fixing` | `current_fixing_floor` | 0 | R, W | cycling_flood_escape, land_card_flow |
| Marsh Flats | `colored_land_fixing` | `current_fixing_floor` | 0 | R, W | fetch_or_basic_access, life_cost |
| Mountain // Mountain | `colored_land_fixing` | `current_fixing_floor` | 0 | R | basic_count_for_land_tax |
| Plains // Plains | `colored_land_fixing` | `current_fixing_floor` | 0 | W | basic_count_for_land_tax |
| Plaza of Heroes | `colored_land_fixing` | `current_fixing_floor` | 0 | C, R, W | legendary_protection |
| Prismatic Vista | `colored_land_fixing` | `current_fixing_floor` | 0 | R, W | fetch_or_basic_access, life_cost |
| Radiant Summit | `colored_land_fixing` | `current_fixing_floor` | 0 | R, W | - |
| Sacred Foundry | `colored_land_fixing` | `current_fixing_floor` | 0 | R, W | - |
| Scalding Tarn | `colored_land_fixing` | `current_fixing_floor` | 0 | R, W | fetch_or_basic_access, life_cost |
| Spectator Seating | `colored_land_fixing` | `current_fixing_floor` | 0 | R, W | - |
| Sunbaked Canyon | `colored_land_fixing` | `current_fixing_floor` | 0 | R, W | land_card_flow, life_cost |
| Sunbillow Verge | `colored_land_fixing` | `current_fixing_floor` | 0 | R, W | - |
| Turbulent Steppe | `colored_land_fixing` | `current_fixing_floor` | 0 | R, W | - |
| Windswept Heath | `colored_land_fixing` | `current_fixing_floor` | 0 | R, W | fetch_or_basic_access, life_cost |
| Wooded Foothills | `colored_land_fixing` | `current_fixing_floor` | 0 | R, W | fetch_or_basic_access, life_cost |
| Pearl Medallion | `cost_reducer` | `protected_current_mana_foundation` | 2 | - | early_cost_reducer |
| Ruby Medallion | `cost_reducer` | `protected_current_mana_foundation` | 2 | - | early_cost_reducer |
| Land Tax | `early_colored_rock` | `protected_current_mana_foundation` | 1 | R, W | - |
| Arcane Signet | `early_colored_rock` | `protected_current_mana_foundation` | 2 | R, W | early_recurring_colored_mana |
| Boros Signet | `early_colored_rock` | `protected_current_mana_foundation` | 2 | R, W | early_recurring_colored_mana |
| Fellwar Stone | `early_colored_rock` | `protected_current_mana_foundation` | 2 | R, W | early_recurring_colored_mana |
| Talisman of Conviction | `early_colored_rock` | `protected_current_mana_foundation` | 2 | C, R, W | early_recurring_colored_mana |
| The Mind Stone | `early_colored_rock` | `protected_current_mana_foundation` | 2 | W | early_recurring_colored_mana |
| Sol Ring | `early_colorless_burst` | `protected_current_mana_foundation` | 1 | C | early_colorless_acceleration |
| Ancient Tomb | `fast_or_utility_land` | `protected_current_mana_foundation` | 0 | C | fast_colorless_acceleration, life_cost |
| Jeska's Will | `ritual_or_spell_burst` | `protected_current_mana_foundation` | 3 | R | burst_or_treasure_ramp |
| Monument to Endurance | `treasure_or_discard_ramp` | `protected_current_mana_foundation` | 3 | R, W | burst_or_treasure_ramp |
| Big Score | `treasure_or_discard_ramp` | `current_mana_role_card` | 4 | R, W | burst_or_treasure_ramp |
| Smothering Tithe | `treasure_or_discard_ramp` | `protected_current_mana_foundation` | 4 | R, W | table_tax_treasure_engine |
| Unexpected Windfall | `treasure_or_discard_ramp` | `protected_current_mana_foundation` | 4 | R, W | burst_or_treasure_ramp |
| Bender's Waterskin | `turn_cycle_miracle_mana` | `protected_turn_cycle_miracle_mana` | 3 | R, W | turn_cycle_miracle_mana |
| Victory Chimes | `turn_cycle_miracle_mana` | `protected_turn_cycle_miracle_mana` | 3 | C | turn_cycle_miracle_mana |
| Command Beacon | `utility_land` | `current_utility_land_watch` | 0 | C | commander_recast_recovery |
| Reliquary Tower | `utility_land` | `current_utility_land_watch` | 0 | C | no_max_hand_size |
| Urza's Saga | `utility_land` | `protected_current_mana_foundation` | 0 | C | artifact_tutor_land |
| War Room | `utility_land` | `current_utility_land_watch` | 0 | C | land_card_flow |

## Candidate Mana Backlog

| Card | Lane | In 607 | Rank | Decision | Reasons |
| --- | --- | --- | ---: | --- | --- |
| Flooded Strand | `colored_land_fixing` | `true` | 42 | `already_in_607_mana_package` | current_607_card |
| Bloodstained Mire | `colored_land_fixing` | `true` | 43 | `already_in_607_mana_package` | current_607_card |
| Windswept Heath | `colored_land_fixing` | `true` | 46 | `already_in_607_mana_package` | current_607_card |
| Wooded Foothills | `colored_land_fixing` | `true` | 49 | `already_in_607_mana_package` | current_607_card |
| Scalding Tarn | `colored_land_fixing` | `true` | 50 | `already_in_607_mana_package` | current_607_card |
| Marsh Flats | `colored_land_fixing` | `true` | 51 | `already_in_607_mana_package` | current_607_card |
| Arid Mesa | `colored_land_fixing` | `true` | 55 | `already_in_607_mana_package` | current_607_card |
| Command Tower | `colored_land_fixing` | `true` | - | `already_in_607_mana_package` | current_607_card |
| Elegant Parlor | `colored_land_fixing` | `true` | - | `already_in_607_mana_package` | current_607_card |
| Sacred Foundry | `colored_land_fixing` | `true` | - | `already_in_607_mana_package` | current_607_card |
| Spectator Seating | `colored_land_fixing` | `true` | - | `already_in_607_mana_package` | current_607_card |
| Sunbaked Canyon | `colored_land_fixing` | `true` | - | `already_in_607_mana_package` | current_607_card |
| Pearl Medallion | `cost_reducer` | `true` | - | `already_in_607_protected_mana_foundation` | current_607_role_card |
| Ruby Medallion | `cost_reducer` | `true` | - | `already_in_607_protected_mana_foundation` | current_607_role_card |
| Arcane Signet | `early_colored_rock` | `true` | 3 | `already_in_607_protected_mana_foundation` | current_607_role_card |
| Fellwar Stone | `early_colored_rock` | `true` | 18 | `already_in_607_protected_mana_foundation` | current_607_role_card |
| Talisman of Conviction | `early_colored_rock` | `true` | 155 | `already_in_607_protected_mana_foundation` | current_607_role_card |
| Boros Signet | `early_colored_rock` | `true` | 226 | `already_in_607_protected_mana_foundation` | current_607_role_card |
| Sol Ring | `early_colorless_burst` | `true` | 1 | `already_in_607_protected_mana_foundation` | current_607_role_card |
| Ancient Tomb | `fast_or_utility_land` | `true` | - | `already_in_607_protected_mana_foundation` | current_607_role_card |
| Jeska's Will | `ritual_or_spell_burst` | `true` | 102 | `already_in_607_protected_mana_foundation` | current_607_role_card |
| Smothering Tithe | `treasure_or_discard_ramp` | `true` | 57 | `already_in_607_protected_mana_foundation` | current_607_role_card |
| Big Score | `treasure_or_discard_ramp` | `true` | 172 | `already_in_607_mana_package` | current_607_card |
| Unexpected Windfall | `treasure_or_discard_ramp` | `true` | 303 | `already_in_607_protected_mana_foundation` | current_607_role_card |
| Monument to Endurance | `treasure_or_discard_ramp` | `true` | - | `already_in_607_protected_mana_foundation` | current_607_role_card |
| Bender's Waterskin | `turn_cycle_miracle_mana` | `true` | - | `already_in_607_protected_turn_cycle_miracle_mana` | opponent_turn_miracle_mana_is_not_generic_ramp |
| Victory Chimes | `turn_cycle_miracle_mana` | `true` | - | `already_in_607_protected_turn_cycle_miracle_mana` | opponent_turn_miracle_mana_is_not_generic_ramp |
| Urza's Saga | `utility_land` | `true` | 119 | `already_in_607_protected_mana_foundation` | current_607_role_card |
| Jeweled Lotus | `banned_fast_mana` | `false` | - | `blocked_commander_banned_or_not_accessible` | commander_ban_or_legality_block |
| Mana Crypt | `banned_fast_mana` | `false` | - | `blocked_commander_banned_or_not_accessible` | commander_ban_or_legality_block |
| Great Furnace | `colored_land_fixing` | `false` | 415 | `candidate_requires_same_lane_cut_and_gate` | staple_policy:candidate_requires_same_lane_cut_and_gate |
| Ancient Den | `colored_land_fixing` | `false` | 528 | `candidate_land_upgrade_requires_current_land_cut` | mana_base_already_passes_current_foundation |
| City of Brass | `colored_land_fixing` | `false` | - | `candidate_land_upgrade_requires_current_land_cut` | mana_base_already_passes_current_foundation |
| Mana Confluence | `colored_land_fixing` | `false` | - | `candidate_land_upgrade_requires_current_land_cut` | mana_base_already_passes_current_foundation |
| Plateau | `colored_land_fixing` | `false` | - | `candidate_land_upgrade_requires_current_land_cut` | mana_base_already_passes_current_foundation |
| Seething Song | `contextual_mana_source` | `false` | 370 | `blocked_prior_exact_reject` | staple_policy:blocked_prior_exact_reject |
| Treasonous Ogre | `contextual_mana_source` | `false` | - | `candidate_requires_same_lane_cut_and_sequence_gate` | must_preserve_commander_turn_and_current_protected_anchors |
| Lotus Petal | `early_colored_rock` | `false` | 117 | `blocked_prior_exact_reject` | staple_policy:blocked_prior_exact_reject |
| Pyretic Ritual | `early_colored_rock` | `false` | - | `candidate_requires_same_lane_cut_and_sequence_gate` | must_preserve_commander_turn_and_current_protected_anchors |
| Mana Vault | `fast_colorless_burst` | `false` | 144 | `blocked_prior_gate_rejected` | mana_vault_current_pair_lost_with_real_card_use |
| Grim Monolith | `fast_colorless_burst` | `false` | - | `candidate_fast_mana_requires_fixing_and_use_gate` | colorless_burst_must_not_reduce_boros_fixing_or_miracle_cadence |
| City of Traitors | `fast_or_utility_land` | `false` | - | `candidate_land_requires_named_land_cut_and_equal_gate` | fast_or_utility_land_cannot_cut_colored_or_protected_land_by_rank |
| Gemstone Caverns | `fast_or_utility_land` | `false` | - | `candidate_land_requires_named_land_cut_and_equal_gate` | fast_or_utility_land_cannot_cut_colored_or_protected_land_by_rank |
| Chrome Mox | `premium_mox_fast_mana` | `false` | 142 | `policy_blocked_no_premium_mox` | staple_policy:policy_blocked_no_premium_mox |
| Mox Amber | `premium_mox_fast_mana` | `false` | 208 | `policy_blocked_no_premium_mox` | staple_policy:policy_blocked_no_premium_mox |
| Mox Opal | `premium_mox_fast_mana` | `false` | 239 | `policy_blocked_no_premium_mox` | staple_policy:policy_blocked_no_premium_mox |
| Mox Diamond | `premium_mox_fast_mana` | `false` | 246 | `policy_blocked_no_premium_mox` | staple_policy:policy_blocked_no_premium_mox |
| Rite of Flame | `ritual_or_spell_burst` | `false` | - | `candidate_spell_ramp_requires_spell_slot_gate` | one_shot_or_contextual_ramp_is_not_opening_fixing |
| Storm-Kiln Artist | `treasure_or_discard_ramp` | `false` | 233 | `candidate_hypothesis_requires_named_cut_and_equal_gate` | staple_policy:candidate_hypothesis_requires_named_cut_and_equal_gate |
| Strike It Rich | `treasure_or_discard_ramp` | `false` | - | `candidate_spell_ramp_requires_spell_slot_gate` | one_shot_or_contextual_ramp_is_not_opening_fixing |

## Learning Sources

- EDHREC Lorehold cEDH average deck: https://edhrec.com/average-decks/lorehold-the-historian/cedh
- EDHREC Miracles Every Turn with Lorehold: https://edhrec.com/articles/miracles-every-turn-with-lorehold-the-historian-in-commander
- Card Kingdom Lorehold synergy article: https://blog.cardkingdom.com/10-crazy-synergy-cards-for-lorehold-the-historian-secrets-of-strixhaven/
- CoolStuffInc Commander ramp discussion: https://www.coolstuffinc.com/a/markwischkaemper-06222023-how-much-ramp-is-right-for-your-commander-deck

## Decision

- keep_607_mana_sequence_policy: `true`
- reason: The protected 607 shell already passes the current land/ramp foundation and contains both early fixing and Lorehold-specific turn-cycle mana. Missing fast mana and land staples are either already in the deck, blocked by legality/policy, previously rejected, or require a named same-lane cut plus equal battle gate.
- next_action: `only generate a land/ramp challenger when it names the exact current land or ramp slot being cut and states which sequencing failure it is trying to fix`
