# Battle Flow Inventory Audit - 2026-06-19T15:43Z

## Scope

Read-only inventory of the current ManaLoom battle validation flow. No
PostgreSQL changes, no swaps, no code changes, and no commit.

## Sources Checked

- `docs/hermes-analysis/BATTLE_SYSTEM_LOGIC.md`
- `docs/hermes-analysis/BATTLE_AUDIT_COVERAGE_STATUS_2026-06-16.md`
- `docs/hermes-analysis/BATTLE_MULTI_RULE_RUNTIME_READINESS_2026-06-17.md`
- `docs/hermes-analysis/BATTLE_GENERATOR_IMPLEMENTATION_SLICE_SPEC_2026-06-17.md`
- `docs/hermes-analysis/BATTLE_GENERATOR_LOREHOLD_TASK_MATRIX_2026-06-17.md`
- `docs/hermes-analysis/LOREHOLD_MIRACLE_TOPDECK_READINESS_AUDIT_2026-06-17.md`
- `docs/hermes-analysis/LOREHOLD_BATTLE_MODEL_COVERAGE_MATRIX_2026-06-16.md`
- `docs/hermes-analysis/LOREHOLD_DECK6_STRATEGY_COHERENCE_AUDIT_2026-06-19.md`
- `docs/hermes-analysis/manaloom-knowledge/scripts/battle_analyst_v9.py`
- `docs/hermes-analysis/manaloom-knowledge/scripts/battle_replay_v10_3.py`
- `docs/hermes-analysis/manaloom-knowledge/scripts/battle_action_critic.py`
- `docs/hermes-analysis/manaloom-knowledge/scripts/battle_decision_strategy_auditor.py`
- `docs/hermes-analysis/manaloom-knowledge/scripts/battle_effect_coverage_audit.py`
- `docs/hermes-analysis/manaloom-knowledge/scripts/battle_forensic_audit.py`
- `docs/hermes-analysis/manaloom-knowledge/scripts/replay_decision_auditor.py`
- `/Users/desenvolvimentomobile/.manaloom-agents/bin/manaloom-battle-strategy-audit.sh`
- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/latest/summary.json`

## Current Automated Flow

Latest run:

- run dir:
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260619_153803`
- timestamp UTC: `2026-06-19T15:38:03Z`
- seed: `63201430`
- action findings: `0`
- action verdict counts: `{"ok": 478}`
- strategy findings: `2`
- strategy severity counts: `{"medium": 2}`
- strategy code counts: `{"forced_keep_after_bad_mulligan": 2}`
- strategy blockers: `[]`
- coverage unknowns: `33`
- heuristic effects: `120`
- trigger not explicit: `147`
- cast permission not explicit: `89`
- land utility ability not modeled: `48`
- runtime-safe rule names: `1702`
- review-only rule names: `1457`

The automation now runs:

- `battle_replay_v10_3.py`
- `battle_action_critic.py`
- `battle_decision_strategy_auditor.py`
- `battle_decision_research_review.py`
- `battle_effect_coverage_audit.py`
- focused unit tests for action critic, strategy auditor, research review,
  effect coverage, replay renderer, runtime-safe registry, and the main battle
  analyst suite.

The automation still does not run:

- `battle_forensic_audit.py`
- `replay_decision_auditor.py`

## Additional Gates Run For This Audit

Artifact:

- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-validation-register/20260619_latest_seed63201430_forensic_124320/`

Replay decision audit over latest seed:

- status: `turn_by_turn_clean`
- structured events: `1251`
- decision traces: `185`
- turn findings: `0`
- decision findings: `0`
- critical/high/medium/low: `0/0/0/0`

Forensic audit over latest seed:

- status: `ready_for_review`
- findings total: `0`
- critical/high/medium/low: `0/0/0/0`
- card events: `75`
- unique cards seen: `51`
- rule logical key present/missing: `74/1`
- card id present/missing: `12/63`
- semantic hash present/missing: `12/63`
- sources: `curated=74`, `type_line_creature=1`
- statuses: `verified=69`, `active=5`, `fact=1`

Interpretation: the latest automated seed is clean in the extra forensic and
decision gates, but its semantic lineage is still sparse because most card
events lack `card_id` and `semantic_hash`.

## Implementation Map

- `battle_analyst_v9.py`: active simulation engine, decision trace emitter,
  cost payment, priority, miracle/topdeck, landfall, utility lands, combat,
  replacement effects, casting, card-specific behaviors, and learned-opponent
  loading.
- `battle_replay_v10_3.py`: human replay renderer for structured events.
- `battle_action_critic.py`: action-level critic for replay events; now catches
  counter spells without stack target, but still accepts trigger events with
  placeholder evidence.
- `battle_decision_strategy_auditor.py`: strategy critic for decisions and
  risky resource use; now catches forced keeps after mana-screw mulligan cap.
- `battle_effect_coverage_audit.py`: corpus-level card/effect coverage audit
  across Lorehold plus twelve opponent decks; now separates runtime-safe rules
  from review-only rules.
- `battle_rule_registry.py`: SQLite battle rule registry and runtime-safe
  filtering.
- `battle_forensic_audit.py`: rule provenance and effect support gate; not part
  of the hourly automation summary.
- `replay_decision_auditor.py`: turn and decision-trace invariant gate; not
  part of the hourly automation summary.

## Current Contradictions And Risks

1. The latest automation summary now includes coverage fields. Older register
   language saying the summary has no coverage is historically true for earlier
   runs but stale for the current script. The remaining automation gap is now
   forensic plus replay-decision aggregation.
2. `LOREHOLD_BATTLE_MODEL_COVERAGE_MATRIX_2026-06-16.md` classifies `Pyroblast`
   as `hard_modelled` and `low` risk, but seed `786135854` still has action
   critic `high` for `Pyroblast` resolving as `counter` without stack target.
3. `LOREHOLD_MIRACLE_TOPDECK_READINESS_AUDIT_2026-06-17.md` says the base
   Lorehold miracle path is resolved, but the current manual rerun shows a
   miracle/topdeck counter path that is not safe.
4. `battle_action_critic.py` flags counter target gaps, but it does not yet
   flag `trigger_put_on_stack` events that lack source/stack evidence. The
   latest seed has an action entry for `trigger_put_on_stack` with evidence
   `-` and verdict `ok`.
5. The latest forensic gate is clean, but lineage is incomplete: `63/75` card
   events are missing `card_id` and `semantic_hash`.
6. The current coverage gate still reports `unknown_effect=33`,
   `trigger_not_explicit=147`, `cast_permission_not_explicit=89`,
   `land_utility_ability_not_modeled=48`, and `review_only_rule=34`. This is
   not compatible with a claim that all action templates are created.

## Register Updates Needed

- Update `BV-012`: coverage is now in the latest `summary.json`; remaining gap
  is forensic and replay-decision summary/alert integration.
- Update `BV-010`: latest strategy audit catches both bad forced keeps on seed
  `63201430`; closure still requires deciding whether `needs_review` is an
  acceptable final status for the automation.
- Add a finding for stale Lorehold coverage docs around `Pyroblast` and
  miracle/topdeck.
- Add a finding for trigger events accepted by the action critic without
  source/stack evidence.
- Add a finding for sparse card-event provenance in otherwise clean forensic
  runs.
