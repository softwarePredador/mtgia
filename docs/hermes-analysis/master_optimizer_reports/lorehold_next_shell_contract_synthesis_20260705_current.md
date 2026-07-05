# Lorehold Next Shell Contract Synthesis

- Generated at: `2026-07-05T08:43:13Z`
- PostgreSQL writes: `false`
- Source DB mutated: `false`
- Deck 607 mutated: `false`
- Status: `next_shell_contract_written_not_materializable_keep_607`
- Shell key: `engine_preserving_pressure_conversion_shell_v1`
- Target route: `guttersnipe_storm_kiln_engine_preserving_pair`
- Target adds: `Guttersnipe, Storm-Kiln Artist`
- Mana floor: `34` lands, `15` ramp, `49` land+ramp sources
- Available named seed-safe cuts: `0`
- Cut shortage: `2`
- Candidate deck materialization allowed now: `false`
- Natural battle gate allowed now: `false`
- Promotion allowed now: `false`
- Recommended next action: `mine_two_named_seed_safe_nonanchor_cuts_for_engine_preserving_shell`

## Source Reports

- `artifact_audit`: `docs/hermes-analysis/master_optimizer_reports/lorehold_artifact_contract_audit_20260705_governed_learning_artifacts_current.json`
- `current_best`: `docs/hermes-analysis/master_optimizer_reports/lorehold_current_best_baseline_synthesis_20260705_current.json`
- `engine_contract`: `docs/hermes-analysis/master_optimizer_reports/lorehold_guttersnipe_storm_kiln_hypothesis_contract_20260705_current_relearn.json`
- `gap_floor_trace_miner`: `docs/hermes-analysis/master_optimizer_reports/lorehold_gap_floor_trace_miner_20260705_current.json`
- `sidecar_cut_planner`: `docs/hermes-analysis/master_optimizer_reports/lorehold_topdeck_sidecar_cut_model_planner_20260705_current.json`
- `staple_accessibility`: `docs/hermes-analysis/master_optimizer_reports/lorehold_staple_accessibility_freshness_audit_20260705_current.json`
- `value_model`: `docs/hermes-analysis/master_optimizer_reports/lorehold_deckbuilding_value_model_20260704_current.json`

## Target Adds

- `Guttersnipe`: role `noncombat_spell_pressure`, position `candidate_add_after_named_safe_cuts`, blockers `fast_pressure_slice_not_protected, no_current_positive_guttersnipe_trace, pressure_causality_unproven, pressure_conversion_unproven`
- `Storm-Kiln Artist`: role `spell_chain_mana_conversion`, position `candidate_add_after_named_safe_cuts`, blockers `pressure_conversion_unproven, storm_kiln_arcane_signet_swap_rejected`

## Protected Core

- Protected anchors: `Bender's Waterskin`, `Victory Chimes`, `Molecule Man`, `The Scarlet Witch`, `The Mind Stone`, `Insurrection`, `Storm Herd`, `Creative Technique`
- Floor-trace cut blockers: `Call Forth the Tempest`, `Esper Sentinel`, `Everything Comes to Dust`, `Hit the Mother Lode`, `Rise of the Eldrazi`, `Surge to Victory`

## Learning-Only Staples

- `Mana Vault`: `rules_accessible_collection_missing_promotion_blocked`, owned `false`, readiness `blocked_prior_reject`, promotion `blocked_prior_gate_rejected`
- `The One Ring`: `rules_collection_accessible_promotion_blocked`, owned `true`, readiness `blocked_prior_reject`, promotion `blocked_existing_package_rejected`

## Materialization Requirements

- `find_two_named_seed_safe_nonanchor_cuts`
- `do_not_cut_floor_trace_blockers_or_protected_anchors_as_generic_slots`
- `preserve_34_lands_15_ramp_49_land_plus_ramp_sources`
- `preserve_topdeck_miracle_and_lorehold_upkeep_rummage_floors`
- `show_direct_guttersnipe_damage_events_and_storm_kiln_treasure_events`
- `tie_or_improve_winota_fast_pressure_slice`
- `pass_structure_matrix_before_any_equal_battle_gate`
- `run_same_seed_same_opponent_gate_against_current_deck_607`

## External Learning Snapshot

- `Wizards Commander banned list`: https://magic.wizards.com/en/banned-restricted-list - Commander legality is an entry gate. Mana Vault and The One Ring are not deck-ready just because they are legal.
- `Scryfall named-card legalities`: https://scryfall.com - Mana Vault, The One Ring, Guttersnipe, and Storm-Kiln Artist are Commander-legal in the current external snapshot.
- `EDHREC Lorehold optimized spellslinger`: https://edhrec.com/average-decks/lorehold-the-historian/optimized/spellslinger - Public Lorehold spellslinger lists support Storm-Kiln Artist and spell-pressure cards as ideas, but popularity is priority evidence, not promotion permission.

## Decision

- keep_607_as_protected_baseline: `true`
- deck_action_allowed: `false`
- candidate_deck_materialization_allowed_now: `false`
- promotion_allowed: `false`
- reason: The next learnable shell is Guttersnipe plus Storm-Kiln Artist, but current evidence has zero named seed-safe cuts and generic staples remain learning-only. Deck 607 stays protected.

## Validation

- PASS: next shell is documented as learning-only under current evidence.
