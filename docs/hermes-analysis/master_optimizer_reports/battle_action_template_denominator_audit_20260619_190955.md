# Battle Action Template Denominator Audit - 2026-06-19T19:09Z

## Scope

This audit checks whether the current battle artifacts support the claim that
card action templates are complete. It separates four denominators:

- unknown card backlog;
- focused template dispatch readiness;
- effect coverage residual flags;
- rule review/runtime-safe status.

No code, PostgreSQL data, swaps, or commits were changed.

## Sources

- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/latest/summary.json`
- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/latest/effect_coverage.json`
- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/latest/effect_coverage.md`
- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/latest/effect_coverage_residual.json`
- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/latest/focused_template_dispatch.json`
- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/latest/focused_template_dispatch.md`
- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/latest/unknown_template_backlog.json`
- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/latest/unknown_template_backlog.md`

## Current Latest State

- `timestamp_utc`: `2026-06-19T18:47:21Z`
- `battle_replay_final_status`: `trusted_for_strategy_learning`
- `mandatory_gate_divergences`: `[]`
- `seeds_with_high_or_critical_action_findings`: `[]`
- `seeds_with_strategy_blockers`: `[]`

## Unknown Backlog

The unknown backlog is currently clear:

- `unknown_template_backlog_status`: `focused_template_backlog_ready`
- `unknown_template_backlog_cards`: `0`
- `unknown_template_without_current_inferred_family`: `0`
- `unknown_template_without_reviewed_family`: `0`
- `unknown_template_without_focused_template_match`: `0`
- `unknown_template_without_plan_or_waiver`: `0`

Reading: the current unknown-card backlog does not need additional template
plans before the latest gate can pass.

## Focused Template Dispatch

Focused template dispatch is currently ready:

- `focused_template_dispatch_status`: `focused_template_dispatch_ready`
- `focused_template_cards`: `29`
- `focused_template_predicate_match`: `29`
- `focused_template_without_predicate_match`: `0`
- `focused_template_evidence_dispatch_ready`: `29`
- `focused_template_without_evidence_dispatch`: `0`
- `focused_template_evidence_ready`: `29`
- `focused_template_evidence_not_ready_unwaived`: `0`
- `focused_template_supports_template_count`: `47`
- `focused_template_evaluate_dispatch_template_count`: `47`
- `focused_template_build_evidence_function_count`: `47`
- `focused_template_accepted_waivers`: `0`

Reading: it is accurate to say the current focused template backlog is ready.
It is not accurate to generalize this as all card action effects being fully
modeled.

## Effect Coverage

Current effect coverage denominator:

- `total_card_instances`: `1288`
- `unique_cards`: `556`
- `runtime_safe_rule_names`: `1702`
- `active_or_review_rule_names`: `3159`
- `non_runtime_safe_rule_names`: `1457`
- `needs_review_rule_names`: `1457`
- `review_only_rule_names`: `0`
- `review_status_counts`: `{"active": 27, "needs_review": 1457, "verified": 1675}`

Source totals:

| Source | Count |
| --- | ---: |
| `battle_rule_curated` | `724` |
| `battle_rule_needs_review_generated` | `34` |
| `effect_map` | `100` |
| `focused_template_ready` | `33` |
| `handcrafted` | `2` |
| `tag` | `18` |
| `type_land` | `377` |

Reading: `review_only_rule_names=0` is not a proof that review backlog is gone.
The live denominator for rules that are not runtime-safe is
`needs_review_rule_names=1457` / `non_runtime_safe_rule_names=1457`.

## Residual Flags

Current residual status:

- `effect_coverage_residual_status`: `effect_coverage_residual_accepted`
- `effect_coverage_residual_raw_flag_total`: `539`
- `effect_coverage_residual_card_flag_rows`: `293`
- `effect_coverage_residual_unique_flagged_cards`: `240`
- `effect_coverage_residual_unaccepted_card_flag_rows`: `0`
- `effect_coverage_residual_raw_unaccepted_flags`: `[]`

Accepted residual owner totals:

| Owner | Accepted rows |
| --- | ---: |
| `battle-effect-contract` | `153` |
| `battle-heuristic-fallback` | `90` |
| `battle-land-utility-contract` | `21` |
| `battle-rule-review-queue` | `29` |

Accepted residual flag totals:

| Flag | Accepted rows |
| --- | ---: |
| `heuristic_effect` | `90` |
| `trigger_not_explicit` | `63` |
| `temporary_effect_not_explicit` | `38` |
| `cast_permission_not_explicit` | `35` |
| `needs_review_rule` | `29` |
| `land_utility_ability_not_modeled` | `21` |
| `oracle_target_removal_mismatch` | `12` |
| `oracle_silence_mismatch` | `4` |
| `copy_effect_mismatch` | `1` |

Reading: all residual rows are accepted by policy, but accepted residuals are
still a separate denominator from card-specific runtime support.

## Finding

The current artifacts support this precise statement:

> Unknown backlog is zero, focused template dispatch is ready for the current
> 29 focused cards, and all residual flags are accepted by explicit policies.

They do not support this broader statement:

> All card action templates/effects in the battle corpus are fully modeled as
> runtime-safe card-specific behavior.

The main ambiguity is naming: a reader can see `review_only_rule_names=0` and
miss the larger `needs_review_rule_names=1457` /
`non_runtime_safe_rule_names=1457` denominator. Reports and future handoffs
should always surface those fields together.

## Recommended Follow-up

- Keep `focused_template_dispatch_ready` scoped to the `29` focused cards and
  the `47` current support/build/dispatch functions.
- When reporting "all templates", always include:
  - `unknown_template_backlog_cards`
  - `focused_template_cards`
  - `focused_template_evidence_ready`
  - `effect_coverage_residual_card_flag_rows`
  - `effect_coverage_residual_raw_flag_total`
  - `needs_review_rule_names`
  - `non_runtime_safe_rule_names`
  - `runtime_safe_rule_names`
- Treat `review_only_rule_names=0` as a narrow field, not as proof that
  `needs_review` rule backlog is gone.
