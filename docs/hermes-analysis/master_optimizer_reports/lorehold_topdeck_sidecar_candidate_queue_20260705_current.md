# Lorehold Topdeck Sidecar Candidate Queue

- Generated at: `2026-07-05T06:35:33Z`
- PostgreSQL writes: `false`
- Source DB mutated: `false`
- Deck 607 mutated: `false`
- Status: `topdeck_sidecar_candidate_queue_blocked_no_matrix_rows_keep_607`
- Queue rows: `40`
- Matrix candidate rows eligible: `0`
- Candidate deck materialization allowed now: `false`
- Natural battle gate allowed now: `false`
- Promotion allowed now: `false`
- Recommended next action: `build_named_same_lane_cut_models_for_topdeck_and_mana_rows_before_matrix_scoring`

## Source Reports

- `hypothesis_queue`: `docs/hermes-analysis/master_optimizer_reports/lorehold_hypothesis_queue_from_value_model_20260705_current_relearn.json`
- `post_safe_cut_route`: `docs/hermes-analysis/master_optimizer_reports/lorehold_topdeck_post_safe_cut_route_20260705_current.json`
- `safe_cut_miner`: `docs/hermes-analysis/master_optimizer_reports/lorehold_topdeck_safe_cut_miner_20260705_current.json`
- `structure_matrix`: `docs/hermes-analysis/master_optimizer_reports/lorehold_miracle_access_structure_matrix_contract_20260705_current_relearn.json`
- `value_model`: `docs/hermes-analysis/master_optimizer_reports/lorehold_deckbuilding_value_model_20260704_current.json`

## Queue Summary

- tag_counts: `{"generic_staple_learning_only": 2, "mana_base_safe_cut_model": 7, "pressure_window_after_topdeck_floor": 5, "sidecar_watchlist": 10, "spell_chain_after_miracle_floor": 8, "topdeck_access_sidecar_primary": 5, "tutor_learning_only_after_prior_reject": 3}`
- readiness_counts: `{"blocked_prior_reject": 9, "needs_safe_cut_model": 31}`
- blocker_counts: `{"generic_staple_not_lorehold_specific_until_trace_proof": 2, "missing_named_same_lane_cut": 40, "must_follow_topdeck_miracle_floor": 13, "needs_safe_cut_model": 40, "prior_reject_requires_new_trace_hypothesis": 9}`

## Candidate Queue

| Card | Tag | Priority | Eligible | Blockers | Next test |
| --- | --- | --- | ---: | --- | --- |
| Boseiju, Who Shelters All | `mana_base_safe_cut_model` | `P1_safe_cut_model` | `false` | `missing_named_same_lane_cut, needs_safe_cut_model` | `build_safe_cut_mana_source_model_before_any_battle_gate` |
| Clifftop Retreat | `mana_base_safe_cut_model` | `P1_safe_cut_model` | `false` | `missing_named_same_lane_cut, needs_safe_cut_model` | `build_safe_cut_mana_source_model_before_any_battle_gate` |
| Plateau | `mana_base_safe_cut_model` | `P1_safe_cut_model` | `false` | `missing_named_same_lane_cut, needs_safe_cut_model` | `build_safe_cut_mana_source_model_before_any_battle_gate` |
| Rugged Prairie | `mana_base_safe_cut_model` | `P1_safe_cut_model` | `false` | `missing_named_same_lane_cut, needs_safe_cut_model` | `build_safe_cut_mana_source_model_before_any_battle_gate` |
| Sundown Pass | `mana_base_safe_cut_model` | `P1_safe_cut_model` | `false` | `missing_named_same_lane_cut, needs_safe_cut_model` | `build_safe_cut_mana_source_model_before_any_battle_gate` |
| Dragon's Rage Channeler | `topdeck_access_sidecar_primary` | `P1_forced_access_diagnostic` | `false` | `missing_named_same_lane_cut, needs_safe_cut_model` | `forced_access_diagnostic_only_until_miracle_access_floors_pass` |
| Galvanoth | `topdeck_access_sidecar_primary` | `P1_forced_access_diagnostic` | `false` | `missing_named_same_lane_cut, needs_safe_cut_model` | `forced_access_diagnostic_only_until_miracle_access_floors_pass` |
| Penance | `topdeck_access_sidecar_primary` | `P1_forced_access_diagnostic` | `false` | `missing_named_same_lane_cut, needs_safe_cut_model` | `forced_access_diagnostic_only_until_miracle_access_floors_pass` |
| Valakut Awakening // Valakut Stoneforge | `topdeck_access_sidecar_primary` | `P1_forced_access_diagnostic` | `false` | `missing_named_same_lane_cut, needs_safe_cut_model` | `forced_access_diagnostic_only_until_miracle_access_floors_pass` |
| Wheel of Fortune | `topdeck_access_sidecar_primary` | `P1_forced_access_diagnostic` | `false` | `missing_named_same_lane_cut, needs_safe_cut_model` | `forced_access_diagnostic_only_until_miracle_access_floors_pass` |
| Boros Charm | `pressure_window_after_topdeck_floor` | `P1_forced_access_diagnostic` | `false` | `missing_named_same_lane_cut, must_follow_topdeck_miracle_floor, needs_safe_cut_model` | `forced_access_pressure_window_diagnostic_only_until_winota_floor_passes` |
| Deflecting Palm | `pressure_window_after_topdeck_floor` | `P1_forced_access_diagnostic` | `false` | `missing_named_same_lane_cut, must_follow_topdeck_miracle_floor, needs_safe_cut_model` | `forced_access_pressure_window_diagnostic_only_until_winota_floor_passes` |
| Grand Abolisher | `pressure_window_after_topdeck_floor` | `P1_forced_access_diagnostic` | `false` | `missing_named_same_lane_cut, must_follow_topdeck_miracle_floor, needs_safe_cut_model` | `forced_access_pressure_window_diagnostic_only_until_winota_floor_passes` |
| Perch Protection | `pressure_window_after_topdeck_floor` | `P1_forced_access_diagnostic` | `false` | `missing_named_same_lane_cut, must_follow_topdeck_miracle_floor, needs_safe_cut_model` | `forced_access_pressure_window_diagnostic_only_until_winota_floor_passes` |
| Silence | `pressure_window_after_topdeck_floor` | `P1_forced_access_diagnostic` | `false` | `missing_named_same_lane_cut, must_follow_topdeck_miracle_floor, needs_safe_cut_model` | `forced_access_pressure_window_diagnostic_only_until_winota_floor_passes` |
| Apex of Power | `spell_chain_after_miracle_floor` | `P1_forced_access_diagnostic` | `false` | `missing_named_same_lane_cut, must_follow_topdeck_miracle_floor, needs_safe_cut_model` | `forced_access_diagnostic_only_until_miracle_access_floors_pass` |
| Brass's Bounty | `spell_chain_after_miracle_floor` | `P1_forced_access_diagnostic` | `false` | `missing_named_same_lane_cut, must_follow_topdeck_miracle_floor, needs_safe_cut_model` | `forced_access_diagnostic_only_until_miracle_access_floors_pass` |
| Boros Garrison | `mana_base_safe_cut_model` | `P2_forced_access_diagnostic` | `false` | `missing_named_same_lane_cut, needs_safe_cut_model` | `build_safe_cut_mana_source_model_before_any_battle_gate` |
| Cavern of Souls | `mana_base_safe_cut_model` | `P2_forced_access_diagnostic` | `false` | `missing_named_same_lane_cut, needs_safe_cut_model` | `build_safe_cut_mana_source_model_before_any_battle_gate` |
| Dance with Calamity | `spell_chain_after_miracle_floor` | `P2_forced_access_diagnostic` | `false` | `missing_named_same_lane_cut, must_follow_topdeck_miracle_floor, needs_safe_cut_model` | `forced_access_diagnostic_only_until_miracle_access_floors_pass` |
| Goldspan Dragon | `spell_chain_after_miracle_floor` | `P2_forced_access_diagnostic` | `false` | `missing_named_same_lane_cut, must_follow_topdeck_miracle_floor, needs_safe_cut_model` | `forced_access_diagnostic_only_until_miracle_access_floors_pass` |
| Invoke Calamity | `spell_chain_after_miracle_floor` | `P2_forced_access_diagnostic` | `false` | `missing_named_same_lane_cut, must_follow_topdeck_miracle_floor, needs_safe_cut_model` | `forced_access_diagnostic_only_until_miracle_access_floors_pass` |
| Austere Command | `sidecar_watchlist` | `P2_forced_access_diagnostic` | `false` | `missing_named_same_lane_cut, needs_safe_cut_model` | `safe_cut_model_required_before_natural_gate` |
| Chaos Warp | `sidecar_watchlist` | `P2_forced_access_diagnostic` | `false` | `missing_named_same_lane_cut, needs_safe_cut_model` | `safe_cut_model_required_before_natural_gate` |
| Dualcaster Mage | `sidecar_watchlist` | `P2_forced_access_diagnostic` | `false` | `missing_named_same_lane_cut, needs_safe_cut_model` | `safe_cut_model_required_before_natural_gate` |
| Goliath Daydreamer | `sidecar_watchlist` | `P2_forced_access_diagnostic` | `false` | `missing_named_same_lane_cut, needs_safe_cut_model` | `safe_cut_model_required_before_natural_gate` |
| Longshot, Rebel Bowman | `sidecar_watchlist` | `P2_forced_access_diagnostic` | `false` | `missing_named_same_lane_cut, needs_safe_cut_model` | `safe_cut_model_required_before_natural_gate` |
| Goblin Engineer | `tutor_learning_only_after_prior_reject` | `P2_forced_access_diagnostic` | `false` | `missing_named_same_lane_cut, needs_safe_cut_model` | `safe_cut_model_required_before_natural_gate` |
| Olórin's Searing Light | `sidecar_watchlist` | `P2_forced_access_diagnostic` | `false` | `missing_named_same_lane_cut, needs_safe_cut_model` | `safe_cut_model_required_before_natural_gate` |
| Restoration Seminar | `sidecar_watchlist` | `P2_forced_access_diagnostic` | `false` | `missing_named_same_lane_cut, needs_safe_cut_model` | `safe_cut_model_required_before_natural_gate` |
| Volcanic Vision | `sidecar_watchlist` | `P2_forced_access_diagnostic` | `false` | `missing_named_same_lane_cut, needs_safe_cut_model` | `safe_cut_model_required_before_natural_gate` |
| Birgi, God of Storytelling // Harnfel, Horn of Bounty | `spell_chain_after_miracle_floor` | `P3_learning_only` | `false` | `missing_named_same_lane_cut, must_follow_topdeck_miracle_floor, needs_safe_cut_model, prior_reject_requires_new_trace_hypothesis` | `do_not_retest_without_new_cut_or_new_trace_hypothesis` |
| Cloud Key | `spell_chain_after_miracle_floor` | `P3_learning_only` | `false` | `missing_named_same_lane_cut, must_follow_topdeck_miracle_floor, needs_safe_cut_model, prior_reject_requires_new_trace_hypothesis` | `do_not_retest_without_new_cut_or_new_trace_hypothesis` |
| Mana Vault | `generic_staple_learning_only` | `P3_learning_only` | `false` | `generic_staple_not_lorehold_specific_until_trace_proof, missing_named_same_lane_cut, needs_safe_cut_model, prior_reject_requires_new_trace_hypothesis` | `do_not_retest_without_new_cut_or_new_trace_hypothesis` |
| Storm-Kiln Artist | `spell_chain_after_miracle_floor` | `P3_learning_only` | `false` | `missing_named_same_lane_cut, must_follow_topdeck_miracle_floor, needs_safe_cut_model, prior_reject_requires_new_trace_hypothesis` | `do_not_retest_without_new_cut_or_new_trace_hypothesis` |
| Electro, Assaulting Battery | `sidecar_watchlist` | `P3_learning_only` | `false` | `missing_named_same_lane_cut, needs_safe_cut_model, prior_reject_requires_new_trace_hypothesis` | `do_not_retest_without_new_cut_or_new_trace_hypothesis` |
| Possibility Storm | `sidecar_watchlist` | `P3_learning_only` | `false` | `missing_named_same_lane_cut, needs_safe_cut_model, prior_reject_requires_new_trace_hypothesis` | `do_not_retest_without_new_cut_or_new_trace_hypothesis` |
| Enlightened Tutor | `tutor_learning_only_after_prior_reject` | `P3_learning_only` | `false` | `missing_named_same_lane_cut, needs_safe_cut_model, prior_reject_requires_new_trace_hypothesis` | `do_not_retest_without_new_cut_or_new_trace_hypothesis` |
| Gamble | `tutor_learning_only_after_prior_reject` | `P3_learning_only` | `false` | `missing_named_same_lane_cut, needs_safe_cut_model, prior_reject_requires_new_trace_hypothesis` | `do_not_retest_without_new_cut_or_new_trace_hypothesis` |
| The One Ring | `generic_staple_learning_only` | `P3_learning_only` | `false` | `generic_staple_not_lorehold_specific_until_trace_proof, missing_named_same_lane_cut, needs_safe_cut_model, prior_reject_requires_new_trace_hypothesis` | `do_not_retest_without_new_cut_or_new_trace_hypothesis` |

## Matrix Candidate Rows

- None. Every current row is blocked before matrix scoring.

## Decision

- keep_607_as_protected_baseline: `true`
- deck_action_allowed: `false`
- matrix_candidate_rows_ready: `false`
- candidate_deck_materialization_allowed_now: `false`
- forced_access_allowed_now: `false`
- natural_battle_allowed_now: `false`
- promotion_allowed: `false`
- reason: The queue has learning rows, but no current row has the named same-lane cut and floor proof required by the structure matrix.
- next_actions:
  - do_not_mutate_deck_607
  - do_not_materialize_a_sidecar_deck_from_blocked_rows
  - mine named same-lane cuts for topdeck and mana rows first
  - keep Mana Vault and The One Ring as learning-only until new trace and cut proof exist
