# Lorehold Brain in a Jar Seed-Safe Cut Unlock Audit

- Generated at: `2026-07-05T11:55:48Z`
- PostgreSQL writes: `false`
- Source DB mutated: `false`
- Deck 607 mutated: `false`
- Decision status: `brain_seed_safe_cut_unlock_audit_closed_no_unlockable_cut_keep_607`
- Brain safe-cut gap status: `brain_safe_cut_gap_no_seed_safe_cut_keep_607`
- Active Brain rule count: `1`
- Brain PostgreSQL rule active confirmed now: `true`
- Brain apply confirmed outside package script: `true`
- Brain PG package route governed: `true`
- Safe cut count: `0`
- Unlockable now: `0`
- Diagnostic focus: `Molecule Man`
- Targeted floor trace missing slots: `0`
- Current best status: `current_best_baseline_synthesis_keep_607`
- Current best top deck is 607: `true`
- Matrix scoring allowed now: `false`
- Candidate deck materialization allowed now: `false`
- Natural battle gate allowed now: `false`
- Recommended next action: `continue_seed_safe_cut_discovery_no_deck_action`

## Source Reports

- `current_best`: `docs/hermes-analysis/master_optimizer_reports/lorehold_current_best_baseline_synthesis_20260705_current.json`
- `cut_slot_trace`: `docs/hermes-analysis/master_optimizer_reports/lorehold_brain_cut_slot_trace_miner_20260705_current_summary.json`
- `safe_cut_gap`: `docs/hermes-analysis/master_optimizer_reports/lorehold_brain_safe_cut_gap_audit_20260705_post_authorized_full_validation.json`

## External Deckbuilding Lessons

- EDHREC Lorehold commander page: Lorehold's public profile is Topdeck, Spellslinger, and Discard; high-synergy topdeck anchors include Library of Leng, Sensei's Divining Top, and Scroll Rack. Guardrail: External adoption discovers lanes; it is not local cut proof. (https://edhrec.com/commanders/lorehold-the-historian)
- Wizards Commander Brackets Beta: Mana Vault and The One Ring are treated as Game Changers because fast mana and overwhelming resource advantage can change table power. Guardrail: A Game Changer label raises review burden; it does not bypass the 607 same-lane cut and battle gates. (https://magic.wizards.com/en/news/announcements/introducing-commander-brackets-beta)
- Official Commander banned list: Legality and bracket pressure are separate checks. Guardrail: Legal cards still need role fit, cut safety, and trace evidence. (https://mtgcommander.net/index.php/banned-list/)

## Unlock Classes

- `diagnostic_only_prior_reject_requires_new_trace`: `2`
- `locked_no_unlock_current_607_contract`: `2`
- `protected_floor_requires_floor_replacement_trace`: `2`
- `protected_topdeck_anchor_requires_role_preservation`: `3`

## Slot Queue

| Slot | Unlock class | Role requirement | Exposure | Floor trace | Missing evidence | Action |
| --- | --- | --- | ---: | --- | --- | --- |
| Molecule Man | `diagnostic_only_prior_reject_requires_new_trace` | preserve_topdeck_miracle_access_or_discard_to_top_role | 102 | `brain_cut_slot_floor_trace_found_cut_blocked` | named_same_lane_seed_safe_cut_evidence, new_trace_evidence_reverses_prior_rejected_cut, refresh_candidate_queue_and_strategy_matrix, battle_gate_only_after_matrix_candidate | mine_new_trace_evidence_before_reopening_prior_rejected_cut |
| Land Tax | `diagnostic_only_prior_reject_requires_new_trace` | preserve_topdeck_miracle_access_or_discard_to_top_role | 3449 | `brain_cut_slot_floor_trace_found_cut_blocked` | named_same_lane_seed_safe_cut_evidence, new_trace_evidence_reverses_prior_rejected_cut, refresh_candidate_queue_and_strategy_matrix, battle_gate_only_after_matrix_candidate | mine_new_trace_evidence_before_reopening_prior_rejected_cut |
| Library of Leng | `protected_topdeck_anchor_requires_role_preservation` | preserve_topdeck_miracle_access_or_discard_to_top_role | 855 | `brain_cut_slot_floor_trace_found_cut_blocked` | named_same_lane_seed_safe_cut_evidence, replacement_preserves_topdeck_miracle_anchor_role, refresh_candidate_queue_and_strategy_matrix, battle_gate_only_after_matrix_candidate | prove_replacement_preserves_topdeck_miracle_anchor_before_matrix |
| Scroll Rack | `protected_topdeck_anchor_requires_role_preservation` | preserve_topdeck_miracle_access_or_discard_to_top_role | 2957 | `brain_cut_slot_floor_trace_found_cut_blocked` | named_same_lane_seed_safe_cut_evidence, replacement_preserves_topdeck_miracle_anchor_role, refresh_candidate_queue_and_strategy_matrix, battle_gate_only_after_matrix_candidate | prove_replacement_preserves_topdeck_miracle_anchor_before_matrix |
| Sensei's Divining Top | `protected_topdeck_anchor_requires_role_preservation` | preserve_topdeck_miracle_access_or_discard_to_top_role | 3816 | `brain_cut_slot_floor_trace_found_cut_blocked` | named_same_lane_seed_safe_cut_evidence, replacement_preserves_topdeck_miracle_anchor_role, refresh_candidate_queue_and_strategy_matrix, battle_gate_only_after_matrix_candidate | prove_replacement_preserves_topdeck_miracle_anchor_before_matrix |
| The Scarlet Witch | `protected_floor_requires_floor_replacement_trace` | preserve_topdeck_miracle_access_or_discard_to_top_role | 362 | `brain_cut_slot_floor_trace_found_cut_blocked` | named_same_lane_seed_safe_cut_evidence, replacement_preserves_mana_or_curve_floor, refresh_candidate_queue_and_strategy_matrix, battle_gate_only_after_matrix_candidate | collect_floor_replacement_trace_before_matrix |
| The Mind Stone | `protected_floor_requires_floor_replacement_trace` | preserve_topdeck_miracle_access_or_discard_to_top_role | 2312 | `brain_cut_slot_floor_trace_found_cut_blocked` | named_same_lane_seed_safe_cut_evidence, replacement_preserves_mana_or_curve_floor, refresh_candidate_queue_and_strategy_matrix, battle_gate_only_after_matrix_candidate | collect_floor_replacement_trace_before_matrix |
| Urza's Saga | `locked_no_unlock_current_607_contract` | not_applicable_never_cut_slot | 2656 | `brain_cut_slot_floor_trace_found_cut_blocked` | cannot_unlock_under_current_607_contract | do_not_use_as_brain_cut_under_current_607_contract |
| Lorehold, the Historian | `locked_no_unlock_current_607_contract` | not_applicable_never_cut_slot | 5768 | `brain_cut_slot_floor_trace_found_cut_blocked` | cannot_unlock_under_current_607_contract | do_not_use_as_brain_cut_under_current_607_contract |

## Decision

- keep_607_as_protected_baseline: `true`
- brain_cut_unlocked_now: `false`
- deck_action_allowed: `false`
- natural_battle_allowed_now: `false`
- pg_apply_requires_explicit_approval: `false`
- reason: Brain in a Jar already has an active PostgreSQL-backed rule, but no seed-safe cut is unlocked. Current slots are either never-cut, protected anchors/floors, or prior-rejected diagnostic rows that need new trace evidence before matrix scoring.
- next_actions:
  - do_not_mutate_deck_607
  - do_not_materialize_brain_candidate_deck
  - do_not_run_natural_battle_from_this_audit
  - brain_rule_already_active_no_pg_apply_needed
  - use_brain_cut_slot_traces_as_cut_protection_evidence
  - reopen_prior_rejected_slots_only_with_new_same_lane_trace_evidence
