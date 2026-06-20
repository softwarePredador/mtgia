# Battle Decision Trace Taxonomy Audit - 2026-06-19T16:27Z

## Scope

Artifact-only validation slice for `decision_trace` taxonomy and auditor
ownership. This audit does not change PostgreSQL, swaps, product code, or
automation code.

Inputs:

- Latest summary:
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/latest/summary.json`
- Latest run:
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260619_161528`
- Latest decision trace:
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260619_161528/seed_786135854/replay.decision_trace.jsonl`
- Generated taxonomy artifact:
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-validation-register/20260619_decision_trace_taxonomy_1627/decision_trace_taxonomy.json`
- Re-run auditor artifacts:
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-validation-register/20260619_decision_trace_taxonomy_1627/strategy_audit.json`
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-validation-register/20260619_decision_trace_taxonomy_1627/replay_decision_audit.json`
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-validation-register/20260619_decision_trace_taxonomy_1627/research_review.json`

## Current Latest Snapshot

Latest `summary.json` at `2026-06-19T16:15:28Z`:

- `events`: `1073`
- `decisions`: `152`
- `action_findings`: `0`
- `strategy_findings`: `0`
- `decision_audit_turn_findings`: `0`
- `decision_audit_decision_findings`: `0`
- `forensic_rule_findings`: `0`
- `forensic_turn_findings`: `0`
- `decision_audit_status_scope`: `turn_and_decision_trace_invariants`
- `decision_audit_human_replay_complete`:
  `not_evaluated_by_replay_decision_auditor`
- `decision_audit_rules_interaction_trusted`:
  `not_evaluated_by_replay_decision_auditor`

Auditors re-run in this slice:

- `battle_decision_strategy_auditor.py` - `0` findings,
  `verdict=usable_for_strategy_learning`.
- `replay_decision_auditor.py --require-decision-trace` - `0` turn findings,
  `0` decision findings, `status=turn_invariants_clean`.
- `battle_decision_research_review.py` - `10` research categories
  `coherent_in_sample`.

Tests run in this slice:

- `python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_decision_strategy_auditor.py` - PASS.
- `python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_decision_research_review.py` - PASS.
- `python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_replay_decision_auditor_scope.py` - PASS.
- `python3 docs/hermes-analysis/manaloom-knowledge/scripts/battle_decision_trace_tests.py` - PASS.

## Engine Decision Surface

Static extraction from `battle_analyst_v9.py`:

- `emit_decision_trace(...)` call sites: `34`
- static decision types emitted by the engine: `15`

Decision types emitted statically:

- `activated_sacrifice_damage`
- `attack_trigger_artifact_tutor`
- `board_wipe`
- `cast_spell`
- `combat_attack`
- `lorehold_upkeep_rummage`
- `mulligan_decision`
- `pass_no_action`
- `response`
- `saga_chapter_resolution`
- `tutor`
- `utility_artifact_activation`
- `utility_land_activation`
- `wheel`
- `worldfire_reset`

Latest seed exercised `10/15` static types:

| Decision type | Latest count |
| --- | ---: |
| `pass_no_action` | 69 |
| `cast_spell` | 35 |
| `combat_attack` | 24 |
| `mulligan_decision` | 8 |
| `utility_artifact_activation` | 8 |
| `lorehold_upkeep_rummage` | 4 |
| `saga_chapter_resolution` | 1 |
| `response` | 1 |
| `tutor` | 1 |
| `wheel` | 1 |

Static engine types not observed in latest:

- `activated_sacrifice_damage`
- `attack_trigger_artifact_tutor`
- `board_wipe`
- `utility_land_activation`
- `worldfire_reset`

## Auditor Ownership

`replay_decision_auditor.py` provides generic invariant coverage for all
decision types:

- required base fields;
- non-empty `available_options`;
- chosen option present in options;
- non-empty `score_components`;
- rule source/status;
- comparative fields for multi-option decisions.

`battle_decision_strategy_auditor.py` has specialized branches for `7` decision
types:

- `board_wipe`
- `cast_spell`
- `mulligan_decision`
- `pass_no_action`
- `tutor`
- `wheel`
- `worldfire_reset`

`battle_decision_research_review.py` has research categories for `8` decision
types:

- `board_wipe`
- `cast_spell`
- `combat_attack`
- `mulligan_decision`
- `pass_no_action`
- `response`
- `tutor`
- `wheel`

## Contract Gaps

The latest trace has complete generic fields, so the existing auditors return
clean results. The gap is type-specific ownership: some decision types are
emitted and even observed, but only receive generic invariant checks.

Observed in latest with no specialized strategy branch and no research category:

| Decision type | Latest count | Score component keys observed |
| --- | ---: | --- |
| `utility_artifact_activation` | 8 | `activation_cost_generic`, `cards_exchanged`, `hand_to_top`, `miracle_cost`, `peek_top_count`, `top_after`, `top_before` |
| `lorehold_upkeep_rummage` | 4 | `discard_destination`, `drawn_card`, `miracle_cost` |
| `saga_chapter_resolution` | 1 | `candidate_count`, `chapter`, `selected_reason` |

Emitted by the engine with no specialized strategy branch and no research
category, but not observed in latest:

- `activated_sacrifice_damage`
- `attack_trigger_artifact_tutor`
- `utility_land_activation`

Decision types with partial ownership:

- `combat_attack`: research category exists, but strategy auditor only checks
  generic strategy fields; it has no dedicated `combat_attack` branch.
- `response`: research category exists, but strategy auditor only checks generic
  strategy fields; it has no dedicated `response` branch.
- `worldfire_reset`: strategy branch exists, but no research category currently
  maps to it.

## Operational Reading

The current latest run is clean for turn invariants, generic decision trace
shape, and the strategy rules that exist today. It does not prove that every
decision type has a complete type-specific contract.

The biggest practical risk is reading `strategy_findings=0` or
`decision_audit_decision_findings=0` as proof that every decision kind is
strategically trusted. For `utility_artifact_activation`,
`lorehold_upkeep_rummage`, and `saga_chapter_resolution`, the latest trace was
observed and clean only under generic checks.

## Required Follow-Up

- Create or generate `BATTLE_DECISION_TRACE_TAXONOMY.md` with one row per
  decision type:
  required fields, score component keys, latest count, strategy auditor owner,
  research category, replay auditor scope, fixture/test, and current status.
- Add summary/report counters:
  `decision_trace_kinds_total`, `decision_trace_kinds_observed`,
  `decision_trace_kinds_without_specific_contract`, and
  `decision_trace_observed_without_specific_contract`.
- Add specialized contracts or explicit waivers for:
  `utility_artifact_activation`, `lorehold_upkeep_rummage`,
  `saga_chapter_resolution`, `activated_sacrifice_damage`,
  `attack_trigger_artifact_tutor`, and `utility_land_activation`.
- Consider dedicated strategy-auditor branches for `combat_attack` and
  `response`, because both are research-covered but currently only generic in
  `battle_decision_strategy_auditor.py`.

