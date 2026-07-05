# Lorehold Learning Frontier After Probe Closure

- Generated at: `2026-07-05T15:56:38Z`
- PostgreSQL writes: `false`
- Source DB mutated: `false`
- Deck 607 mutated: `false`
- Status: `learning_frontier_closed_execution_routes_keep_607`
- Selected next route: `topdeck_floor_trace_target_contract`
- Recommended next action: `write_topdeck_floor_trace_target_contract_before_any_matrix_row`
- Candidate materialization allowed: `false`
- Natural battle gate allowed: `false`
- Promotion allowed: `false`
- Probe rows: `48`
- Queue rows: `40`
- Matrix-eligible rows: `0`
- Safe-cut ready: `0`
- Mana eligible pairs: `0`

## Source Reports

- `candidate_queue`: `docs/hermes-analysis/master_optimizer_reports/lorehold_topdeck_sidecar_candidate_queue_20260705_current.json`
- `hypothesis_queue`: `docs/hermes-analysis/master_optimizer_reports/lorehold_hypothesis_queue_from_value_model_20260705_current_relearn.json`
- `mana_decision_integrator`: `docs/hermes-analysis/master_optimizer_reports/lorehold_mana_base_decision_integrator_20260705_after_plateau_turbulent_current.json`
- `post_safe_cut_route`: `docs/hermes-analysis/master_optimizer_reports/lorehold_topdeck_post_safe_cut_route_20260705_current.json`
- `probe_evidence`: `docs/hermes-analysis/master_optimizer_reports/lorehold_topdeck_sidecar_probe_evidence_miner_20260705_current.json`
- `shell_failure_synthesis`: `docs/hermes-analysis/master_optimizer_reports/lorehold_from_scratch_shell_failure_synthesis_20260705_current_relearn.json`

## Learning Frontiers

| Frontier | Status | Allowed | Natural Battle | Reason |
| --- | --- | --- | --- | --- |
| `mana_base_pair_frontier` | `closed_by_exact_pair_decisions` | `false` | `false` | The dedicated mana-base integrator has zero eligible pairs after exact Plateau decisions. |
| `topdeck_sidecar_matrix_rows` | `closed_no_matrix_rows` | `false` | `false` | The sidecar queue has no row eligible for matrix scoring or materialization. |
| `one_for_one_safe_cut_frontier` | `closed_zero_seed_safe_cuts` | `false` | `false` | The current 607 one-for-one frontier has zero seed-safe cuts. |
| `natural_gate_watchlist` | `blocked_no_current_natural_gate` | `false` | `false` | The hypothesis queue reports zero current natural-gate-ready packages. |
| `forced_access_diagnostic_frontier` | `closed_no_runnable_forced_access` | `false` | `false` | The post-safe-cut route has no runnable forced-access command now. |
| `from_scratch_shell_frontier` | `blocked_prior_shell_failures` | `false` | `false` | Prior from-scratch shells are rejected or non-promotable; a new shell needs a declared trace target. |
| `generic_staple_frontier` | `closed_until_same_lane_cut_and_trace_proof` | `false` | `false` | Mana Vault and The One Ring remain hypotheses, not accessible deck changes for 607. |
| `topdeck_floor_trace_target_contract` | `learning_only_next` | `true` | `false` | The next valid learning step is to define trace-floor targets for topdeck cards before any matrix row. |

## External Learning Refresh

- `Scryfall Lorehold, the Historian`: https://scryfall.com/card/sos/201/lorehold-the-historian
  - learning_use: Oracle and ruling source for the commander's miracle/topdeck timing.
  - guardrail: Oracle/ruling data validates behavior, not a replacement decklist.
- `EDHREC Lorehold commander pages`: https://edhrec.com/commanders/lorehold-the-historian
  - learning_use: Public topdeck, spellslinger, discard, and combo lanes for candidate discovery.
  - guardrail: Commander adoption is source evidence, not same-lane cut proof.
- `Commander Spellbook Storm-Kiln Artist + Haze of Rage`: https://commanderspellbook.com/combo/3940-5195/
  - learning_use: Combo package discovery for future Storm-Kiln pressure/conversion research.
  - guardrail: Combo existence does not bypass runtime, cut, matrix, or battle gates.

## Decision

- keep_607_as_protected_baseline: `true`
- allow_deck_mutation_now: `false`
- allow_candidate_materialization_now: `false`
- allow_structure_matrix_now: `false`
- allow_forced_access_now: `false`
- allow_natural_battle_gate_now: `false`
- promotion_allowed: `false`
- reason: Current execution frontiers are closed: no safe cut, no matrix row, no eligible mana pair, no runnable natural gate, and no promotable from-scratch shell. The next valid work is learning-only trace targeting before any deck action.
- blocked_actions:
  - `do_not_mutate_deck_607`
  - `do_not_write_postgresql_or_sqlite`
  - `do_not_materialize_sidecar_deck_from_watchlist_only`
  - `do_not_retest_exact_plateau_pairs_without_new_mana_evidence`
  - `do_not_promote_mana_vault_or_the_one_ring_without_same_lane_trace_proof`
- next_actions:
  - `write_topdeck_floor_trace_target_contract_before_any_matrix_row`
  - `define floor trace metrics for the selected topdeck target cards`
  - `route pressure and spell-chain followups only after the topdeck floor is preserved`
  - `refresh external sources as candidate discovery only, not promotion proof`
