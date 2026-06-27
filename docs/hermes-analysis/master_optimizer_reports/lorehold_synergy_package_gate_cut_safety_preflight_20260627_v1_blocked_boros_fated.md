# Lorehold Synergy Package Gate

- generated_at: `2026-06-27T19:20:01.610502+00:00`
- source_db: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_squee_equal_gate_rerun_20260627_010256_squee_goblin_nabob/knowledge_candidate.db`
- source_db_mutated: `false`
- games_per_opponent: `1`
- opponent_limit: `1`
- opponent_seed: `20260626`
- simulation_seed: `42`
- cut_safety_report: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_strategy_learning_audit_20260627_v1.json`

| Package | Family | Adds | Cuts | Preflight | Baseline | Candidate | Delta | Strategic Delta | Decision |
| --- | --- | --- | --- | --- | --- | --- | ---: | --- | --- |
| boros_charm_pressure_cut_fated | pressure_absorber | Boros Charm | Fated Clash | `blocked_cut_safety` | - | - | +0.00 | - | skipped_cut_safety |

## Package Notes

### boros_charm_pressure_cut_fated

- family: pressure_absorber
- hypothesis: Boros Charm appears across the stronger Lorehold variants as cheap instant-speed protection/pressure absorption. This same-lane triage tests whether lowering a five-mana pressure-response slot into a two-mana modal protection spell improves the life-zero combat failures without cutting ramp, topdeck engines, High Noon, Hexing Squelcher, Storm Herd, or the protection shell.
- status: `skipped_cut_safety`
- cut_safety: `{"cuts": [{"best_delta_pp": -88.89, "card_name": "Fated Clash", "current_lane": "pressure_absorber_or_protection", "effective_role": "removal", "reason": "one or more packages collapsed the known strong seed when cutting this slot", "status": "locked_do_not_cut", "worst_strong_seed_delta_pp": -88.89}], "reason": "proposed cuts already have blocker evidence: Fated Clash", "status": "blocked_cut_safety"}`
- allow_miracle_core_cuts: `None`
- miracle_core_cuts: `-`
- added_rule_counts: `{}`
- candidate_db: `-`
- gate_markdown: `-`
- gate_json: `-`
- gate_returncode: `None`

