# Lorehold Topdeck Post Safe-Cut Route

- Generated at: `2026-07-05T07:23:39Z`
- PostgreSQL writes: `false`
- Source DB mutated: `false`
- Deck 607 mutated: `false`
- Status: `topdeck_post_safe_cut_route_sidecar_shell_required_keep_607`
- Selected route: `topdeck_access_first_sidecar_shell`
- One-for-one cut ready count: `0`
- Non-anchor primary target: `Dragon's Rage Channeler`
- Non-anchor primary target status: `clean_prior_target_blocked_no_nonanchor_cut`
- Non-anchor seed-safe count: `0`
- Non-anchor reviewable gaps: `0`
- Reviewable same-lane gaps: `0`
- Forced-access runnable count: `0`
- Sidecar shell contract required: `true`
- Natural battle gate allowed: `false`
- Promotion allowed: `false`
- Recommended next action: `write_or_refresh_topdeck_access_first_sidecar_shell_contract_before_materialization`

## Source Reports

- `closing_window_router`: `docs/hermes-analysis/master_optimizer_reports/lorehold_closing_window_next_shell_target_router_20260705_current_relearn.json`
- `hypothesis_queue`: `docs/hermes-analysis/master_optimizer_reports/lorehold_hypothesis_queue_from_value_model_20260705_current_relearn.json`
- `microbenchmark_plan`: `docs/hermes-analysis/master_optimizer_reports/lorehold_topdeck_forced_access_microbenchmark_plan_20260705_current.json`
- `miracle_shell_contract`: `docs/hermes-analysis/master_optimizer_reports/lorehold_miracle_access_first_shell_contract_20260705_current_relearn.json`
- `nonanchor_cut_model`: `docs/hermes-analysis/master_optimizer_reports/lorehold_topdeck_nonanchor_cut_model_miner_20260705_current.json`
- `safe_cut_miner`: `docs/hermes-analysis/master_optimizer_reports/lorehold_topdeck_safe_cut_miner_20260705_current.json`
- `shell_failure_synthesis`: `docs/hermes-analysis/master_optimizer_reports/lorehold_from_scratch_shell_failure_synthesis_20260705_current_relearn.json`

## External Research Snapshot

- Wizards Commander format: https://magic.wizards.com/en/formats/commander
  - model_use: Use as legality gate for any sidecar or candidate. Legality never overrides runtime trace, cut safety, or same-seed battle evidence.
- EDHREC Lorehold commander page: https://edhrec.com/commanders/lorehold-the-historian
  - model_use: Use public adoption as lane discovery. Lorehold-specific topdeck anchors outrank generic staples unless runtime proof says otherwise.
- EDHREC optimized topdeck Lorehold page: https://edhrec.com/decks/lorehold-the-historian/optimized/topdeck
  - model_use: Optimized topdeck lists confirm the learning route, but the sample is small and cannot promote a ManaLoom deck without local battle gates.

## Selected Route

- selected_route: `topdeck_access_first_sidecar_shell`
- reason: Zero safe cuts and zero runnable forced-access commands leave a copied sidecar shell contract as the next learning step.
- recommended_next_action: `write_or_refresh_topdeck_access_first_sidecar_shell_contract_before_materialization`

## Sidecar Shell Contract Requirements

- shell_key: `topdeck_access_first_sidecar_shell`
- materialization_allowed_now: `false`
- battle_allowed_now: `false`
- copy_or_lab_candidate_only; never mutate deck_607
- declare shell hypothesis before any 100-card materialization
- preserve Commander 99-plus-1, singleton, and color identity gates
- state adds, same-lane cuts, and protected anchors before decklist output
- preserve Sensei's Divining Top, Scroll Rack, Library of Leng, and Land Tax access floors
- preserve Bender's Waterskin and Victory Chimes unless same-lane proof beats 607
- preserve miracle_cast, topdeck_manipulation_activated, upkeep_rummage, and spell_volume floors
- show direct drawn/cast/activated trace for each added card
- block generic-staple upgrades until same-lane cut proof exists
- run forced-access only as diagnostic; never as promotion evidence
- run natural equal battle gate only after structure matrix and trace floors pass
- compare against current deck_607 on same seed and opponent matrix
- include Winota or fast-pressure slice before promotion

## Global Staple Policy

### Mana Vault
- current_access_status: `not_accessible_for_607_change_now`
- reason: Legal Commander staple, but current 607 evidence has no safe cut and EDHREC Lorehold synergy is low compared with topdeck anchors.
- required_proof:
  - `early_mana_lane_gap`
  - `same_lane_nonanchor_cut`
  - `no_topdeck_floor_regression`
  - `same_seed_equal_gate_beats_607`
### The One Ring
- current_access_status: `not_accessible_for_607_change_now`
- reason: Legal colorless draw engine, but it is generic resource density until the shell proves it improves Lorehold's miracle/topdeck floor without slowing the commander plan.
- required_proof:
  - `draw_lane_gap`
  - `same_lane_nonanchor_cut`
  - `candidate_drawn_cast_used_trace`
  - `no_fast_pressure_regression`

## Blocked Routes

- `one_for_one_swap_now` -> `blocked_without_seed_safe_cut`: The safe-cut miner found zero seed-safe cuts for the topdeck target set.
- `natural_battle_gate_now` -> `blocked_before_structure_matrix`: A natural gate would test an undeclared structure, not a controlled deckbuilding hypothesis.
- `broad_from_scratch_rewrite` -> `blocked_by_prior_shell_failures`: Prior broad shells did not create promotable evidence against protected 607.
- `generic_staple_upgrade` -> `blocked_without_lane_and_cut_proof`: Mana Vault and The One Ring are hypotheses, not replacements, until they have a lane, a cut, and trace proof.

## Decision

- keep_607_as_protected_baseline: `true`
- allow_deck_mutation_now: `false`
- allow_forced_access_execution_now: `false`
- allow_natural_gate_now: `false`
- promotion_allowed: `false`
- reason: Zero safe cuts and zero runnable forced-access commands leave a copied sidecar shell contract as the next learning step.
- next_actions:
  - do_not_mutate_deck_607
  - do_not_write_postgresql_or_sqlite
  - write_or_refresh_topdeck_access_first_sidecar_shell_contract_before_materialization
  - keep global staples as hypotheses until lane, cut, trace, and battle proof exist
