# Battle Strategy Learning Confidence Scope Audit - 2026-06-19T19:16Z

## Scope

This audit checks whether the current recurring battle result can be read as all
seeds being high-confidence strategy-learning samples.

No code, PostgreSQL data, swaps, or commits were changed.

## Sources

- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/latest/summary.json`
- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/latest/summary.md`
- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/latest/research_review.json`
- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/latest/research_review.md`
- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/latest/seed_*/strategy_audit.json`
- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/latest/seed_*/strategy_audit.md`
- `docs/hermes-analysis/BATTLE_REPLAY_GATE_MATRIX.md`
- `docs/hermes-analysis/BATTLE_VALIDATION_REGISTER_2026-06-19.md`

## Current Latest State

- `timestamp_utc`: `2026-06-19T18:47:21Z`
- `battle_replay_final_status`: `trusted_for_strategy_learning`
- `battle_replay_final_status_reason`: `all_mandatory_gates_pass`
- `mandatory_gate_divergences`: `[]`
- `mandatory_gate_statuses.strategy_audit.status`: `pass`
- `strategy_findings`: `3`
- `strategy_low_confidence_findings`: `3`
- `strategy_review_required_findings`: `0`
- `strategy_code_counts`: `{"forced_keep_after_bad_mulligan": 3}`
- `strategy_severity_counts`: `{"medium": 3}`
- `research_statuses.mulligan`: `blocked_or_needs_review`
- `seeds_with_strategy_blockers`: `[]`

## Learning Confidence Split

The current latest result separates high-confidence and low-confidence strategy
learning samples:

- `strategy_learning_confidence_counts`:
  `{"high_confidence_replay": 13, "low_confidence_replay": 3}`
- `strategy_high_confidence_learning_seeds`:
  `["63201734","63201735","63201736","63201737","63201738","63201742","63201743","63201744","63201745","63201746","63201747","63201748","63201749"]`
- `strategy_low_confidence_seeds`:
  `["63201739","63201740","63201741"]`
- `strategy_not_learning_eligible_seeds`: `[]`

## Low-Confidence Seeds

Each low-confidence seed has one medium finding:

| Seed | Finding | Verdict | High-confidence eligible | Weight | Reason |
| --- | ---: | --- | --- | ---: | --- |
| `63201739` | `1` | `low_confidence_replay` | `False` | `0.0` | `forced_keep_after_bad_mulligan` |
| `63201740` | `1` | `low_confidence_replay` | `False` | `0.0` | `forced_keep_after_bad_mulligan` |
| `63201741` | `1` | `low_confidence_replay` | `False` | `0.0` | `forced_keep_after_bad_mulligan` |

The per-seed recommendations say to track these replays separately and not
treat the resulting WR as high-confidence deck quality.

## Gate Matrix Check

`docs/hermes-analysis/BATTLE_REPLAY_GATE_MATRIX.md` already documents this
contract:

- low-confidence strategy findings remain visible;
- forced mulligan-cap keeps get `high_confidence_learning_weight=0.0`;
- `strategy_audit.status` can pass when only low-confidence findings remain;
- `strategy_review_required_findings` identifies findings that keep the
  strategy gate in review.

## Finding

No new open battle finding is required in this pass. `BV-056` was closed
correctly for the current recurring surface because the summary, research
review, per-seed strategy reports, and gate matrix all distinguish:

- aggregate final trusted status;
- high-confidence strategy-learning seeds;
- low-confidence seeds with weight `0.0`.

The operational rule remains:

`trusted_for_strategy_learning` does not mean every seed is a high-confidence
strategy sample. It means all mandatory gates passed, while per-seed learning
confidence still controls which seeds should contribute to high-confidence
learning or WR interpretation.

## Recommended Follow-up

- Continue reporting `strategy_learning_confidence_counts`,
  `strategy_high_confidence_learning_seeds`, and `strategy_low_confidence_seeds`
  whenever citing `battle_replay_final_status=trusted_for_strategy_learning`.
- Keep `mulligan` flagged as `blocked_or_needs_review` in research output until
  forced mulligan-cap keeps no longer appear or have a better accepted model.
- Do not use low-confidence seeds for WR/baseline/handoff claims unless the
  output explicitly marks them as low-confidence and excludes them from
  high-confidence evidence.
