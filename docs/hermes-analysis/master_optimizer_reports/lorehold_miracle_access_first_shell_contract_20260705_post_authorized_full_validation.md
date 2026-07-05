# Lorehold Miracle Access First Shell Contract

- Generated at: `2026-07-05T11:26:01Z`
- PostgreSQL writes: `false`
- Source DB mutated: `false`
- Deck 607 mutated: `false`
- Decision status: `miracle_access_first_contract_written_no_battle_blocked_before_structure_matrix`
- Selected hypothesis: `preserve_topdeck_miracle_floor_micro_package`
- Selected contract: `miracle_access_first_shell_contract`
- Structure matrix contract allowed now: `true`
- Structure matrix allowed now: `false`
- Natural battle gate allowed now: `false`
- Promotion allowed now: `false`
- Named seed-safe cuts: `0`
- Aggregate blockers: `28`
- Recommended next action: `design_micro_shell_structure_matrix_contract_no_battle`

## Source Reports

- `closing_trace`: `docs/hermes-analysis/master_optimizer_reports/lorehold_closing_window_trace_miner_20260704_role_tag_repair.json`
- `cut_miner`: `docs/hermes-analysis/master_optimizer_reports/lorehold_engine_preserving_cut_evidence_miner_20260705_current_relearn.json`
- `miracle_failure`: `docs/hermes-analysis/master_optimizer_reports/lorehold_miracle_trace_failure_miner_20260704_current.json`
- `preflight`: `docs/hermes-analysis/master_optimizer_reports/lorehold_miracle_access_first_preflight_20260704_current.json`
- `router`: `docs/hermes-analysis/master_optimizer_reports/lorehold_closing_window_next_shell_target_router_20260705_post_authorized_full_validation.json`
- `shell_failure`: `docs/hermes-analysis/master_optimizer_reports/lorehold_from_scratch_shell_failure_synthesis_20260705_authorized_full_validation.json`

## External Research Refresh

- Wizards Commander format: https://magic.wizards.com/en/formats/commander
  - Use official Commander shape, singleton, color identity, and bracket framing as legality and power-context gates only.
- EDHREC Lorehold commander page: https://edhrec.com/commanders/lorehold-the-historian
  - Treat public Lorehold adoption and staple rates as evidence lanes. They can suggest cards, but cannot override 607 trace floors or cuts.
- EDHREC Miracles Every Turn with Lorehold: https://edhrec.com/articles/miracles-every-turn-with-lorehold-the-historian-in-commander
  - Lorehold's opponent-upkeep rummage creates first-draw miracle windows; top-library control is therefore the engine floor.
- EDHREC Boros Miracles on a Budget: https://edhrec.com/articles/lorehold-the-historian-boros-miracles-on-a-budget
  - Instant/sorcery density, topdeck manipulation, protection, mana for opponents' turns, and big spell conversion are the relevant lanes.
- Commander Spellbook: https://commanderspellbook.com/
  - Use combo discovery as package evidence only; it is not full-deck balance, cut safety, or ManaLoom runtime proof.

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

## Event Floor Requirements

- `miracle_cast_floor` uses `miracle_cast`: meet_or_exceed_current_607_same_seed_floor
- `topdeck_manipulation_floor` uses `topdeck_manipulation_activated`: meet_or_exceed_current_607_same_seed_floor
- `lorehold_spell_volume_floor` uses `lorehold_spell_cast`: meet_or_exceed_current_607_same_seed_floor
- `upkeep_rummage_floor` uses `lorehold_upkeep_rummage`: meet_or_exceed_current_607_same_seed_floor
- `static_cost_reduction_floor` uses `static_cost_reduction_total`: no_regression_against_607_closing_window_trace
- `approach_conversion_floor` uses `approach_conversion`: no_missing_approach_conversion_in_candidate_closing_windows

## Current 607 Floors

- strategic_floors_from_607: `{"lorehold_cost_paid": 27, "lorehold_spell_cast": 22, "lorehold_upkeep_rummage": 5, "miracle_cast": 4, "topdeck_manipulation_activated": 5}`
- anchor_access_floors_from_607: `{"Land Tax": 1, "Library of Leng": 0, "Lorehold, the Historian": 3, "Scroll Rack": 1, "Sensei's Divining Top": 2, "The Mind Stone": 2, "Urza's Saga": 1}`

## Blocked Shortcuts

- `pressure_conversion_blocked_until_miracle_floor`: Pressure packages such as Guttersnipe or Storm-Kiln cannot be tested as the next shell until miracle/topdeck floors are preserved.
- `forced_access_not_promotion_evidence`: Forced access can prove visibility or use, but prior forced-access diagnostics still failed to convert into wins.
- `global_staple_not_cross_lane_cut_proof`: Mana Vault, The One Ring, and similar staples stay hypotheses unless same-lane cut proof and equal battle evidence beat protected 607.
- `broad_from_scratch_shell_blocked`: The current from-scratch shell synthesis shows broad shells below 607 and requires a predeclared trace target before another shell.

## Structure Matrix Entry Requirements

- start from a micro-shell structure matrix, not a broad full-deck rewrite
- state adds, same-lane cuts, and protected anchors before materializing any list
- keep legal Commander shape, color identity, singleton, and unresolved count gates separate
- preserve topdeck, miracle, upkeep-rummage, spell-volume, and cost-reduction floors
- preserve natural access to Sensei's Divining Top and Scroll Rack
- preserve Bender's Waterskin and Victory Chimes unless same-lane evidence beats 607
- carry Approach of the Second Sun conversion as a protected finisher floor
- reject pressure, tutor, recursion, or generic value density if the miracle floor regresses

## Battle Gate Requirements

- `structure_matrix_passes_before_any_battle`
- `copied_deck_or_lab_candidate_only_until_promotion_gate_passes`
- `same_seed_same_opponent_matrix_against_current_deck_607`
- `direct_drawn_cast_used_trace_for_added_cards_and_anchors`
- `candidate_ties_or_beats_607_aggregate`
- `Winota_fast_pressure_slice_ties_or_improves`
- `closing_window_trace_shows_miracle_topdeck_plan_executed`

## Aggregate Blockers

- `aggregate_topdeck_anchor_access_regressed`
- `all current from-scratch shells are below protected 607`
- `another battle gate without a predeclared trace target would repeat prior work`
- `broad shell changes overfill package lanes or regress miracle/topdeck cadence`
- `fast_pressure_slice_not_protected`
- `fast_pressure_slice_regressed`
- `forced tutor/access evidence still failed to convert into wins`
- `from_scratch_shell_gate_not_allowed`
- `head_to_head_not_won`
- `head_to_head_vs_607_not_won_or_tied`
- `land_tax_access_below_607_floor`
- `lorehold_cost_paid_below_607_floor`
- `lorehold_spell_cast_below_607_floor`
- `lorehold_upkeep_rummage_below_607_floor`
- `miracle_cast_below_607_floor`
- `miracle_trace_missing`
- `no_named_seed_safe_cuts_in_current_607`
- `pressure_card_use_not_observed`
- `pressure_causality_unproven`
- `pressure_conversion_not_proven`
- `pressure_conversion_unproven`
- `scroll_rack_access_below_607_floor`
- `senseis_divining_top_access_below_607_floor`
- `the_mind_stone_access_below_607_floor`
- `topdeck_activation_missing`
- `topdeck_anchor_access_regressed`
- `topdeck_manipulation_activated_below_607_floor`
- `urzas_saga_access_below_607_floor`

## Decision

- keep_607_as_protected_baseline: `true`
- deck_action_allowed: `false`
- structure_matrix_allowed_now: `false`
- natural_battle_allowed_now: `false`
- promotion_allowed: `false`
- reason: The next learning target is the miracle/topdeck access floor, but current evidence still has blocker signals and no ready deck change.
- next_actions:
  - do_not_mutate_deck_607
  - do_not_write_postgresql_or_sqlite
  - write_or_run_structure_matrix_only_after this contract
  - preserve protected anchors unless same-lane proof beats 607
  - run equal battle gate only after structure matrix and trace floors pass
