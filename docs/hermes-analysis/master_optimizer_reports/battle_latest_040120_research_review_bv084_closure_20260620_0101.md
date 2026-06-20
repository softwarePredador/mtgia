# Battle Latest 040120 Research Review BV-084 Closure

Status: `BV-084` closed on 2026-06-20T01:01:00-03:00.

Scope: research-review observability only. No PostgreSQL writes, no deck swap,
and no battle rule promotion.

## Sources

- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260620_040120/summary.json`
- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260620_040120/research_review.json`
- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260620_040120/research_review.md`
- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260620_040120/test_results.jsonl`
- `docs/hermes-analysis/manaloom-knowledge/scripts/battle_decision_research_review.py`
- `docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_decision_research_review.py`

## Fix

`battle_decision_research_review.py` now keeps per-category `finding_samples`.
Each sample joins a strategy finding to its replay decision by `decision_id` and
publishes `seed`, `decision_id`, `decision_type`, `code`, `severity`, `detail`,
`recommendation`, `chosen_option`, `reason`, `risk_flags`, `player`, `turn`,
`phase`, and `actual_outcome`.

The Markdown renderer now prints a finding table with:

`Seed | Decision | Code | Severity | Chosen option | Reason | Risk flags | Detail`

## Evidence

- `summary.json`: `run_scope=recurring_full`, `seeds_requested=16`,
  `seeds_completed=16`, `battle_replay_final_status=trusted_for_strategy_learning`,
  `mandatory_gate_divergences=[]`, `test_results_total=16`, and
  `test_results_status_counts={"pass":16}`.
- `test_results.jsonl`: `test_battle_decision_research_review` passed with
  `exit_code=0`.
- `research_review.json`: `categories.mulligan.finding_codes={"forced_keep_after_bad_mulligan":6}`
  and `len(categories.mulligan.finding_samples)=6`.
- Current samples:
  - `63210405/decision-000007`
  - `63210405/decision-000011`
  - `63210407/decision-000006`
  - `63210410/decision-000010`
  - `63210415/decision-000005`
  - `63210416/decision-000009`
- `research_review.md` contains the finding table for
  `forced_keep_after_bad_mulligan`.

Result: `BV-084` is removed from the open register. The mulligan category can
remain `blocked_or_needs_review` as strategy evidence, but the artifact now
identifies the exact seeds and decisions to inspect.
