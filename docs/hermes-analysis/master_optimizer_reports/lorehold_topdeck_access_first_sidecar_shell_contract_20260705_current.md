# Lorehold Topdeck Access First Sidecar Shell Contract

- Generated at: `2026-07-05T07:34:30Z`
- PostgreSQL writes: `false`
- Source DB mutated: `false`
- Deck 607 mutated: `false`
- Status: `topdeck_access_first_sidecar_contract_written_no_matrix_rows_keep_607`
- Contract key: `topdeck_access_first_sidecar_shell_contract`
- Shell key: `topdeck_access_first_sidecar_shell`
- Selected route: `topdeck_access_first_sidecar_shell`
- Queue rows: `40`
- Matrix candidate rows eligible: `0`
- Topdeck target rows: `5`
- Non-anchor primary target: `Dragon's Rage Channeler`
- Non-anchor primary target status: `clean_prior_target_blocked_no_nonanchor_cut`
- Non-anchor seed-safe count: `0`
- Non-anchor reviewable gaps: `0`
- 607 land floor: `34`
- 607 ramp floor: `15`
- Structure matrix contract allowed now: `false`
- Candidate deck materialization allowed now: `false`
- Forced access allowed now: `false`
- Natural battle gate allowed now: `false`
- Promotion allowed now: `false`
- Recommended next action: `build_named_same_lane_cut_models_for_topdeck_and_mana_rows_before_structure_matrix`

## Source Reports

- `miracle_shell_contract`: `docs/hermes-analysis/master_optimizer_reports/lorehold_miracle_access_first_shell_contract_20260705_current_relearn.json`
- `nonanchor_cut_model`: `docs/hermes-analysis/master_optimizer_reports/lorehold_topdeck_nonanchor_cut_model_miner_20260705_current.json`
- `post_safe_cut_route`: `docs/hermes-analysis/master_optimizer_reports/lorehold_topdeck_post_safe_cut_route_20260705_current.json`
- `sidecar_queue`: `docs/hermes-analysis/master_optimizer_reports/lorehold_topdeck_sidecar_candidate_queue_20260705_current.json`
- `trace_evidence`: `docs/hermes-analysis/master_optimizer_reports/lorehold_topdeck_floor_trace_evidence_collector_20260705_current.json`
- `value_model`: `docs/hermes-analysis/master_optimizer_reports/lorehold_deckbuilding_value_model_20260704_current.json`

## External Research Refresh

- Wizards Commander format: https://magic.wizards.com/en/formats/commander
  - Use official Commander deck shape, singleton, and color identity as legality gates only; they do not prove a deckbuilding upgrade.
- Scryfall Lorehold, the Historian: https://scryfall.com/card/sos/201/lorehold-the-historian
  - Lorehold's miracle grant and opponent-upkeep rummage make top-library control and opponent-turn mana first-class deckbuilding lanes.
- EDHREC Lorehold optimized topdeck average deck: https://edhrec.com/average-decks/lorehold-the-historian/topdeck
  - Public topdeck lists are discovery evidence for cards such as Dragon's Rage Channeler; local cut, trace, and battle gates still win.
- EDHREC Miracles Every Turn with Lorehold: https://edhrec.com/articles/miracles-every-turn-with-lorehold-the-historian-in-commander
  - Use the article only to reinforce the miracle/topdeck floor; it is not a ManaLoom promotion result.
- Card Kingdom Lorehold synergy article: https://blog.cardkingdom.com/10-crazy-synergy-cards-for-lorehold-the-historian-secrets-of-strixhaven/
  - Use synergy suggestions as hypotheses. They still need named cuts and 607-preserving trace proof before execution.

## Value Lanes

- `topdeck_miracle_setup`
- `hand_to_library_control`
- `opponent_turn_mana`
- `spell_volume_conversion`
- `same_lane_nonanchor_cut`
- `nonanchor_cut_model_proof`
- `fast_pressure_survival`

## Protected Anchors

- `Approach of the Second Sun`
- `Bender's Waterskin`
- `Creative Technique`
- `Land Tax`
- `Library of Leng`
- `Lorehold, the Historian`
- `Mizzix's Mastery`
- `Molecule Man`
- `Scroll Rack`
- `Sensei's Divining Top`
- `Storm Herd`
- `The Mind Stone`
- `The Scarlet Witch`
- `Victory Chimes`

## Mana Foundation Floor

`{"artifact_ramp_quantity": 11, "enchantment_ramp_quantity": 1, "instant_sorcery_ramp_quantity": 3, "interpretation": "The 607 mana plan is not just more fast mana: it combines 34 lands, fetch/dual fixing, artifact ramp, spell ramp, and opponent-turn mana rocks that feed miracle windows.", "land_groups": {"basic_floor": 8, "fetch_or_search_fixing": 8, "typed_dual_or_fetch_target": 5, "untapped_or_multiplayer_fixing": 5, "utility_engine_land": 8}, "land_quantity": 34, "land_rows": 28, "mana_sources_land_plus_ramp": 49, "ramp_quantity": 15}`

## Blocked Staples

- `Mana Vault` in `early_mana_and_spell_chain_conversion`: `learning_only_not_607_change`. Fast mana is valuable, but current evidence has no same-lane cut that preserves the 607 opponent-turn mana and miracle cadence floors.
- `The One Ring` in `draw_and_resource_density`: `learning_only_not_607_change`. Generic draw is valuable, but prior 607 retests did not beat the protected shell and no current cut model repairs the floor risk.

## Topdeck Targets

| Card | Model status | Same-lane slots | Seed-safe | Reviewable gaps | Blockers |
| --- | --- | ---: | ---: | ---: | --- |
| Dragon's Rage Channeler | `clean_prior_target_blocked_no_nonanchor_cut` | `6` | `0` | `0` | `missing_named_same_lane_cut, needs_safe_cut_model, nonanchor_model_has_no_reviewable_gap, nonanchor_model_has_no_seed_safe_cut` |
| Galvanoth | `prior_reject_target_blocked_no_nonanchor_cut` | `8` | `0` | `0` | `missing_named_same_lane_cut, needs_safe_cut_model, nonanchor_model_has_no_reviewable_gap, nonanchor_model_has_no_seed_safe_cut, prior_reject_requires_new_trace_hypothesis` |
| Penance | `prior_reject_target_blocked_no_nonanchor_cut` | `20` | `0` | `0` | `missing_named_same_lane_cut, needs_safe_cut_model, nonanchor_model_has_no_reviewable_gap, nonanchor_model_has_no_seed_safe_cut, prior_reject_requires_new_trace_hypothesis` |
| Valakut Awakening // Valakut Stoneforge | `prior_reject_target_blocked_no_nonanchor_cut` | `13` | `0` | `0` | `missing_named_same_lane_cut, needs_safe_cut_model, nonanchor_model_has_no_reviewable_gap, nonanchor_model_has_no_seed_safe_cut, prior_reject_requires_new_trace_hypothesis` |
| Wheel of Fortune | `prior_reject_target_blocked_no_nonanchor_cut` | `13` | `0` | `0` | `missing_named_same_lane_cut, needs_safe_cut_model, nonanchor_model_has_no_reviewable_gap, nonanchor_model_has_no_seed_safe_cut, prior_reject_requires_new_trace_hypothesis` |

## Contract Requirements

- copy_or_lab_candidate_only; never mutate deck_607
- do_not_materialize_a_100_card_list_until_a_named_add_cut_pair_exists
- preserve Commander 99-plus-1, singleton, and color identity gates
- preserve the current 607 land and ramp floor unless a mana model beats it
- preserve topdeck, miracle, upkeep-rummage, spell-volume, and cost-reduction floors
- preserve Sensei's Divining Top, Scroll Rack, Library of Leng, and Land Tax access
- preserve Bender's Waterskin and Victory Chimes unless same-lane proof beats 607
- declare each add, cut, protected anchor, lane, floor risk, and expected metric lift
- require direct drawn/cast/activated trace for added cards before natural battle
- block forced access unless it has a temporary safe cut manifest
- never treat forced-access success as promotion evidence
- run equal battle gates only after structure matrix and trace floors pass
- include a Winota or fast-pressure slice before any promotion claim

## Promotion Gate Requirements

- `same_seed_same_opponent_matrix_against_current_deck_607`
- `candidate_ties_or_beats_607_aggregate`
- `Winota_fast_pressure_slice_ties_or_improves`
- `direct_drawn_cast_used_trace_for_added_cards_and_anchors`
- `closing_window_trace_shows_topdeck_miracle_plan_executed`

## Decision

- keep_607_as_protected_baseline: `true`
- deck_action_allowed: `false`
- structure_matrix_contract_allowed_now: `false`
- candidate_deck_materialization_allowed_now: `false`
- forced_access_allowed_now: `false`
- natural_battle_allowed_now: `false`
- promotion_allowed: `false`
- reason: The sidecar contract can be written, but current rows have zero matrix-eligible add/cut pairs and zero non-anchor safe cuts, so learning must continue at the cut-model layer.
- next_actions:
  - do_not_mutate_deck_607
  - do_not_write_postgresql_or_sqlite
  - do_not_materialize_a_sidecar_deck_from_blocked_rows
  - mine_named_same_lane_cuts_for_topdeck_targets
  - treat Mana Vault and The One Ring as learning-only until lane, cut, trace, and battle proof exist
