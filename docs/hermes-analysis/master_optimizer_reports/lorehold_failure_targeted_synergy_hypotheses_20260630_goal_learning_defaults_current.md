# Lorehold Failure-Targeted Synergy Hypotheses - 2026-06-28

- Generated at: `2026-06-30T20:26:02Z`
- Strategy audit: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_strategy_learning_audit_20260628_v2_runtime_packages.json`
- Hypothesis queue: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_next_hypothesis_queue_20260630_after_profiled_gate.json`
- Next action planner: `docs/hermes-analysis/master_optimizer_reports/lorehold_next_action_planner_20260630_goal_learning_defaults_current.json`
- Source DB: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db`
- PostgreSQL writes: `false`
- Source DB mutated: `false`

## Summary

- Recommended next action: `run_failure_targeted_trace_audit`
- Focus cards: `7`
- Weak seed findings: `2`
- Hypotheses: `4`
- Hypothesis statuses: `{"runtime_utilization_audit_required": 1, "trace_audit_required": 3}`
- Queue gate-ready/tested-negative: `0` / `13`

## Weak Seed Findings

| Seed | Finding | Record | Topdeck Rate | Miracle Rate | Squee Missing |
| ---: | --- | --- | ---: | ---: | --- |
| 7 | `missing_or_low_engine_access` | `0-9-0` | 0.1111 | 0.4444 | `true` |
| 20260625 | `engine_seen_but_conversion_failed` | `0-9-0` | 0.1111 | 0.2222 | `true` |

## Engine Profiles

- `Urza's Saga`: decks `6,606,607,608,609,610,611,612,613,614,615`, champion_inferred=`false`, active_rules=`2`, scopes=`saga_land_token_then_tutor_partial_v1`, notes=`saga_rule_scope_partial, saga_tutor_cmc_max_below_top_or_library`
- `Library of Leng`: decks `6,606,607,608,609,610,611,612,613,614,615`, champion_inferred=`false`, active_rules=`1`, scopes=`discard_replacement_to_top_v1`, notes=`-`
- `Sensei's Divining Top`: decks `6,606,607,608,609,610,611,612,613,614,615,616`, champion_inferred=`false`, active_rules=`1`, scopes=`senseis_top_reorder_and_draw_put_self_on_top_runtime_v1`, notes=`-`
- `Scroll Rack`: decks `6,607,608,609,610,611,612,613,614,616`, champion_inferred=`false`, active_rules=`1`, scopes=`scroll_rack_upkeep_single_exchange_v1`, notes=`-`
- `Squee, Goblin Nabob`: decks `6,609,610`, champion_inferred=`true`, active_rules=`1`, scopes=`graveyard_upkeep_return_self_to_hand_v1`, notes=`-`
- `The Mind Stone`: decks `6,607`, champion_inferred=`false`, active_rules=`1`, scopes=`legendary_artifact_mana_harness_and_end_step_blink_other_nonland_permanent_v1`, notes=`blink_value_requires_target_trace`
- `Land Tax`: decks `6,606,607,609,610,611,613,614,615`, champion_inferred=`false`, active_rules=`1`, scopes=`land_tax_upkeep_opponent_more_lands_basic_land_tutor_to_hand_v1`, notes=`-`

## Hypotheses

### trace_seed7_engine_access_sequence

- Status: `trace_audit_required`
- Target failure: seed 7 missing or low engine access
- Target seeds: `7`
- Focus cards: Urza's Saga, Library of Leng, Sensei's Divining Top, Scroll Rack, Squee, Goblin Nabob
- Why: Seed 7 is 0-9 with topdeck manipulation far below seed 42 and no Squee graveyard/return route, so another card swap is premature.
- Required evidence: per-game opening/early-turn presence for Library, Top, Rack, Urza's Saga, and Squee
- Required evidence: whether Urza's Saga resolves artifact tutor value before the game is lost
- Required evidence: whether the commander rummage ever has Squee in hand and chooses a graveyard route
- Gate after trace: only build a package if the trace identifies a missing access route or unused in-deck engine

### trace_seed20260625_conversion_window

- Status: `trace_audit_required`
- Target failure: engine appears but fails to convert
- Target seeds: `20260625`
- Focus cards: Library of Leng, Sensei's Divining Top, Scroll Rack, The Mind Stone, Land Tax
- Why: Seed 20260625 still sees Lorehold upkeep rummage often but remains 0-9, with low miracle/topdeck conversion and no Squee recursion route.
- Required evidence: whether discard-to-top produces Approach, protection, or a finisher window
- Required evidence: whether The Mind Stone blink has a high-value target or is only incidental ramp
- Required evidence: whether Land Tax thins/fixes mana early enough to increase spell-chain density
- Gate after trace: prefer conversion/support package only if it preserves seed-42 miracle/topdeck telemetry

### audit_urzas_saga_artifact_tutor_scope

- Status: `runtime_utilization_audit_required`
- Target failure: existing engine may be under-modeled
- Target seeds: `7, 20260625, 42`
- Focus cards: Urza's Saga, Sensei's Divining Top, Library of Leng
- Why: Urza's Saga is already in the champion shell, but active rule metadata includes partial Saga scope or artifact tutor CMC limits that may miss key one-mana artifacts.
- Required evidence: confirm chapter progression, construct creation, tutor target choice, and sacrificed state in natural games
- Required evidence: verify whether Top/Library-class targets are intentionally reachable or excluded by the battle model
- Gate after trace: fix runtime/model first if Saga cannot find relevant artifacts before testing new cards

### audit_squee_graveyard_entry_route

- Status: `trace_audit_required`
- Target failure: Squee value exists but not through Lorehold discard
- Target seeds: `7, 20260625, 42`
- Focus cards: Squee, Goblin Nabob, Library of Leng, Lorehold, the Historian
- Why: The champion has Squee returns after known graveyard entry, but Lorehold rummage has not been observed discarding Squee. The deck may need sequencing logic before a card swap.
- Required evidence: trace every Squee hand/graveyard move and the source reason
- Required evidence: verify whether Library replacement conflicts with putting Squee into the graveyard
- Gate after trace: only test discard enablers if Squee is present but cannot enter graveyard naturally

## Guardrails

- Do not register a new add/cut package while the current queue is fully prior-negative.
- Do not cut protected or locked cards without same-lane proof.
- Preserve seed-42 miracle/topdeck telemetry as the first regression check.
- Treat runtime/model underutilization as a blocker before judging a card as strategically bad.
