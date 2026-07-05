# Lorehold Topdeck Non-Anchor Cut Model Miner

- Generated at: `2026-07-05T07:16:34Z`
- PostgreSQL writes: `false`
- Source DB mutated: `false`
- Deck 607 mutated: `false`
- Status: `topdeck_nonanchor_cut_model_none_found_keep_607`
- Primary target: `Dragon's Rage Channeler`
- Primary target status: `clean_prior_target_blocked_no_nonanchor_cut`
- Seed-safe non-anchor count: `0`
- Reviewable non-anchor gap count: `0`
- Forced access allowed now: `false`
- Structure matrix allowed now: `false`
- Natural battle gate allowed now: `false`
- Promotion allowed now: `false`
- Recommended next action: `collect_new_cut_evidence_or_define_new_shell_contract_before_execution`

## Source Reports

- `safe_cut_miner`: `docs/hermes-analysis/master_optimizer_reports/lorehold_topdeck_safe_cut_miner_20260705_current.json`
- `trace_cut_expander`: `docs/hermes-analysis/master_optimizer_reports/lorehold_trace_cut_evidence_expander_20260704_role_tag_repair.json`
- `trace_evidence`: `docs/hermes-analysis/master_optimizer_reports/lorehold_topdeck_floor_trace_evidence_collector_20260705_current.json`

## Target Models

| Card | Status | Same-Lane Slots | Seed-Safe | Reviewable | Prior Rejects | Next Action |
| --- | --- | ---: | ---: | ---: | ---: | --- |
| `Dragon's Rage Channeler` | `clean_prior_target_blocked_no_nonanchor_cut` | 6 | 0 | 0 | 0 | mine_external_or_new_trace_evidence_for_nonanchor_cut |
| `Penance` | `prior_reject_target_blocked_no_nonanchor_cut` | 20 | 0 | 0 | 2 | do_not_retest_prior_pair_without_new_cut_model |
| `Galvanoth` | `prior_reject_target_blocked_no_nonanchor_cut` | 8 | 0 | 0 | 4 | do_not_retest_prior_pair_without_new_cut_model |
| `Valakut Awakening // Valakut Stoneforge` | `prior_reject_target_blocked_no_nonanchor_cut` | 13 | 0 | 0 | 1 | do_not_retest_prior_pair_without_new_cut_model |
| `Wheel of Fortune` | `prior_reject_target_blocked_no_nonanchor_cut` | 13 | 0 | 0 | 1 | do_not_retest_prior_pair_without_new_cut_model |

## Primary Target Blocked Slots

- `Call Forth the Tempest` (spell_velocity): `blocked_by_hard_stop`; blockers: cut_is_miracle_core_big_spell, miracle_or_finisher_core, structural_dependency
- `Everything Comes to Dust` (spell_velocity): `blocked_by_hard_stop`; blockers: cut_is_miracle_core_big_spell, miracle_or_finisher_core, structural_dependency
- `Hexing Squelcher` (contextual): `blocked_by_hard_stop`; blockers: prior_rejected_cut, protected_cut
- `Blasphemous Act` (spell_velocity): `blocked_by_hard_stop`; blockers: cut_is_early_mana_floor_support, cut_is_miracle_core_big_spell, measured_high_cut_exposure, miracle_or_finisher_core, structural_dependency
- `Farewell` (spell_velocity): `blocked_by_hard_stop`; blockers: cut_is_miracle_core_big_spell, measured_high_cut_exposure, miracle_or_finisher_core, structural_dependency
- `Starfall Invocation` (spell_velocity): `blocked_by_hard_stop`; blockers: cut_is_miracle_core_big_spell, measured_high_cut_exposure, miracle_or_finisher_core, structural_dependency

## External Refresh Notes

- `Scryfall Dragon's Rage Channeler`: https://scryfall.com/search?q=dragon%27s+rage+channeler - Oracle text does not create a safe cut or prove it belongs in deck 607.
- `Scryfall Penance`: https://scryfall.com/search?q=Penance - Card-mechanic fit still needs same-lane cut and local trace floors.
- `EDHREC Lorehold pages`: https://edhrec.com/commanders/lorehold-the-historian - EDHREC is discovery/provenance, not deck-change proof.

## Decision

- keep_607_as_protected_baseline: `true`
- allow_deck_mutation_now: `false`
- allow_candidate_materialization_now: `false`
- allow_forced_access_now: `false`
- allow_structure_matrix_now: `false`
- allow_natural_battle_gate_now: `false`
- promotion_allowed: `false`
- reason: The current cut-slot evidence has no seed-safe or reviewable non-anchor same-lane cut for the topdeck targets. Dragon's Rage Channeler remains the cleanest target by prior-result history, but its same-lane slots are hard-blocked.
- next_actions:
  - `collect_new_cut_evidence_or_define_new_shell_contract_before_execution`
  - `do_not_execute_forced_access_without_a_named_safe_cut`
  - `do_not_reuse_protected_or_prior_rejected_cut_slots`
  - `keep 607 protected until equal gate and trace evidence prove a replacement`
