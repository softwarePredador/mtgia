# Battle Latest Strategy Learning Confidence Recheck - 2026-06-19 20:39Z

## Scope

Recheck the current `latest` battle-strategy audit for the strategy-learning
confidence split. The goal is to verify whether `trusted_for_strategy_learning`
can be read as all seeds being high-confidence learning samples.

This is a read-only documentation audit. No PostgreSQL, swaps, code edits, or
commits were performed.

## Sources

- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/latest/summary.json`
- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260619_203855/research_review.json`
- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260619_203855/research_review.md`
- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260619_203855/seed_63202025/strategy_audit.json`
- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260619_203855/seed_63202025/strategy_audit.md`
- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260619_203855/seed_63202025/replay.decision_trace.jsonl`
- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260619_203855/seed_63202025/action_critic.json`
- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260619_203855/seed_63202025/forensic_audit.json`
- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260619_203855/seed_63202025/replay_decision_audit.json`
- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260619_203855/seed_63202031/strategy_audit.json`
- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260619_203855/seed_63202031/strategy_audit.md`
- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260619_203855/seed_63202031/replay.decision_trace.jsonl`
- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260619_203855/seed_63202031/action_critic.json`
- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260619_203855/seed_63202031/forensic_audit.json`
- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260619_203855/seed_63202031/replay_decision_audit.json`
- `docs/hermes-analysis/BATTLE_REPLAY_GATE_MATRIX.md`
- `docs/hermes-analysis/master_optimizer_reports/battle_strategy_learning_confidence_scope_audit_20260619_191643.md`

## Current Latest

- Latest realpath:
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260619_203855`
- `timestamp_utc=2026-06-19T20:38:55Z`
- `battle_replay_final_status=trusted_for_strategy_learning`
- `battle_replay_final_status_reason=all_mandatory_gates_pass`
- `mandatory_gate_divergences=[]`
- `mandatory_gate_statuses.strategy_audit.status=pass`
- `mandatory_gate_statuses.strategy_audit.findings=2`
- `mandatory_gate_statuses.strategy_audit.low_confidence_findings=2`
- `mandatory_gate_statuses.strategy_audit.review_required_findings=0`
- `mandatory_gate_statuses.strategy_audit.blocking_seeds=[]`
- `seeds_with_strategy_blockers=[]`
- `seeds_with_high_or_critical_action_findings=[]`
- `seeds_with_high_or_critical_forensic_findings=[]`

## Learning Confidence Split

Current latest separates high-confidence from low-confidence strategy samples:

- `strategy_learning_confidence_counts={"high_confidence_replay":14,"low_confidence_replay":2}`
- `strategy_high_confidence_learning_seeds=["63202022","63202023","63202024","63202026","63202027","63202028","63202029","63202030","63202032","63202033","63202034","63202035","63202036","63202037"]`
- `strategy_low_confidence_seeds=["63202025","63202031"]`
- `strategy_not_learning_eligible_seeds=[]`
- `strategy_code_counts={"forced_keep_after_bad_mulligan":2}`
- `strategy_severity_counts={"medium":2}`

The `research_review` for this same run reports:

- `seeds=16`
- `finding_counts={"forced_keep_after_bad_mulligan":2}`
- `categories.mulligan.status=blocked_or_needs_review`
- `categories.mulligan.observed_decisions=108`
- `categories.mulligan.finding_count=2`

## Low-Confidence Seeds

Both low-confidence seeds are low because the mulligan cap forced a risky keep:

| Seed | Strategy verdict | Eligible | Weight | Finding detail |
| --- | --- | --- | ---: | --- |
| `63202025` | `low_confidence_replay` | `False` | `0.0` | `mana_screw`, `negative_keep_score`, `too_few_lands` |
| `63202031` | `low_confidence_replay` | `False` | `0.0` | `negative_keep_score`, `no_early_game_plan` |

Per-seed action, forensic, and replay-decision gates are clean for these two
seeds:

| Seed | Action findings | Forensic findings | Replay-decision findings |
| --- | ---: | ---: | ---: |
| `63202025` | `0` | `0` | `0` |
| `63202031` | `0` | `0` | `0` |

Operational reading: the problem is not action legality, forensic lineage, or
decision-trace structure for these seeds. The issue is strategy sample quality:
their mulligan history makes the resulting replay unsuitable as
high-confidence deck-quality or WR evidence.

## Decision Trace Evidence

The flagged decision in both seeds is `decision-000005`.

Seed `63202025`:

- Player: `Kraum, Ludevic's Opus #83 (real)`
- `chosen_option.action=keep`
- `forced_keep=true`
- `mulligan_count=3`
- `score=-7.0`
- `risk_flags=["mana_screw","forced_keep_after_mulligan_cap"]`
- `lands=1`
- `cards_in_hand=5`
- Strategy finding:
  `Mulligan cap forced a risky keep: mana_screw, negative_keep_score, too_few_lands.`

Seed `63202031`:

- Player: `Kraum, Ludevic's Opus #83 (real)`
- `chosen_option.action=keep`
- `forced_keep=true`
- `mulligan_count=3`
- `score=-3.0`
- `risk_flags=["no_early_game_plan","reactive_only_opener","forced_keep_after_mulligan_cap"]`
- `lands=3`
- `cards_in_hand=5`
- Strategy finding:
  `Mulligan cap forced a risky keep: negative_keep_score, no_early_game_plan.`

## Gate Matrix Freshness

`docs/hermes-analysis/BATTLE_REPLAY_GATE_MATRIX.md` still documents the correct
contract:

- low-confidence strategy findings remain visible;
- forced mulligan-cap keeps get `high_confidence_learning_weight=0.0`;
- `strategy_audit.status` can pass when only low-confidence findings remain;
- `strategy_review_required_findings` identifies findings that keep the
  strategy gate in review.

However, its "Current Gate Reading" section is stale for current latest:

- It points to run `20260619_184721`.
- It reports `13` high-confidence and `3` low-confidence seeds.
- Current latest is run `20260619_203855`, with `14` high-confidence and `2`
  low-confidence seeds.

This is already covered by the documentation freshness class in `BV-058`.

## Finding Update

No new open BV is required for learning confidence itself. The current latest
still enforces the intended distinction:

1. The aggregate run can be `trusted_for_strategy_learning`.
2. Low-confidence seeds remain visible.
3. Low-confidence seeds have `high_confidence_learning_eligible=false` and
   `high_confidence_learning_weight=0.0`.
4. Downstream high-confidence WR/deck-quality claims must use
   `strategy_high_confidence_learning_seeds`, not every completed seed.

This pass updates:

- `BV-058`: gate-matrix current-reading snapshot is stale.
- The strategy-learning confidence register section: latest is now `14/2`, not
  `13/3`.

## Suggested Adjustment

- Keep `BATTLE_REPLAY_GATE_MATRIX.md` as a contract doc, but avoid embedding a
  fixed "Current Gate Reading" unless it is generated from latest.
- If a fixed snapshot remains, update it whenever latest changes or label it as
  historical.
- Add a current-latest reference to the register whenever citing strategy WR,
  baseline, or learning handoff.

## Validation Commands Run

- Parsed current latest `summary.json`.
- Parsed current `research_review.json` and `research_review.md`.
- Parsed `strategy_audit.json` and `strategy_audit.md` for seeds `63202025`
  and `63202031`.
- Parsed `replay.decision_trace.jsonl` for the flagged mulligan decisions.
- Parsed `action_critic.json`, `forensic_audit.json`, and
  `replay_decision_audit.json` for both low-confidence seeds.
- Inspected `BATTLE_REPLAY_GATE_MATRIX.md`.
- Compared against prior
  `battle_strategy_learning_confidence_scope_audit_20260619_191643.md`.
- `python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_decision_strategy_auditor.py` - PASS.
- `python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_decision_research_review.py` - PASS.
