# Battle Focused Template Dispatch Gap Audit - 2026-06-19 17:32Z

## Scope

This report audits the latest state after `effect_coverage` moved the former
unknown cards to `source=focused_template_ready`. The question is whether those
focused template matches are executable by the focused evidence runner.

No PostgreSQL changes, no swaps, no product-code edits, and no commits were
performed.

Source artifacts:

- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260619_173213/summary.json`
- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260619_173213/effect_coverage.json`
- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-validation-register/focused_template_dispatch_gap_173213/focused_template_dispatch_gap.json`
- `server/bin/manaloom_battle_rule_focused_evidence.py`

## Current Gate Snapshot

| Metric | Value |
| --- | ---: |
| `battle_replay_final_status` | `review_required` |
| `mandatory_gate_divergences` | `["effect_coverage=review_required"]` |
| `effect_coverage_unknowns` | `0` |
| `source_totals.focused_template_ready` | `33` |
| `focused_template_cards` | `29` |
| `unknown_template_without_focused_template_match` | `0` |

The unknown counter is now clean, but the run still has
`effect_coverage=review_required` because other risk families remain:
`heuristic_effect`, `trigger_not_explicit`, `cast_permission_not_explicit`,
`temporary_effect_not_explicit`, `land_utility_ability_not_modeled`, and
`needs_review_rule`.

## Dispatch Surface

| Surface | Count |
| --- | ---: |
| `supports_*_template` functions in `manaloom_battle_rule_focused_evidence.py` | `47` |
| `supports_*_template` functions called by `evaluate_draft(...)` | `21` |
| `build_*_evidence` functions | `21` |
| `supports_*_template` functions not dispatched by `evaluate_draft(...)` | `26` |

Current `focused_template_ready` cards:

| Metric | Value |
| --- | ---: |
| Cards with `focused_template_matches` | `29` |
| Cards with dispatchable template match | `0` |
| Cards without dispatchable template match | `29` |
| `evaluate_draft(...)` statuses for those 29 cards | `{"unsupported": 29}` |

## Interpretation

`focused_template_ready` currently means a card matched a template predicate. It
does not mean the focused evidence runner can generate `focused_test.json`,
`replay_events.jsonl`, `decision_trace.jsonl`, or `replay_audit.json`.

For the current 29 former unknown cards, every matched `supports_*_template`
belongs to the non-dispatched surface. A dry evaluation through
`evaluate_draft(...)` returns:

- `status=unsupported`
- `reason=no_focused_evidence_template_for_effect_family`

This is a readiness gap in the gate semantics. It is valid for the audit to
separate "unknown effect has a reviewed focused template family" from "focused
evidence has been generated", but the names and summary counters should not make
those states look equivalent.

## Required Adjustment

The recurring gate should expose separate counters:

- `template_predicate_match`: matched by a `supports_*_template` predicate.
- `evidence_dispatch_ready`: routed by `evaluate_draft(...)`.
- `focused_evidence_ready`: artifacts generated and replay/action/decision
  checks passed.

The current focused-template cards should remain blocked from promotion or
learning-grade claims until they are either dispatchable and evidence-ready, or
explicitly waived with a reason.
